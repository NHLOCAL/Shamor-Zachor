import re
import os
import json
from datetime import datetime
from collections import defaultdict
import logging

# ... (שאר הקוד: imports, constants, gematria, extract_book_name נשארים זהים) ...
# Setup basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Keywords indicating a main countable unit
DIVISION_KEYWORDS = [
    "פרק", "דף", "סימן", "רמז", "מזמור",
    "הלכה", "שער", "מאמר", "פסקה", "אות"
]

# Heading levels to check for potential PART divisions
POTENTIAL_PART_LEVELS = [1, 2]

# Heading levels typically used for countable divisions
DIVISION_HEADING_LEVELS = [2, 3, 4]

# Minimum occurrences for a pattern to be considered dominant division
MIN_OCCURRENCES = 3

# --- Gematria Conversion Function (Unchanged) ---
def hebrew_numeral_to_int(hebrew_num):
    if not isinstance(hebrew_num, str) or not hebrew_num: return 0
    hebrew_num = hebrew_num.replace("'", "").replace('"', '').strip()
    hebrew_num = hebrew_num.replace("תר", "ת"+"ר")
    gematria_map = {'א': 1, 'ב': 2, 'ג': 3, 'ד': 4, 'ה': 5, 'ו': 6, 'ז': 7, 'ח': 8, 'ט': 9, 'י': 10, 'כ': 20, 'ל': 30, 'מ': 40, 'נ': 50, 'ס': 60, 'ע': 70, 'פ': 80, 'צ': 90, 'ק': 100, 'ר': 200, 'ש': 300, 'ת': 400}
    value, base = 0, hebrew_num
    if hebrew_num.endswith('טז'): base, value = hebrew_num[:-2], 16
    elif hebrew_num.endswith('טו'): base, value = hebrew_num[:-2], 15
    try:
        current_val = 0
        for char in base:
            digit_val = gematria_map.get(char)
            if digit_val is None:
                if any(word in hebrew_num for word in ["הקדמה", "פתיחה", "מבוא", "סוף"]): return 0
                logging.debug(f"Gematria: Invalid char '{char}' in '{hebrew_num}'. Non-numeric.")
                return 0
            current_val += digit_val
        total_value = current_val + value
        if len(base) > 3 and total_value < 10 and value == 0:
             logging.debug(f"Gematria: Input '{hebrew_num}' heuristic suggests not numeral. Non-numeric.")
             return 0
        return total_value if total_value > 0 else 0
    except Exception as e:
        logging.error(f"Gematria conversion error for '{hebrew_num}': {e}")
        return 0

# --- Function to Extract Book Name (Unchanged) ---
def extract_book_name(lines):
    h1_pattern = re.compile(r'^<h1>(.*?)</h1>$', re.IGNORECASE)
    for line in lines[:20]:
        match = h1_pattern.match(line.strip())
        if match:
            name = match.group(1).strip()
            name = re.sub(r'<.*?>', '', name).strip()
            if name: return name
    return None


