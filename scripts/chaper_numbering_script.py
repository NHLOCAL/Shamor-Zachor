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
# Heading levels to check for potential PART divisions (highest level)
POTENTIAL_PART_LEVELS = [1, 2]
# Heading level to check for potential SUB-PART divisions (only if main division is H4)
POTENTIAL_SUBPART_LEVEL = 3
# Heading levels typically used for countable divisions (lowest level)
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

    # --- Pass 1: Identify the *overall* dominant division pattern ---
    # ... (logic remains the same as before) ...
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
    hierarchy_data = defaultdict(lambda: defaultdict(lambda: {"count": 0, "last_identifier": None}))
    current_part_name = "_default_part_"
    current_subpart_name = "_default_subpart_" # Only relevant if dominant_div_level == 4
    found_explicit_part = False
    found_explicit_subpart = False # Tracks if H3 dividers were found when H4 is dominant
    unnamed_part_counter = 1
    unnamed_subpart_counter = 1

    # Regexes
    part_levels_str = "".join(map(str, POTENTIAL_PART_LEVELS))
    any_potential_part_heading_str = rf'<h([{part_levels_str}])(?: [^>]*)?>\s*(.*?)\s*</h\1>'
    any_potential_part_heading_regex = re.compile(any_potential_part_heading_str, re.IGNORECASE)

    # Regex for H3 sub-parts (only used if dominant is H4)
    h3_subpart_str = rf'<h{POTENTIAL_SUBPART_LEVEL}(?: [^>]*)?>\s*(.*?)\s*</h{POTENTIAL_SUBPART_LEVEL}>'
    h3_subpart_regex = re.compile(h3_subpart_str, re.IGNORECASE)

    # Regex for the specific dominant division type
    specific_div_pattern_str = rf'<h{dominant_div_level}(?: [^>]*)?>\s*?(?:כותרת\s+)?{re.escape(dominant_div_keyword)}\s+(.*?)\s*</h{dominant_div_level}>'
    specific_div_regex = re.compile(specific_div_pattern_str, re.IGNORECASE)

    # --- Line-by-Line Scan ---
    for line_num, line in enumerate(lines):
        line_content = line.strip()
        processed_level = 0 # Track which level was processed to avoid double processing

        # 1. Check for Part Divider (H1/H2)
        part_match = any_potential_part_heading_regex.search(line_content)
        if part_match:
            part_level_matched = int(part_match.group(1))
            if part_level_matched != dominant_div_level: # Is it a potential part divider?
                processed_level = part_level_matched
                found_explicit_part = True
                part_name_raw = part_match.group(2).strip()
                part_name_clean = re.sub(r'<.*?>', '', part_name_raw).strip()
                if part_name_clean:
                    current_part_name = part_name_clean
                    logging.debug(f"'{book_name}': Part Divider (H{part_level_matched}): '{current_part_name}' @ L{line_num+1}")
                else:
                    current_part_name = f"חלק לא מוגדר {unnamed_part_counter}"
                    unnamed_part_counter += 1
                    logging.debug(f"'{book_name}': Unnamed Part Divider (H{part_level_matched}) -> '{current_part_name}' @ L{line_num+1}")
                # Reset sub-part context when a new part starts
                current_subpart_name = "_default_subpart_"
                found_explicit_subpart = False # Reset for the new part
                unnamed_subpart_counter = 1 # Reset for the new part

        # 2. Check for Sub-Part Divider (H3), *only if* dominant division is H4 and we didn't just process an H1/H2
        if dominant_div_level == 4 and processed_level == 0:
            subpart_match = h3_subpart_regex.search(line_content)
            if subpart_match:
                # Check if H3 itself is the dominant division (edge case)
                if POTENTIAL_SUBPART_LEVEL != dominant_div_level:
                    processed_level = POTENTIAL_SUBPART_LEVEL
                    found_explicit_subpart = True # Mark that H3 dividers exist
                    subpart_name_raw = subpart_match.group(1).strip()
                    subpart_name_clean = re.sub(r'<.*?>', '', subpart_name_raw).strip()
                    if subpart_name_clean:
                        current_subpart_name = subpart_name_clean
                        logging.debug(f"'{book_name}': Sub-Part Divider (H3): '{current_subpart_name}' in Part '{current_part_name}' @ L{line_num+1}")
                    else:
                        current_subpart_name = f"תת-חלק לא מוגדר {unnamed_subpart_counter}"
                        unnamed_subpart_counter += 1
                        logging.debug(f"'{book_name}': Unnamed Sub-Part Divider (H3) -> '{current_subpart_name}' in Part '{current_part_name}' @ L{line_num+1}")

        # 3. Check for Dominant Division (e.g., H3 or H4), if not processed as part/sub-part
        if processed_level == 0:
            division_match = specific_div_regex.search(line_content)
            if division_match:
                processed_level = dominant_div_level # Mark as processed
                identifier_raw = division_match.group(1).strip()
                identifier_clean = re.sub(r'<.*?>', '', identifier_raw).strip()

                # Add data to the correct level in the hierarchy
                part_dict = hierarchy_data[current_part_name]
                # If dominant level is H4, use subpart name; otherwise, use a default key for the subpart level
                target_subpart_key = current_subpart_name if dominant_div_level == 4 else "_level3_default_"
                division_data = part_dict.setdefault(target_subpart_key, {"count": 0, "last_identifier": None})

                division_data["count"] += 1
                division_data["last_identifier"] = identifier_clean


    # --- Final Assembly & Simplification ---
    final_result = {}
    total_parts_with_data = 0
    total_subparts_overall = 0

    for part_name, subparts in hierarchy_data.items():
        part_output = {}
        part_has_data = False
        # Handle default subpart (content before first H3 in H4 scenario, or all content if H3 dominant)
        default_subpart_key = "_level3_default_" if dominant_div_level != 4 else "_default_subpart_"
        default_subpart_label = book_name if (part_name == "_default_part_" and not found_explicit_part) \
                                     else (f"{part_name} (ראשי)" if (found_explicit_subpart and dominant_div_level == 4) else part_name)


        if default_subpart_key in subparts and subparts[default_subpart_key]["count"] > 0:
            subpart_data = subparts[default_subpart_key]
            part_output[default_subpart_label] = { # Use the calculated label
                "division_type": dominant_div_keyword,
                "count": subpart_data["count"],
                "heading_level": f"h{dominant_div_level}",
                "last_identifier_found": subpart_data["last_identifier"]
            }
            part_has_data = True
            total_subparts_overall += 1


        # Handle named/unnamed subparts
        for subpart_name, subpart_data in subparts.items():
            if subpart_name == default_subpart_key: continue # Already handled
            if subpart_data["count"] > 0:
                part_output[subpart_name] = {
                    "division_type": dominant_div_keyword,
                    "count": subpart_data["count"],
                    "heading_level": f"h{dominant_div_level}",
                    "last_identifier_found": subpart_data["last_identifier"]
                }
                part_has_data = True
                total_subparts_overall += 1
            else:
                logging.warning(f"'{book_name}': Sub-Part '{subpart_name}' in Part '{part_name}' identified but contained no divisions.")

        if part_has_data:
            # If the part itself was default and had only one subpart entry (which got relabeled), use the subpart label directly
            if part_name == "_default_part_" and len(part_output) == 1:
                 final_result.update(part_output) # Add the single entry directly to final_result
            else:
                 final_result[part_name] = part_output # Add the part with its subparts
            total_parts_with_data += 1
        elif part_name != "_default_part_":
             logging.warning(f"'{book_name}': Part '{part_name}' identified but contained no countable divisions in any sub-part.")


    # --- Apply Simplification Rules ---
    simplified_result = {}
    if total_parts_with_data == 1 and total_subparts_overall == 1:
        # Only one effective entry overall - flatten completely
        single_part_name = list(final_result.keys())[0]
        # Check if the value itself is nested (it shouldn't be if total_subparts is 1)
        if isinstance(final_result[single_part_name], dict) and "count" in final_result[single_part_name]:
             simplified_result = final_result[single_part_name]
             logging.info(f"'{book_name}': Simplified structure (1 Part, 1 Sub-Part).")
        else: # It was nested, take the inner value
             single_subpart_name = list(final_result[single_part_name].keys())[0]
             simplified_result = final_result[single_part_name][single_subpart_name]
             logging.info(f"'{book_name}': Simplified structure (1 Part, 1 Sub-Part - nested).")

    elif total_parts_with_data == 1 and total_subparts_overall > 1 and dominant_div_level == 4:
        # One main part, but multiple H3 subparts - flatten one level (Book -> SubPart -> Details)
        single_part_name = list(final_result.keys())[0]
        simplified_result = final_result[single_part_name] # Use the inner dict containing subparts
        logging.info(f"'{book_name}': Simplified structure (1 Part, >1 Sub-Parts).")
    else:
        # Multiple parts, or other cases - keep the structure as built
        simplified_result = final_result
        if not simplified_result:
             logging.warning(f"'{book_name}': No countable divisions found in any structure.")

    return book_name, simplified_result


