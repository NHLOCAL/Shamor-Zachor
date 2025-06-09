#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Analyses Hebrew religious texts (HTML-like TXT files) to determine their
hierarchical structure (Parts, Sub-Parts, Divisions) and count the divisions.
Performs Gematria validation on the last identifier found in each section.
If validation fails, it identifies and lists all missing division numbers.
Outputs the results to a structured JSON file.
"""

import re
import os
import json
import logging
from datetime import datetime
from collections import defaultdict
from typing import List, Dict, Tuple, Optional, Any

# --- Configuration Constants ---
# Keywords indicating a main countable unit (usually lower level headings)
DIVISION_KEYWORDS = ["פרק", "דף", "סימן", "רמז", "מזמור", "הלכה", "שער", "מאמר", "פסקה", "אות"]
# Heading levels to check for potential PART divisions (highest level)
POTENTIAL_PART_LEVELS = (1, 2)
# Heading level to check for potential SUB-PART divisions (only if main division is H4)
POTENTIAL_SUBPART_LEVEL = 3
# Heading levels typically used for countable divisions (lowest level)
DIVISION_HEADING_LEVELS = (2, 3, 4)
# Minimum occurrences for a pattern to be considered dominant division
MIN_OCCURRENCES = 3
# Default name for content before the first identified part divider
DEFAULT_PART_NAME = "_default_part_"
# Default name for content before the first identified sub-part divider (within a part)
DEFAULT_SUBPART_NAME = "_default_subpart_"
# Placeholder key used when sub-part analysis is not applicable (division is not H4)
LEVEL3_DEFAULT_KEY = "_level3_default_"

# --- Setup Logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)


# --- Utility Functions ---

def hebrew_numeral_to_int(hebrew_num: str) -> int:
    """Converts a Hebrew numeral string (Gematria) to an integer."""
    if not isinstance(hebrew_num, str) or not hebrew_num:
        return 0
    hebrew_num = hebrew_num.replace("'", "").replace('"', '').strip()
    hebrew_num = hebrew_num.replace("תר", "ת" + "ר") # Simplistic high value handling

    gematria_map = {
        'א': 1, 'ב': 2, 'ג': 3, 'ד': 4, 'ה': 5, 'ו': 6, 'ז': 7, 'ח': 8, 'ט': 9,
        'י': 10, 'כ': 20, 'ל': 30, 'מ': 40, 'נ': 50, 'ס': 60, 'ע': 70, 'פ': 80, 'צ': 90,
        'ק': 100, 'ר': 200, 'ש': 300, 'ת': 400
    }

    value, base = 0, hebrew_num
    # Check suffixes first
    if hebrew_num.endswith('טז'): base, value = hebrew_num[:-2], 16
    elif hebrew_num.endswith('טו'): base, value = hebrew_num[:-2], 15

    try:
        current_val = 0
        for char in base:
            digit_val = gematria_map.get(char)
            if digit_val is None:
                # Common non-numeric words
                if any(word in hebrew_num for word in ["הקדמה", "פתיחה", "מבוא", "סוף", "תוכן"]):
                    return 0
                logging.debug(f"Gematria: Invalid char '{char}' in '{hebrew_num}'. Non-numeric.")
                return 0 # Treat as non-numeric identifier
            current_val += digit_val

        total_value = current_val + value
        # Heuristic check for long strings with low value (likely not gematria)
        if len(base) > 3 and total_value < 10 and value == 0:
             logging.debug(f"Gematria: Input '{hebrew_num}' heuristic suggests not numeral. Treating as non-numeric.")
             return 0

        return total_value if total_value > 0 else 0
    except Exception as e:
        logging.error(f"Gematria conversion error for '{hebrew_num}': {e}")
        return 0

def clean_html_content(raw_content: str) -> str:
    """Removes inner HTML tags and excessive whitespace."""
    if not raw_content:
        return ""
    cleaned = re.sub(r'<.*?>', '', raw_content) # Remove tags
    cleaned = re.sub(r'\s+', ' ', cleaned)     # Normalize whitespace
    return cleaned.strip()

# --- Core Analysis Class ---

class TextAnalyzer:
    """Analyzes a single text file for its hierarchical structure."""

    def __init__(self, filepath: str):
        self.filepath = filepath
        self.filename = os.path.basename(filepath)
        self.lines: List[str] = []
        self.book_name: str = os.path.splitext(self.filename)[0] # Default
        self.dominant_div_level: Optional[int] = None
        self.dominant_div_keyword: Optional[str] = None
        # Raw hierarchical data: {part: {subpart: {count, last_id, all_ids}}}
        self.hierarchy_data: Dict[str, Dict[str, Dict[str, Any]]] = defaultdict(
            lambda: defaultdict(lambda: {"count": 0, "last_identifier": None, "all_identifiers": []})
        )
        self._compile_regexes()

    def _compile_regexes(self):
        """Pre-compiles regular expressions used in analysis."""
        # Regex for H1 book name extraction
        self.h1_regex = re.compile(r'^<h1>(.*?)</h1>$', re.IGNORECASE)

        # Regex for finding potential dominant divisions (captures level, keyword, content)
        div_levels_str = "".join(map(str, DIVISION_HEADING_LEVELS))
        div_keywords_pattern = "|".join(re.escape(k) for k in DIVISION_KEYWORDS)
        overall_div_pattern_str = rf'<h([{div_levels_str}])(?: [^>]*)?>\s*?(?:כותרת\s+)?(?:({div_keywords_pattern})\s+(.*?))?\s*</h\1>'
        self.overall_div_regex = re.compile(overall_div_pattern_str, re.IGNORECASE)

        # Regex for finding potential part dividers (H1/H2)
        part_levels_str = "".join(map(str, POTENTIAL_PART_LEVELS))
        any_potential_part_heading_str = rf'<h([{part_levels_str}])(?: [^>]*)?>\s*(.*?)\s*</h\1>'
        self.part_heading_regex = re.compile(any_potential_part_heading_str, re.IGNORECASE)

        # Regex for finding potential sub-part dividers (H3)
        h3_subpart_str = rf'<h{POTENTIAL_SUBPART_LEVEL}(?: [^>]*)?>\s*(.*?)\s*</h{POTENTIAL_SUBPART_LEVEL}>'
        self.subpart_heading_regex = re.compile(h3_subpart_str, re.IGNORECASE)

    def _read_file(self) -> bool:
        """Reads file content into self.lines."""
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                self.lines = f.readlines()
            if not self.lines:
                logging.warning(f"'{self.filename}': File is empty.")
                return False
            return True
        except FileNotFoundError:
            logging.error(f"File not found: {self.filepath}")
            return False
        except Exception as e:
            logging.error(f"Error reading file {self.filepath}: {e}")
            return False

    def _extract_book_name(self):
        """Extracts book name from H1 tag if present."""
        for line in self.lines[:20]: # Check first few lines
            match = self.h1_regex.match(line.strip())
            if match:
                name_raw = match.group(1).strip()
                name_clean = clean_html_content(name_raw)
                if name_clean:
                    self.book_name = name_clean
                    logging.info(f"'{self.filename}': Extracted book name '{self.book_name}' from H1.")
                    return # Found it
        logging.info(f"'{self.filename}': No H1 book name found, using filename '{self.book_name}'.")


    def _find_dominant_division(self) -> bool:
        """Pass 1: Finds the most frequent division pattern (keyword and level)."""
        potential_patterns = defaultdict(int)
        for line in self.lines:
            match = self.overall_div_regex.search(line.strip())
            if match:
                level = int(match.group(1))
                keyword = match.group(2) # Keyword is in group 2
                if keyword: # Only count if a DIVISION_KEYWORD was matched
                    potential_patterns[(level, keyword)] += 1

        frequent_patterns = {
            pat: count for pat, count in potential_patterns.items()
            if count >= MIN_OCCURRENCES
        }

        if not frequent_patterns:
            logging.warning(f"'{self.book_name}': No frequent division pattern (min {MIN_OCCURRENCES}) found.")
            return False

        # Prefer lower heading level, then higher frequency
        min_level = min(level for level, keyword in frequent_patterns.keys())
        candidates = {
            pat: count for pat, count in frequent_patterns.items()
            if pat[0] == min_level
        }
        dominant_pattern = max(candidates.keys(), key=lambda pat: candidates[pat])

        self.dominant_div_level, self.dominant_div_keyword = dominant_pattern
        logging.info(f"'{self.book_name}': Dominant division: H{self.dominant_div_level} '{self.dominant_div_keyword}' "
                     f"({candidates[dominant_pattern]} occurrences >= {MIN_OCCURRENCES}).")
        return True

    def _scan_and_build_hierarchy(self):
        """Pass 2: Scans lines, tracks hierarchy, and counts divisions."""
        if self.dominant_div_level is None or self.dominant_div_keyword is None:
            logging.error(f"'{self.book_name}': Cannot scan hierarchy without dominant division info.")
            return

        # Compile regex for the specific dominant division only once
        specific_div_pattern_str = (
            rf'<h{self.dominant_div_level}(?: [^>]*)?>\s*?'
            rf'(?:כותרת\s+)?{re.escape(self.dominant_div_keyword)}\s+(.*?)\s*'
            rf'</h{self.dominant_div_level}>'
        )
        specific_div_regex = re.compile(specific_div_pattern_str, re.IGNORECASE)

        current_part_name = DEFAULT_PART_NAME
        current_subpart_name = DEFAULT_SUBPART_NAME
        # Initialize default structure to ensure it exists, now with all_identifiers list
        self.hierarchy_data[current_part_name][current_subpart_name] = {"count": 0, "last_identifier": None, "all_identifiers": []}

        unnamed_part_counter = 1
        unnamed_subpart_counter = 1
        found_explicit_part = False

        for line_num, line in enumerate(self.lines):
            line_content = line.strip()
            processed_level = 0

            # 1. Check for Part Divider (H1/H2)
            part_match = self.part_heading_regex.search(line_content)
            if part_match:
                part_level_matched = int(part_match.group(1))
                if part_level_matched != self.dominant_div_level: # Must be different level
                    processed_level = part_level_matched
                    found_explicit_part = True
                    part_name_raw = part_match.group(2).strip()
                    part_name_clean = clean_html_content(part_name_raw)

                    if part_name_clean:
                        current_part_name = part_name_clean
                    else:
                        current_part_name = f"חלק לא מוגדר {unnamed_part_counter}"
                        unnamed_part_counter += 1
                    logging.debug(f"'{self.book_name}': Part Divider (H{part_level_matched}): '{current_part_name}' @ L{line_num+1}")

                    # Reset sub-part context
                    current_subpart_name = DEFAULT_SUBPART_NAME
                    unnamed_subpart_counter = 1
                    # Ensure part/subpart exist in hierarchy data with the new structure
                    self.hierarchy_data.setdefault(current_part_name, defaultdict(lambda: {"count": 0, "last_identifier": None, "all_identifiers": []}))
                    self.hierarchy_data[current_part_name].setdefault(current_subpart_name, {"count": 0, "last_identifier": None, "all_identifiers": []})


            # 2. Check for Sub-Part Divider (H3) - only if H4 is dominant division
            if self.dominant_div_level == 4 and processed_level == 0:
                subpart_match = self.subpart_heading_regex.search(line_content)
                if subpart_match:
                    # Ensure H3 isn't actually the dominant division itself
                    if POTENTIAL_SUBPART_LEVEL != self.dominant_div_level:
                        processed_level = POTENTIAL_SUBPART_LEVEL
                        subpart_name_raw = subpart_match.group(1).strip()
                        subpart_name_clean = clean_html_content(subpart_name_raw)

                        if subpart_name_clean:
                            current_subpart_name = subpart_name_clean
                        else:
                            current_subpart_name = f"תת-חלק לא מוגדר {unnamed_subpart_counter}"
                            unnamed_subpart_counter += 1
                        logging.debug(f"'{self.book_name}': Sub-Part Divider (H3): '{current_subpart_name}' in Part '{current_part_name}' @ L{line_num+1}")
                        # Ensure subpart exists in hierarchy data for the current part with the new structure
                        self.hierarchy_data[current_part_name].setdefault(current_subpart_name, {"count": 0, "last_identifier": None, "all_identifiers": []})


            # 3. Check for Dominant Division
            if processed_level == 0:
                division_match = specific_div_regex.search(line_content)
                if division_match:
                    identifier_raw = division_match.group(1).strip()
                    identifier_clean = clean_html_content(identifier_raw)

                    # Determine target subpart key
                    target_subpart_key = current_subpart_name if self.dominant_div_level == 4 else LEVEL3_DEFAULT_KEY

                    # Get the data dict for the target part/subpart, ensuring defaults exist
                    part_dict = self.hierarchy_data.setdefault(current_part_name, defaultdict(lambda: {"count": 0, "last_identifier": None, "all_identifiers": []}))
                    division_data = part_dict.setdefault(target_subpart_key, {"count": 0, "last_identifier": None, "all_identifiers": []})

                    # Update count, last identifier, and the list of all identifiers
                    division_data["count"] += 1
                    division_data["last_identifier"] = identifier_clean
                    division_data["all_identifiers"].append(identifier_clean)


    def _assemble_and_simplify_result(self) -> Dict[str, Any]:
        """Assembles the final structure and applies simplification rules."""
        if not self.hierarchy_data or self.dominant_div_keyword is None:
            return {}

        final_result_assembly = {} # Holds Part -> (SubPart -> Details) structure

        for part_name, subparts in self.hierarchy_data.items():
            valid_subparts_for_this_part = {}
            # Key for subpart when structure is H2->H3 or H1->H2/H3 (no H3 subparts)
            default_subpart_key_for_non_h4 = LEVEL3_DEFAULT_KEY
            # Key for content before first H3 when dominant division is H4
            default_subpart_key_for_h4 = DEFAULT_SUBPART_NAME
            current_default_key = default_subpart_key_for_h4 if self.dominant_div_level == 4 else default_subpart_key_for_non_h4

            # Check the default/implicit subpart first
            if current_default_key in subparts and subparts[current_default_key]["count"] > 0:
                 # Determine appropriate label for this default content
                 if part_name == DEFAULT_PART_NAME and len(self.hierarchy_data) == 1: # Only default part exists
                     label = self.book_name # Use book name directly
                 else:
                     # Default part content before other named parts OR default subpart before named subparts
                     label = part_name if part_name != DEFAULT_PART_NAME else f"{self.book_name} (מבוא/כללי)"
                 valid_subparts_for_this_part[label] = subparts[current_default_key]


            # Check explicit subparts (only relevant if dominant division is H4)
            if self.dominant_div_level == 4:
                for subpart_name, subpart_data in subparts.items():
                    if subpart_name == current_default_key: continue # Already handled
                    if subpart_data["count"] > 0:
                        valid_subparts_for_this_part[subpart_name] = subpart_data
                    else:
                        logging.warning(f"'{self.book_name}': Sub-Part '{subpart_name}' in Part '{part_name}' identified but empty.")


            # --- Decide Structure for this Part ---
            num_valid_subparts = len(valid_subparts_for_this_part)
            part_label_final = part_name if part_name != DEFAULT_PART_NAME else self.book_name

            if num_valid_subparts == 1:
                # Simplify: Use the details from the single valid subpart directly under the part label
                single_subpart_details = list(valid_subparts_for_this_part.values())[0]
                final_result_assembly[part_label_final] = {
                    "division_type": self.dominant_div_keyword,
                    "count": single_subpart_details["count"],
                    "heading_level": f"h{self.dominant_div_level}",
                    "last_identifier_found": single_subpart_details["last_identifier"],
                    "all_identifiers_found": single_subpart_details["all_identifiers"] # Intermediate field
                }
                logging.debug(f"'{self.book_name}': Simplified Part '{part_label_final}' (1 sub-part).")

            elif num_valid_subparts > 1:
                # Keep subpart structure: Part -> SubPart -> Details
                part_data_nested = {}
                for subpart_label, subpart_details in valid_subparts_for_this_part.items():
                    part_data_nested[subpart_label] = {
                        "division_type": self.dominant_div_keyword,
                        "count": subpart_details["count"],
                        "heading_level": f"h{self.dominant_div_level}",
                        "last_identifier_found": subpart_details["last_identifier"],
                        "all_identifiers_found": subpart_details["all_identifiers"] # Intermediate field
                    }
                final_result_assembly[part_label_final] = part_data_nested
                logging.debug(f"'{self.book_name}': Kept Sub-Part structure for Part '{part_label_final}' ({num_valid_subparts} sub-parts).")

            # If num_valid_subparts == 0, log warning if part was explicitly named
            elif part_name != DEFAULT_PART_NAME:
                 logging.warning(f"'{self.book_name}': Part '{part_name}' identified but contained no countable divisions.")


        # --- Apply Final Overall Simplification ---
        if len(final_result_assembly) == 1:
             # Only one top-level key remains, flatten completely
             single_toplevel_key = list(final_result_assembly.keys())[0]
             final_output_structure = final_result_assembly[single_toplevel_key]
             logging.info(f"'{self.book_name}': Simplified structure: Only one effective top-level part found ('{single_toplevel_key}'). Final structure is flat.")
        elif not final_result_assembly:
             logging.warning(f"'{self.book_name}': No countable divisions found in any structure.")
             final_output_structure = {}
        else:
             # Multiple top-level parts, keep the structure as assembled
             final_output_structure = final_result_assembly
             logging.info(f"'{self.book_name}': Multiple effective top-level parts found ({len(final_result_assembly)}). Keeping hierarchical structure.")

        return final_output_structure


    def analyze(self) -> Dict[str, Any]:
        """Orchestrates the analysis process for the file."""
        if not self._read_file():
            return {}
        self._extract_book_name()
        if not self._find_dominant_division():
            return {} # Cannot proceed without knowing what to count

        self._scan_and_build_hierarchy()
        return self._assemble_and_simplify_result()

# --- Runner Class ---

class AnalysisRunner:
    """Manages the analysis process for a directory of files."""

    def __init__(self, input_dir: str):
        self.input_dir = input_dir
        self.results: Dict[str, Any] = {} # Stores {book_name: structured_data}

    def _get_output_path(self) -> str:
        """Determines the output JSON file path."""
        script_dir = os.path.dirname(os.path.abspath(__file__))
        input_folder_name = os.path.basename(os.path.normpath(self.input_dir))
        safe_folder_name = re.sub(r'[\\/*?:"<>|]', '_', input_folder_name) # Sanitize
        output_filename = f"{safe_folder_name}_analysis.json" # Changed name slightly
        return os.path.join(script_dir, output_filename)

    def _perform_gematria_checks(self):
        """Iterates through results and adds Gematria check information."""
        logging.info("--- Performing Gematria Validation ---")
        for book_name, structured_data in self.results.items():
            if not structured_data: continue

            # Apply check recursively or based on identified structure
            self._apply_gematria_check_recursive(structured_data, book_name)

    def _apply_gematria_check_recursive(self, data_node: Any, context_name: str):
        """Applies Gematria check potentially recursively."""
        if isinstance(data_node, dict) and "division_type" in data_node:
            # This node holds the countable data, perform the check
            self._perform_single_gematria_check(data_node, context_name)
        elif isinstance(data_node, dict):
            # This node is a container (Part or Book level), recurse into its values
            for key, value in data_node.items():
                # Build context name for logging
                new_context = f"{context_name} / {key}"
                self._apply_gematria_check_recursive(value, new_context)
        # else: It's not a dict or not the data node we're looking for, stop recursion

    def _find_missing_divisions(self, data_node: Dict[str, Any]) -> List[int]:
        """
        Identifies missing sequential division numbers based on the list of all
        identifiers found.
        """
        last_id = data_node.get('last_identifier_found')
        all_ids = data_node.get('all_identifiers_found', [])
        
        if not last_id or not all_ids:
            return [] # Cannot determine missing numbers without data

        # The expected maximum number is the Gematria of the last identifier.
        expected_max = hebrew_numeral_to_int(last_id)
        if expected_max <= 0:
            logging.debug(f"Cannot find missing divisions; last ID '{last_id}' is not a valid positive number.")
            return []
            
        # Convert all found identifiers to their integer values.
        # Use a set for efficient lookup and to handle duplicates.
        found_numbers = {hebrew_numeral_to_int(id_str) for id_str in all_ids}
        found_numbers.discard(0) # Remove non-numeric entries like 'הקדמה'

        if not found_numbers:
            return []

        # Create the full expected set of numbers from 1 to the max.
        expected_set = set(range(1, expected_max + 1))
        
        # The missing numbers are the difference between the sets.
        missing_numbers = sorted(list(expected_set - found_numbers))
        
        return missing_numbers


    def _perform_single_gematria_check(self, data_node: Dict[str, Any], context_name: str):
        """Performs Gematria check on a single data node and updates it."""
        logging.info(f"  -> Checking: {context_name} | Count: {data_node.get('count', 'N/A')} | Last ID: '{data_node.get('last_identifier_found', 'N/A')}'")
        last_id = data_node.get('last_identifier_found')
        count = data_node.get('count')
        check_result = "N/A"

        if last_id and count is not None and count > 0:
            gematria_value = hebrew_numeral_to_int(last_id)
            
            ### MODIFIED ###
            # Add the calculated Gematria value to the node for output.
            data_node["last_identifier_gematria"] = gematria_value
            
            if gematria_value > 0:
                if gematria_value == count:
                    logging.info(f"     -> Gematria ('{context_name}'): Match! ('{last_id}' = {gematria_value})")
                    check_result = "Match"
                else:
                    logging.warning(f"     -> Gematria ('{context_name}'): Mismatch! ('{last_id}' = {gematria_value}, Count = {count})")
                    check_result = f"Mismatch (ID:{gematria_value}, Count:{count})"
            else:
                logging.warning(f"     -> Gematria ('{context_name}'): Last ID ('{last_id}') is non-numeric.")
                check_result = "Non-numeric ID"
        elif count is not None and count > 0:
             logging.warning(f"     -> Gematria ('{context_name}'): Last ID missing (Count = {count}).")
             check_result = "Last ID Missing"
        else:
            check_result = "N/A (No Count/ID)"

        data_node["gematria_check"] = check_result
        
        # If the check did not result in a perfect match, find missing divisions.
        # We also check for "N/A" to avoid running on empty sections.
        if check_result not in ["Match", "N/A", "N/A (No Count/ID)"]:
            missing = self._find_missing_divisions(data_node)
            if missing:
                logging.warning(f"     -> Missing divisions found for '{context_name}': {len(missing)} items. Example: {missing[:10]}")
                data_node["missing_divisions"] = missing

        # Remove the intermediate list of all identifiers from the final output.
        data_node.pop("all_identifiers_found", None)


    def run_analysis(self):
        """Runs the analysis for all files in the input directory."""
        logging.info(f"Starting analysis in directory: {self.input_dir}")
        output_path = self._get_output_path() # Determine output path early
        logging.info(f"Output will be saved to: {output_path}")

        files_processed = 0
        for filename in os.listdir(self.input_dir):
            # Consider common text/markup file extensions
            if filename.lower().endswith(('.txt', '.html', '.htm')):
                filepath = os.path.join(self.input_dir, filename)
                # Skip the output file itself and ensure it's a file
                if os.path.isfile(filepath) and filepath != output_path:
                    logging.info(f"--- Analyzing file: '{filename}' ---")
                    try:
                        analyzer = TextAnalyzer(filepath)
                        structured_data = analyzer.analyze()
                        if structured_data: # Only add if analysis yielded results
                            self.results[analyzer.book_name] = structured_data
                        files_processed += 1
                    except Exception as e:
                        logging.error(f"!!! Critical error analyzing file '{filename}': {e}", exc_info=True)
            # else: skip non-text files silently or log debug message

        if not self.results:
             logging.warning("Analysis complete, but no structured data was generated for any file.")
             return # Don't perform checks or write empty file

        # Perform Gematria checks on the collected results
        self._perform_gematria_checks()

        # Write the final output
        self._write_json_output(output_path)
        logging.info(f"--- Analysis complete. Processed {files_processed} files. ---")


    def _write_json_output(self, output_path: str):
        """Writes the collected results to a JSON file."""
        final_output_json = {
            "collection_name": os.path.basename(os.path.normpath(self.input_dir)) or "Unknown Collection",
            "processed_folder": self.input_dir,
            "books_data": self.results, # Contains potentially varied structures
            "analysis_timestamp": datetime.now().isoformat()
        }

        try:
            with open(output_path, 'w', encoding='utf-8') as outfile:
                json.dump(final_output_json, outfile, ensure_ascii=False, indent=4)
            logging.info(f"Successfully wrote analysis results to: {output_path}")
        except Exception as e:
            logging.error(f"Critical error writing JSON output to '{output_path}': {e}", exc_info=True)


# --- Main Execution ---
if __name__ == "__main__":
    print("Hebrew Text Structure Analyzer")
    print("-" * 30)
    input_dir_raw = input("Enter the path to the directory containing text files (can include quotes): ")
    input_dir_clean = input_dir_raw.strip().strip('"').strip("'")

    if not os.path.isdir(input_dir_clean):
        logging.error(f"Error: Input path '{input_dir_clean}' is not a valid directory.")
    else:
        runner = AnalysisRunner(input_dir_clean)
        runner.run_analysis()
        print("-" * 30)
        print("Processing finished. Check log messages above for details.")