# --- Combined Analysis Function ---
def analyze_hierarchical_structure(filepath, division_keywords):
    lines = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        logging.error(f"File not found: {filepath}")
        return os.path.splitext(os.path.basename(filepath))[0], {}
    except Exception as e:
        logging.error(f"Error reading file {filepath}: {e}")
        return os.path.splitext(os.path.basename(filepath))[0], {}

    book_name_from_h1 = extract_book_name(lines)
    book_name = book_name_from_h1 if book_name_from_h1 else os.path.splitext(os.path.basename(filepath))[0]

    # --- Pass 1: Identify the *overall* dominant division pattern ---
    potential_division_patterns = defaultdict(int)
    div_levels_str = "".join(map(str, DIVISION_HEADING_LEVELS))
    div_keywords_pattern = "|".join(re.escape(k) for k in division_keywords)
    overall_div_pattern_str = rf'<h([{div_levels_str}])(?: [^>]*)?>\s*?(?:כותרת\s+)?(?:({div_keywords_pattern})\s+(.*?))?\s*</h\1>'
    overall_div_regex = re.compile(overall_div_pattern_str, re.IGNORECASE)

    for line in lines:
        match = overall_div_regex.search(line.strip())
        if match:
            level = int(match.group(1))
            keyword = match.group(2)
            if keyword: potential_division_patterns[(level, keyword)] += 1

    frequent_division_patterns = {
        pat: count for pat, count in potential_division_patterns.items()
        if count >= MIN_OCCURRENCES
    }
    if not frequent_division_patterns:
        logging.warning(f"'{book_name}': No frequent division pattern found. Cannot proceed.")
        return book_name, {}

    min_div_level = min(level for level, keyword in frequent_division_patterns.keys())
    dominant_division_candidates = {
        pat: count for pat, count in frequent_division_patterns.items()
        if pat[0] == min_div_level
    }
    dominant_div_pattern = max(dominant_division_candidates.keys(), key=lambda pat: dominant_division_candidates[pat])
    dominant_div_level, dominant_div_keyword = dominant_div_pattern
    logging.info(f"'{book_name}': Dominant division: H{dominant_div_level} '{dominant_div_keyword}'")

    # --- Pass 2: Scan line-by-line, tracking parts and counting divisions ---
    parts_data = defaultdict(lambda: {"count": 0, "last_identifier": None})
    current_part_name = "_default_part_"
    found_explicit_part = False
    unnamed_part_counter = 1

    part_levels_str = "".join(map(str, POTENTIAL_PART_LEVELS))
    any_potential_part_heading_str = rf'<h([{part_levels_str}])(?: [^>]*)?>\s*(.*?)\s*</h\1>'
    any_potential_part_heading_regex = re.compile(any_potential_part_heading_str, re.IGNORECASE)

    specific_div_pattern_str = rf'<h{dominant_div_level}(?: [^>]*)?>\s*?(?:כותרת\s+)?{re.escape(dominant_div_keyword)}\s+(.*?)\s*</h{dominant_div_level}>'
    specific_div_regex = re.compile(specific_div_pattern_str, re.IGNORECASE)

    for line_num, line in enumerate(lines):
        line_content = line.strip()
        is_part_heading = False

        part_match = any_potential_part_heading_regex.search(line_content)
        if part_match:
            part_level_matched = int(part_match.group(1))
            part_name_raw = part_match.group(2).strip()
            part_name_clean = re.sub(r'<.*?>', '', part_name_raw).strip()

            if part_level_matched != dominant_div_level:
                is_part_heading = True
                found_explicit_part = True
                if part_name_clean:
                    current_part_name = part_name_clean
                    logging.debug(f"'{book_name}': Identified Named Part Divider (H{part_level_matched}): '{current_part_name}' at line {line_num+1}")
                else:
                    current_part_name = f"חלק לא מוגדר {unnamed_part_counter}"
                    unnamed_part_counter += 1
                    logging.debug(f"'{book_name}': Identified Unnamed Part Divider (H{part_level_matched}) -> '{current_part_name}' at line {line_num+1}")
                if current_part_name not in parts_data:
                    parts_data[current_part_name]

        if not is_part_heading:
            division_match = specific_div_regex.search(line_content)
            if division_match:
                identifier_raw = division_match.group(1).strip()
                identifier_clean = re.sub(r'<.*?>', '', identifier_raw).strip()
                if current_part_name not in parts_data:
                     parts_data[current_part_name]
                current_part_data = parts_data[current_part_name]
                current_part_data["count"] += 1
                current_part_data["last_identifier"] = identifier_clean

    # --- Final Assembly ---
    # Build the preliminary result with potential parts
    preliminary_result = {}
    if "_default_part_" in parts_data and parts_data["_default_part_"]["count"] > 0:
         # Use a simpler label for the default part now
         default_part_label = f"{book_name} (ראשי)" if found_explicit_part else book_name
         preliminary_result[default_part_label] = {
                "division_type": dominant_div_keyword,
                "count": parts_data["_default_part_"]["count"],
                "heading_level": f"h{dominant_div_level}",
                "last_identifier_found": parts_data["_default_part_"]["last_identifier"]
            }

    for part_name, data in parts_data.items():
        if part_name == "_default_part_": continue
        if data["count"] > 0:
            preliminary_result[part_name] = {
                "division_type": dominant_div_keyword,
                "count": data["count"],
                "heading_level": f"h{dominant_div_level}",
                "last_identifier_found": data["last_identifier"]
            }
        else:
             logging.warning(f"'{book_name}': Part '{part_name}' identified but contained no countable '{dominant_div_keyword}' divisions.")

    # --- Simplification Check --- <<<< NEW LOGIC HERE
    if len(preliminary_result) == 1:
        # If there's only one logical part, structure the output directly under the book name
        single_part_data = list(preliminary_result.values())[0]
        final_result = single_part_data # Return the data directly, not nested
        logging.info(f"'{book_name}': Simplified structure as only one logical part was found.")
    elif not preliminary_result:
         logging.warning(f"'{book_name}': No countable divisions found in any identified part structure.")
         final_result = {} # Return empty dict for the book
    else:
        # If there are multiple parts, keep the nested structure
        final_result = preliminary_result
        logging.info(f"'{book_name}': Multiple parts found, maintaining hierarchical structure.")

    # Return the book name and the final structured data (either simplified or hierarchical)
    return book_name, final_result