# --- Main Execution (Needs Adjustment for Gematria Check) ---
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

                            # --- Gematria Check (Revised) ---
                            # Function to perform the check on a single data node
                            def perform_gematria_check(data_node, context_name):
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
                                    if count is not None and count > 0: # Only warn if units were counted but no ID found
                                        logging.warning(f"     -> אימות גימטריה ('{context_name}'): לא נמצא מזהה אחרון (נספרו {count} יחידות).")
                                        data_node["gematria_check"] = "Last ID Missing"
                                    else: # No units counted or ID missing - no check needed
                                         data_node["gematria_check"] = "N/A (No Count/ID)"


                            # Determine the structure and apply the check
                            if "division_type" in structured_data: # Case 1: Fully flattened
                                perform_gematria_check(structured_data, book_name)
                            else: # Cases 2 & 3: Potentially nested
                                for level1_key, level1_value in structured_data.items():
                                    # Check if level1_value holds the data directly (Case 2 simplified)
                                    if isinstance(level1_value, dict) and "division_type" in level1_value:
                                        perform_gematria_check(level1_value, f"{book_name} / {level1_key}")
                                    # Check if level1_value is a dict of subparts (Case 3 or Case 2 hierarchical)
                                    elif isinstance(level1_value, dict):
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
            "books_data": overall_results, # Holds potentially varied structures per book
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