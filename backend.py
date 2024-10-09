import json
import os
from pathlib import Path

progress_file_path = "progress.json"

def load_progress(masechta_name, category):
    """ טוען את ההתקדמות עבור מסכת מסוימת לפי הנושא שלה """
    if os.path.exists(progress_file_path):
        with open(progress_file_path, "r", encoding="utf-8") as file:
            progress_data = json.load(file)
            return progress_data.get(category, {}).get(masechta_name, {})
    return {}

def save_progress(masechta_name, daf, amud, value, category):
    """ שומר את ההתקדמות לפי מסכת, דף ועמוד בהתאם לקטגוריה """
    progress_data = {}
    if os.path.exists(progress_file_path):
        with open(progress_file_path, "r", encoding="utf-8") as file:
            progress_data = json.load(file)

    # וידוא שיש קטגוריה רלוונטית
    if category not in progress_data:
        progress_data[category] = {}

    # וידוא שיש רשומת מסכת רלוונטית בקטגוריה
    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

    # שמירת ההתקדמות עבור המסכת
    if daf not in progress_data[category][masechta_name]:
        progress_data[category][masechta_name][daf] = {}

    progress_data[category][masechta_name][daf][amud] = value

    with open(progress_file_path, "w", encoding="utf-8") as file:
        json.dump(progress_data, file, ensure_ascii=False, indent=4)

def save_all_masechta(masechta_name, total_pages, value, category):
    """ שומר את ההתקדמות עבור כל דפי המסכת במסכת מסוימת בהתאם לקטגוריה """
    progress_data = {}
    if os.path.exists(progress_file_path):
        with open(progress_file_path, "r", encoding="utf-8") as file:
            progress_data = json.load(file)

    # וידוא שיש קטגוריה רלוונטית
    if category not in progress_data:
        progress_data[category] = {}

    # וידוא שיש רשומת מסכת רלוונטית בקטגוריה
    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

    # עדכון כל העמודים במסכת
    for daf in range(1, total_pages + 1):
        progress_data[category][masechta_name][str(daf)] = {
            "a": value,
            "b": value
        }

    with open(progress_file_path, "w", encoding="utf-8") as file:
        json.dump(progress_data, file, ensure_ascii=False, indent=4)



def load_data():
    data_directory = Path("data")  # Define the directory
    json_files = data_directory.glob("*.json")  # Get all JSON files in the directory

    combined_data = {}

    for json_file in json_files:
        try:
            with json_file.open("r", encoding="utf-8") as f:
                data = json.load(f)
                
                # Ensure the data contains the 'name' key and it's a string
                if "name" not in data or not isinstance(data["name"], str):
                    raise ValueError(f"Missing or invalid 'name' field in {json_file}. Expected a string.")
                
                topic_name = data["name"]  # Use the 'name' field in the JSON file
                
                # Ensure 'data' key exists and contains valid information
                if "data" not in data or not isinstance(data["data"], dict):
                    raise ValueError(f"Missing or invalid 'data' field in {json_file}. Expected a dictionary.")

                # Optional: Validate structure within 'data'
                for masechta_data in data["data"].values():
                    if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                        raise ValueError(f"Invalid masechta data format in {json_file}. 'pages' key missing or not an integer.")
                
                combined_data[topic_name] = data["data"]  # Add the 'data' content under the Hebrew topic name

        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
            print(f"Error loading {json_file}: {e}")

    return combined_data
