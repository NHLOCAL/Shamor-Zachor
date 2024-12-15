import json
import os
from pathlib import Path
from flet import Page
from datetime import datetime
from pyluach import dates

APP_PREFIX = "nhlocal.shamor_vezachor"  # הקידומת הייחודית שלך

def _get_storage_key(key):
    """ Creates a prefixed storage key """
    return f"{APP_PREFIX}.{key}"

def load_progress(page: Page, masechta_name, category):
    """ Loads the progress for a specific masechta by category from client_storage """
    progress_data = page.client_storage.get(_get_storage_key("progress_data"))
    if progress_data and isinstance(progress_data, dict):
        return progress_data.get(category, {}).get(masechta_name, {})
    return {}

def save_progress(page: Page, masechta_name, daf, amud, value, category):
    """ Saves the progress by masechta, daf and amud according to the category in client_storage """
    progress_data = page.client_storage.get(_get_storage_key("progress_data")) or {}

    if category not in progress_data:
        progress_data[category] = {}

    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

    if daf not in progress_data[category][masechta_name]:
        progress_data[category][masechta_name][daf] = {}

    progress_data[category][masechta_name][daf][amud] = value

    page.client_storage.set(_get_storage_key("progress_data"), progress_data)

def save_all_masechta(page: Page, masechta_name, total_pages, value, category):
    """ Saves the progress for all pages of a masechta according to the category in client_storage """
    progress_data = page.client_storage.get(_get_storage_key("progress_data")) or {}

    if category not in progress_data:
        progress_data[category] = {}

    if masechta_name not in progress_data[category]:
        progress_data[category][masechta_name] = {}

    for daf in range(1, total_pages + 1):
        progress_data[category][masechta_name][str(daf)] = {
            "a": value,
            "b": value
        }

    page.client_storage.set(_get_storage_key("progress_data"), progress_data)

    # שמירת תאריך סיום
    if value:
        save_completion_date(page, masechta_name, category)
        page.update()

def save_completion_date(page: Page, masechta_name, category):
    """ שומר את תאריך הסיום של מסכת """
    completion_dates = page.client_storage.get(_get_storage_key("completion_dates")) or {}
    if category not in completion_dates:
        completion_dates[category] = {}
    completion_dates[category][masechta_name] = datetime.now().strftime("%Y-%m-%d")
    page.client_storage.set(_get_storage_key("completion_dates"), completion_dates)

def get_completion_date(page: Page, masechta_name, category):
    """ מחזיר את תאריך הסיום של מסכת """
    completion_dates = page.client_storage.get(_get_storage_key("completion_dates")) or {}
    date_str = completion_dates.get(category, {}).get(masechta_name)
    if date_str:
        date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
        hebrew_date = dates.GregorianDate(date_obj.year, date_obj.month, date_obj.day).to_heb()
        return hebrew_date.hebrew_date_string()
    return None

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

def calculate_completion_percentage(page: Page, masechta_name, category, total_pages):
    """ Calculates the completion percentage for a given masechta """
    progress = load_progress(page, masechta_name, category)
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