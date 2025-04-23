import re
import os
import json
from datetime import datetime
from collections import defaultdict
import logging

# Setup basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Keywords indicating a main countable unit
DIVISION_KEYWORDS = ["פרק", "דף", "סימן", "רמז", "מזמור", "הלכה", "שער", "מאמר", "פסקה", "אות"]
# Heading levels to check for potential PART divisions
POTENTIAL_PART_LEVELS = [1, 2]
# Heading level to check for potential SUB-PART divisions
POTENTIAL_SUBPART_LEVEL = 3
# Heading levels typically used for countable divisions
DIVISION_HEADING_LEVELS = [2, 3, 4]
# Minimum occurrences for a pattern to be considered dominant division
MIN_OCCURRENCES = 3

# --- Gematria Conversion Function (Unchanged) ---
def hebrew_numeral_to_int(hebrew_num):
    # ... (same as previous version) ...
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
    # ... (same as previous version) ...
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

    # --- Pass 1: Identify dominant division pattern ---
    # ... (logic remains the same) ...
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
    frequent_division_patterns = { pat: count for pat, count in potential_division_patterns.items() if count >= MIN_OCCURRENCES }
    if not frequent_division_patterns:
        logging.warning(f"'{book_name}': No frequent division pattern found.")
        return book_name, {}
    min_div_level = min(level for level, keyword in frequent_division_patterns.keys())
    dominant_division_candidates = { pat: count for pat, count in frequent_division_patterns.items() if pat[0] == min_div_level }
    dominant_div_pattern = max(dominant_division_candidates.keys(), key=lambda pat: dominant_division_candidates[pat])
    dominant_div_level, dominant_div_keyword = dominant_div_pattern
    logging.info(f"'{book_name}': Dominant division: H{dominant_div_level} '{dominant_div_keyword}'")

    # --- Pass 2: Scan line-by-line, tracking hierarchy ---
    # Structure: {part_name: {subpart_name: {details}}}
    # ... (logic remains the same - populates hierarchy_data) ...
    hierarchy_data = defaultdict(lambda: defaultdict(lambda: {"count": 0, "last_identifier": None}))
    current_part_name = "_default_part_"
    current_subpart_name = "_default_subpart_"
    found_explicit_part = False
    found_explicit_subpart_in_current_part = False # Track subparts per part
    unnamed_part_counter = 1
    unnamed_subpart_counter = 1

    part_levels_str = "".join(map(str, POTENTIAL_PART_LEVELS))
    any_potential_part_heading_str = rf'<h([{part_levels_str}])(?: [^>]*)?>\s*(.*?)\s*</h\1>'
    any_potential_part_heading_regex = re.compile(any_potential_part_heading_str, re.IGNORECASE)
    h3_subpart_str = rf'<h{POTENTIAL_SUBPART_LEVEL}(?: [^>]*)?>\s*(.*?)\s*</h{POTENTIAL_SUBPART_LEVEL}>'
    h3_subpart_regex = re.compile(h3_subpart_str, re.IGNORECASE)
    specific_div_pattern_str = rf'<h{dominant_div_level}(?: [^>]*)?>\s*?(?:כותרת\s+)?{re.escape(dominant_div_keyword)}\s+(.*?)\s*</h{dominant_div_level}>'
    specific_div_regex = re.compile(specific_div_pattern_str, re.IGNORECASE)

    for line_num, line in enumerate(lines):
        line_content = line.strip()
        processed_level = 0
        part_match = any_potential_part_heading_regex.search(line_content)
        if part_match:
            part_level_matched = int(part_match.group(1))
            if part_level_matched != dominant_div_level:
                processed_level = part_level_matched
                found_explicit_part = True
                part_name_raw = part_match.group(2).strip()
                part_name_clean = re.sub(r'<.*?>', '', part_name_raw).strip()
                if part_name_clean: current_part_name = part_name_clean
                else: current_part_name = f"חלק לא מוגדר {unnamed_part_counter}"; unnamed_part_counter += 1
                logging.debug(f"'{book_name}': Part Divider (H{part_level_matched}): '{current_part_name}' @ L{line_num+1}")
                current_subpart_name = "_default_subpart_"
                found_explicit_subpart_in_current_part = False # Reset for new part
                unnamed_subpart_counter = 1 # Reset for new part
                if current_part_name not in hierarchy_data: hierarchy_data[current_part_name]

        if dominant_div_level == 4 and processed_level == 0:
            subpart_match = h3_subpart_regex.search(line_content)
            if subpart_match:
                if POTENTIAL_SUBPART_LEVEL != dominant_div_level:
                    processed_level = POTENTIAL_SUBPART_LEVEL
                    found_explicit_subpart_in_current_part = True # Mark subparts found in this part
                    subpart_name_raw = subpart_match.group(1).strip()
                    subpart_name_clean = re.sub(r'<.*?>', '', subpart_name_raw).strip()
                    if subpart_name_clean: current_subpart_name = subpart_name_clean
                    else: current_subpart_name = f"תת-חלק לא מוגדר {unnamed_subpart_counter}"; unnamed_subpart_counter += 1
                    logging.debug(f"'{book_name}': Sub-Part Divider (H3): '{current_subpart_name}' in Part '{current_part_name}' @ L{line_num+1}")
                    if current_subpart_name not in hierarchy_data[current_part_name]: hierarchy_data[current_part_name][current_subpart_name]

        if processed_level == 0:
            division_match = specific_div_regex.search(line_content)
            if division_match:
                identifier_raw = division_match.group(1).strip()
                identifier_clean = re.sub(r'<.*?>', '', identifier_raw).strip()
                target_subpart_key = current_subpart_name if dominant_div_level == 4 else "_level3_default_"
                division_data = hierarchy_data[current_part_name].setdefault(target_subpart_key, {"count": 0, "last_identifier": None})
                division_data["count"] += 1
                division_data["last_identifier"] = identifier_clean


    # --- Final Assembly & Simplification (Revised Logic) ---
    final_result_assembly = {} # Build the potentially nested structure here first

    for part_name, subparts in hierarchy_data.items():
        # Collect valid subparts for this part
        valid_subparts_for_this_part = {}
        default_subpart_key = "_level3_default_" if dominant_div_level != 4 else "_default_subpart_"

        # Determine the label for the default subpart if it exists and has data
        default_subpart_label = None
        if default_subpart_key in subparts and subparts[default_subpart_key]["count"] > 0:
            # Decide label based on context
            if part_name == "_default_part_" and not found_explicit_part:
                 default_subpart_label = book_name # No parts found at all
            elif dominant_div_level != 4: # Dominant is H2/H3, subpart level is just a placeholder
                 default_subpart_label = part_name if part_name != "_default_part_" else f"{book_name} (ראשי)"
            else: # Dominant is H4, default subpart is content before first H3
                 default_subpart_label = f"{part_name} (מבוא/הקדמה?)" if found_explicit_subpart_in_current_part else part_name # If only default, use part name
            valid_subparts_for_this_part[default_subpart_label] = subparts[default_subpart_key]


        # Collect named/unnamed subparts (only relevant if dominant is H4)
        if dominant_div_level == 4:
            for subpart_name, subpart_data in subparts.items():
                if subpart_name == default_subpart_key: continue
                if subpart_data["count"] > 0:
                    valid_subparts_for_this_part[subpart_name] = subpart_data
                else:
                     logging.warning(f"'{book_name}': Sub-Part '{subpart_name}' in Part '{part_name}' identified but contained no divisions.")

        # Now decide how to structure this part based on the number of valid subparts
        num_valid_subparts = len(valid_subparts_for_this_part)
        part_label = part_name if part_name != "_default_part_" else book_name # Use book name if it's the only part

        if num_valid_subparts == 1:
            # Simplify: Part -> Details (take details from the single valid subpart)
            single_subpart_details = list(valid_subparts_for_this_part.values())[0]
            final_result_assembly[part_label] = {
                "division_type": dominant_div_keyword,
                "count": single_subpart_details["count"],
                "heading_level": f"h{dominant_div_level}",
                "last_identifier_found": single_subpart_details["last_identifier"]
            }
            logging.debug(f"'{book_name}': Simplified Part '{part_label}' (only 1 sub-part found).")
        elif num_valid_subparts > 1:
            # Keep subpart structure: Part -> SubPart -> Details
            part_data_nested = {}
            for subpart_label, subpart_details in valid_subparts_for_this_part.items():
                 part_data_nested[subpart_label] = {
                    "division_type": dominant_div_keyword,
                    "count": subpart_details["count"],
                    "heading_level": f"h{dominant_div_level}",
                    "last_identifier_found": subpart_details["last_identifier"]
                }
            final_result_assembly[part_label] = part_data_nested
            logging.debug(f"'{book_name}': Kept Sub-Part structure for Part '{part_label}' ({num_valid_subparts} sub-parts found).")
        # If num_valid_subparts == 0, do nothing (part is empty)


    # --- Apply Final Overall Simplification ---
    final_output_structure = {}
    if len(final_result_assembly) == 1:
        # If only one top-level key exists after processing all parts, flatten completely
        single_toplevel_key = list(final_result_assembly.keys())[0]
        # The value associated with this key IS the final data for the book
        final_output_structure = final_result_assembly[single_toplevel_key]
        logging.info(f"'{book_name}': Simplified structure: Only one effective top-level part found ('{single_toplevel_key}'). Final structure is flat.")
    elif not final_result_assembly:
        logging.warning(f"'{book_name}': No countable divisions found in any structure.")
        final_output_structure = {}
    else:
        # Multiple top-level parts exist, keep the structure as assembled
        final_output_structure = final_result_assembly
        logging.info(f"'{book_name}': Multiple effective top-level parts found ({len(final_result_assembly)}). Keeping hierarchical structure.")

    return book_name, final_output_structure


