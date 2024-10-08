import json
import os

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
    def load_json_file(filename):
        try:
            with open(filename, "r", encoding="utf-8") as f:
                data = json.load(f)
                if not isinstance(data, dict):
                    raise ValueError(f"Invalid data format in {filename}. Expected a dictionary.")
                for masechta_data in data.values():
                    if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                        raise ValueError(f"Invalid masechta data format in {filename}. 'pages' key missing or not an integer.")
                return data
        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
            print(f"Error loading {filename}: {e}")
            return {}

    # Load data from different sources
    shas_data = load_json_file("data/shas.json")
    yerushalmi_data = load_json_file("data/yerushalmi.json")
    tanach_data = load_json_file("data/tanach.json")
    rambam_data = load_json_file("data/rambam.json")
    shulchan_aruch_data = load_json_file("data/shulchan_aruch.json")

    # Combine all data into a single dictionary
    combined_data = {
        "תלמוד בבלי": shas_data,
        "תלמוד ירושלמי": yerushalmi_data,
        "תנ״ך": tanach_data,
        "רמב״ם": rambam_data,
        "שולחן ערוך": shulchan_aruch_data
    }

    return combined_data
