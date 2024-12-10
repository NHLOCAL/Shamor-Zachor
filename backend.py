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

    if category not in progress_data:
        progress_data[category] = {}

    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

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

    if category not in progress_data:
        progress_data[category] = {}

    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

    for daf in range(1, total_pages + 1):
        progress_data[category][masechta_name][str(daf)] = {
            "a": value,
            "b": value
        }

    with open(progress_file_path, "w", encoding="utf-8") as file:
        json.dump(progress_data, file, ensure_ascii=False, indent=4)

def load_data():
    data_directory = Path("data")
    json_files = data_directory.glob("*.json")

    combined_data = {}

    for json_file in json_files:
        try:
            with json_file.open("r", encoding="utf-8") as f:
                data = json.load(f)

                if "name" not in data or not isinstance(data["name"], str):
                    raise ValueError(f"Missing or invalid 'name' field in {json_file}. Expected a string.")
                
                if "content_type" not in data or not isinstance(data["content_type"], str):
                    raise ValueError(f"Missing or invalid 'content_type' field in {json_file}. Expected a string.")

                if "columns" not in data or not isinstance(data["columns"], list):
                    raise ValueError(f"Missing or invalid 'columns' field in {json_file}. Expected a list.")

                topic_name = data["name"]
                content_type = data["content_type"]  # קבלת סוג התוכן
                columns = data["columns"]  # קבלת חלוקת העמודות

                if "data" not in data or not isinstance(data["data"], dict):
                    raise ValueError(f"Missing or invalid 'data' field in {json_file}. Expected a dictionary.")

                for masechta_name, masechta_data in data["data"].items():
                    if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                        raise ValueError(f"Invalid masechta data format in {json_file}. 'pages' key missing or not an integer.")

                    # הוספת 'content_type' ו-'columns' לכל מסכת
                    masechta_data["content_type"] = content_type
                    masechta_data["columns"] = columns

                combined_data[topic_name] = data["data"]

        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
            print(f"Error loading {json_file}: {e}")

    return combined_data

def calculate_completion_percentage(masechta_name, category, total_pages):
    """ מחשב את אחוז ההשלמה עבור מסכת נתונה """
    progress = load_progress(masechta_name, category)
    if not progress:
        return 0

    # שימוש במידע מתוך הנתונים עבור חלוקת העמודים
    masechta_data = load_data()[category][masechta_name]
    columns = masechta_data["columns"]

    if len(columns) > 1:
        completed_pages = sum(
            1 for daf_data in progress.values() for amud_value in daf_data.values() if amud_value
        )
    else:
        completed_pages = sum(1 for daf_data in progress.values() if daf_data.get("a", False))

    return round((completed_pages / total_pages) * 100)