# --- Main Execution (Gematria check needs slight adjustment) ---
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

                            # --- Gematria Check (Revised Logic for Final Structure) ---
                            def perform_gematria_check(data_node, context_name):
                                # ... (Gematria check function remains the same internal logic) ...
                                if not isinstance(data_node, dict) or "count" not in data_node:
                                    logging.error(f"Gematria Check Error: Invalid data node for context '{context_name}'")
                                    return
                                logging.info(f"  -> {context_name} | יחידות: {data_node.get('count', 'N/A')} מסוג '{data_node.get('division_type', 'N/A')}' ({data_node.get('heading_level', 'N/A')}) | מזהה אחרון: '{data_node.get('last_identifier_found', 'N/A')}'")
                                last_id = data_node.get('last_identifier_found')
                                count = data_node.get('count')
                                if last_id and count is not None:
                                    gematria_value = hebrew_numeral_to_int(last_id)
                                    if gematria_value > 0:
                                        if gematria_value == count:
                                            logging.info(f"     -> אימות גימטריה ('{context_name}'): תקין! ('{last_id}' = {gematria_value})")
                                            data_node["gematria_check"] = "Match"
                                        else:
                                            logging.warning(f"     -> אימות גימטריה ('{context_name}'): אי התאמה! ('{last_id}' = {gematria_value}, נספרו = {count})")
                                            data_node["gematria_check"] = f"Mismatch (ID:{gematria_value}, Count:{count})"
                                    else:
                                        logging.warning(f"     -> אימות גימטריה ('{context_name}'): המזהה האחרון ('{last_id}') אינו מספר גימטריה תקני.")
                                        data_node["gematria_check"] = "Non-numeric ID"
                                else:
                                    if count is not None and count > 0:
                                        logging.warning(f"     -> אימות גימטריה ('{context_name}'): לא נמצא מזהה אחרון (נספרו {count} יחידות).")
                                        data_node["gematria_check"] = "Last ID Missing"
                                    else:
                                         data_node["gematria_check"] = "N/A (No Count/ID)"

                            # Apply check based on the final structure of structured_data
                            if "division_type" in structured_data: # Case 1: Fully flattened (Book -> Details)
                                perform_gematria_check(structured_data, book_name)
                            elif isinstance(structured_data, dict): # Case 2 or 3: Nested (Book -> Part/SubPart -> ...)
                                for level1_key, level1_value in structured_data.items():
                                    if isinstance(level1_value, dict) and "division_type" in level1_value: # Case 2 Simplified (Book -> SubPart -> Details)
                                        perform_gematria_check(level1_value, f"{book_name} / {level1_key}")
                                    elif isinstance(level1_value, dict): # Case 3 (Book -> Part -> SubPart -> Details)
                                        for level2_key, level2_value in level1_value.items():
                                             if isinstance(level2_value, dict) and "division_type" in level2_value:
                                                  perform_gematria_check(level2_value, f"{book_name} / {level1_key} / {level2_key}")

                        else:
                             logging.warning(f"  -> ספר: '{book_name}', לא נמצאו נתוני חלוקה מובנים לאחר ניתוח היררכי.")

                    except Exception as e:
                        logging.error(f"  -> !! שגיאה חריגה בעת עיבוד הקובץ '{filename}': {e}", exc_info=True)

        # Prepare the final JSON structure
        final_output_json = {
            "collection_name": input_folder_name if input_folder_name else "ספרים סרוקים",
            "processed_folder": input_dir,
            "books_data": overall_results,
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