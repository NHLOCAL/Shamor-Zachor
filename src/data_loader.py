import json
import logging
from functools import lru_cache
from pathlib import Path
from pyluach import dates

# הגדרת לוגר בסיסי
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@lru_cache(maxsize=1)
def load_data():
    """
    טוען ומאחד את נתוני ה-JSON ממספר קבצים בתיקיית 'data'.
    מיושמת כאן פונקציית Cache כדי למנוע טעינות חוזרות.
    """
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
                content_type = data["content_type"]
                columns = data["columns"]

                # בדיקה אם זה קובץ ש"ס ואז מגדירים start_page ל-2 אחרת 1
                if json_file.name in ["shas.json", "yerushalmi.json"]:
                   start_page = 2
                else:
                   start_page = 1


                if "data" not in data or not isinstance(data["data"], dict):
                    raise ValueError(f"Missing or invalid 'data' field in {json_file}. Expected a dictionary.")

                # הוספת מאפיינים לכל מסכת במילון
                for masechta_name, masechta_data in data["data"].items():
                    if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                        raise ValueError(f"Invalid masechta data format in {json_file}. 'pages' key missing or not an integer.")
                    masechta_data["content_type"] = content_type
                    masechta_data["columns"] = columns
                    masechta_data["start_page"] = start_page # הוספה של start_page לכל מסכת

                combined_data[topic_name] = data["data"]

        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
            logger.error(f"Error loading {json_file}: {e}")

    return combined_data


def get_total_pages(masechta_data: dict) -> int:
    """
    פונקציה לחישוב מספר העמודים הכולל עבור מסכת/ספר,
    בהתחשב במספר העמודות.
    """
    if masechta_data["columns"] == ["עמוד א", "עמוד ב"]:
        return 2 * masechta_data["pages"]
    return masechta_data["pages"]


def get_completion_date_string(date_str: str):
    """
    ממיר מחרוזת תאריך פורמט 'YYYY-MM-DD' לתאריך עברי.
    מחזיר מחרוזת תאריך עברית או None אם לא קיים.
    """
    from datetime import datetime
    if not date_str:
        return None
    date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
    hebrew_date = dates.GregorianDate(date_obj.year, date_obj.month, date_obj.day).to_heb()
    return hebrew_date.hebrew_date_string()