# --- Main Execution (Unchanged) ---
if __name__ == "__main__":
    input_dir_raw = input("הכנס את נתיב תיקיית הקבצים המקוריים (ניתן להדביק עם גרשיים): ")
    input_dir = input_dir_raw.strip().strip('"').strip("'")

    if not os.path.isdir(input_dir):
        logging.error(f"שגיאה: תיקיית הקלט '{input_dir}' אינה קיימת.")
    else:
        overall_results = {}
        logging.info(f"מתחיל עיבוד קבצים מתוך: {input_dir}")

        script_dir = os.path.dirname(os.path.abspath(__file__))
        input_folder_name = os.path.basename(os.path.normpath(input_dir))
        safe_folder_name = re.sub(r'[\\/*?:"<>|]', '_', input_folder_name)
        output_json_filename = f"{safe_folder_name}_hierarchical_analysis.json"
        output_json_path = os.path.join(script_dir, output_json_filename)
        logging.info(f"קובץ הפלט יווצר ב: {output_json_path}")

        for filename in os.listdir(input_dir):
            if filename.lower().endswith(('.txt', '.html', '.htm')):
                filepath = os.path.join(input_dir, filename)
                if os.path.isfile(filepath) and filepath != output_json_path :
                    logging.info(f"--- מעבד קובץ: '{filename}' ---")
                    try:
                        book_name, structured_data = analyze_hierarchical_structure(filepath, DIVISION_KEYWORDS)

                        if structured_data:
                            overall_results[book_name] = structured_data

                            # Gematria Check - needs adjustment based on structure
                            # If the structure is flat (len==1 case), data is directly in structured_data
                            # If hierarchical, need to iterate through parts

                            # Check if it's the simplified (flat) structure
                            if "division_type" in structured_data:
                                # Simplified structure - perform check directly
                                logging.info(f"  -> ספר: '{book_name}' (חלק יחיד) | יחידות: {structured_data['count']} מסוג '{structured_data['division_type']}' ({structured_data['heading_level']}) | מזהה אחרון: '{structured_data['last_identifier_found']}'")
                                last_id = structured_data['last_identifier_found']
                                count_in_part = structured_data['count']
                                part_name_for_log = book_name # Use book name for log context
                                # Perform the actual gematria check (logic copied below)
                                if last_id:
                                    gematria_value = hebrew_numeral_to_int(last_id)
                                    if gematria_value > 0:
                                        if gematria_value == count_in_part:
                                            logging.info(f"     -> אימות גימטריה ('{part_name_for_log}'): תקין! ('{last_id}' = {gematria_value})")
                                            structured_data["gematria_check"] = "Match"
                                        else:
                                            logging.warning(f"     -> אימות גימטריה ('{part_name_for_log}'): אי התאמה! ('{last_id}' = {gematria_value}, נספרו = {count_in_part})")
                                            structured_data["gematria_check"] = f"Mismatch (ID:{gematria_value}, Count:{count_in_part})"
                                    else:
                                        logging.warning(f"     -> אימות גימטריה ('{part_name_for_log}'): המזהה האחרון ('{last_id}') אינו מספר גימטריה תקני.")
                                        structured_data["gematria_check"] = "Non-numeric ID"
                                else:
                                    logging.warning(f"     -> אימות גימטריה ('{part_name_for_log}'): לא נמצא מזהה אחרון.")
                                    structured_data["gematria_check"] = "Last ID Missing"

                            else: # Hierarchical structure
                                for part_name, part_data in structured_data.items():
                                    logging.info(f"  -> חלק: '{part_name}' | יחידות: {part_data['count']} מסוג '{part_data['division_type']}' ({part_data['heading_level']}) | מזהה אחרון: '{part_data['last_identifier_found']}'")
                                    last_id = part_data['last_identifier_found']
                                    count_in_part = part_data['count']
                                    # Perform the actual gematria check (logic copied below)
                                    if last_id:
                                        gematria_value = hebrew_numeral_to_int(last_id)
                                        if gematria_value > 0:
                                            if gematria_value == count_in_part:
                                                logging.info(f"     -> אימות גימטריה ('{part_name}'): תקין! ('{last_id}' = {gematria_value})")
                                                # Add check result to the specific part's data
                                                structured_data[part_name]["gematria_check"] = "Match"
                                            else:
                                                logging.warning(f"     -> אימות גימטריה ('{part_name}'): אי התאמה! ('{last_id}' = {gematria_value}, נספרו = {count_in_part})")
                                                structured_data[part_name]["gematria_check"] = f"Mismatch (ID:{gematria_value}, Count:{count_in_part})"
                                        else:
                                            logging.warning(f"     -> אימות גימטריה ('{part_name}'): המזהה האחרון ('{last_id}') אינו מספר גימטריה תקני.")
                                            structured_data[part_name]["gematria_check"] = "Non-numeric ID"
                                    else:
                                        logging.warning(f"     -> אימות גימטריה ('{part_name}'): לא נמצא מזהה אחרון.")
                                        structured_data[part_name]["gematria_check"] = "Last ID Missing"
                        else:
                             logging.warning(f"  -> ספר: '{book_name}', לא נמצאו נתוני חלוקה מובנים לאחר ניתוח היררכי.")

                    except Exception as e:
                        logging.error(f"  -> !! שגיאה חריגה בעת עיבוד הקובץ '{filename}': {e}", exc_info=True)

        # Prepare the final JSON structure
        final_output_json = {
            "collection_name": input_folder_name if input_folder_name else "ספרים סרוקים",
            "processed_folder": input_dir,
            "books_data": overall_results, # This now holds either flat or nested structures per book
            "last_updated": datetime.now().isoformat()
        }

        # Write the results
        try:
            with open(output_json_path, 'w', encoding='utf-8') as outfile:
                json.dump(final_output_json, outfile, ensure_ascii=False, indent=4)
            logging.info(f"--- העיבוד הסתיים בהצלחה. התוצאות נשמרו ב: {output_json_path} ---")
        except Exception as e:
            logging.error(f"שגיאה קריטית בכתיבת קובץ ה-JSON פלט '{output_json_path}': {e}", exc_info=True)

        print("\nהעיבוד הסתיים. בדוק את הודעות הלוג למעלה לקבלת פרטים נוספים.")