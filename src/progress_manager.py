from datetime import datetime
from flet import Page

class ProgressManager:
    """
    מחלקה סטטית לניהול קריאה ושמירת התקדמות המשתמש ב-client_storage של Flet.
    """
    APP_PREFIX = "nhlocal.shamor_vezachor"

    @staticmethod
    def _get_storage_key(key: str) -> str:
        return f"{ProgressManager.APP_PREFIX}.{key}"

    @staticmethod
    def load_progress(page: Page, masechta_name: str, category: str) -> dict:
        progress_data = page.client_storage.get(ProgressManager._get_storage_key("progress_data"))
        if progress_data and isinstance(progress_data, dict):
            return progress_data.get(category, {}).get(masechta_name, {})
        return {}

    @staticmethod
    def save_progress(page: Page, masechta_name: str, daf: int, amud: str, column: str, value: bool, category: str):
        """
        שומר את התקדמות המשתמש עבור מסכת/ספר מסוים (daf, amud, column).
        משתמש ב-setdefault כדי לצמצם קוד כפול.
        """
        progress_data = page.client_storage.get(ProgressManager._get_storage_key("progress_data")) or {}
        daf_str = str(daf)
        masechta_progress = progress_data.setdefault(category, {}).setdefault(masechta_name, {})
        
        # אם יש ערך בוליאני קיים עבור daf/amud, נחליף אותו במילון
        daf_entry = masechta_progress.setdefault(daf_str, {})
        if amud not in daf_entry or not isinstance(daf_entry[amud], dict):
            daf_entry[amud] = {}

        daf_entry[amud][column] = value

        # בודק אם כל הערכים ל"לימוד" הם False, אם כן, מוחק את המידע עבור הדף
        current_amud = masechta_progress.get(daf_str, {}).get(amud, {})
        if isinstance(current_amud, dict) and "learn" in current_amud and not current_amud["learn"]:
            reviews = ["review1", "review2", "review3"]
            if all(not current_amud.get(review, False) for review in reviews):
                if amud in masechta_progress.get(daf_str, {}):
                    del masechta_progress[daf_str][amud]
                if not masechta_progress.get(daf_str, {}):
                    del masechta_progress[daf_str]

        # בדיקה אם יש התקדמות - אם לא, נמחק את המסכת
        if not any(
            amud_val
            for daf_data in masechta_progress.values()
            for amud_data in daf_data.values()
            for amud_val in (amud_data.values() if isinstance(amud_data, dict) else [amud_data])
        ):
            if masechta_name in progress_data.get(category, {}):
                del progress_data[category][masechta_name]
            if not progress_data.get(category, {}):
                del progress_data[category]

        page.client_storage.set(ProgressManager._get_storage_key("progress_data"), progress_data)

    @staticmethod
    def save_all_masechta(page: Page, masechta_name: str, total_pages: int, value: bool, category: str):
        """
        מסמן את כל הדפים והעמודים כגמורים/לא גמורים עבור מסכת/ספר מסוים.
        """
        progress_data = page.client_storage.get(ProgressManager._get_storage_key("progress_data")) or {}

        if value == False:
            if masechta_name in progress_data.get(category, {}):
                del progress_data[category][masechta_name]
            if not progress_data.get(category, {}):
                del progress_data[category]
        else:
            masechta_progress = progress_data.setdefault(category, {}).setdefault(masechta_name, {})
            for daf in range(1, total_pages + 1):
                daf_str = str(daf)
                daf_entry = masechta_progress.setdefault(daf_str, {})
                for amud in ["a", "b"]:
                    # אם הערך עבור amud אינו מילון, נחליף אותו במילון
                    if amud not in daf_entry or not isinstance(daf_entry[amud], dict):
                        daf_entry[amud] = {}
                    for column in ["learn", "review1", "review2", "review3"]:
                        daf_entry[amud][column] = value

        page.client_storage.set(ProgressManager._get_storage_key("progress_data"), progress_data)

        if value:
            ProgressManager.save_completion_date(page, masechta_name, category)

    @staticmethod
    def save_completion_date(page: Page, masechta_name: str, category: str):
        """
        שמירת תאריך סיום עבור מסכת/ספר ב-client_storage.
        התאריך נשמר רק אם סימנו את כל הדפים כ"לימוד" בפעם הראשונה.
        """
        completion_dates = page.client_storage.get(ProgressManager._get_storage_key("completion_dates")) or {}
        
        if masechta_name not in completion_dates.get(category, {}):
            completion_dates.setdefault(category, {})[masechta_name] = datetime.now().strftime("%Y-%m-%d")
            page.client_storage.set(ProgressManager._get_storage_key("completion_dates"), completion_dates)

    @staticmethod
    def get_completion_date(page: Page, masechta_name: str, category: str) -> str:
        """
        מחזיר את מחרוזת תאריך הסיום עבור מסכת/ספר מסוים (פורמט עברי).
        """
        completion_dates = page.client_storage.get(ProgressManager._get_storage_key("completion_dates")) or {}
        date_str = completion_dates.get(category, {}).get(masechta_name)
        return date_str

def get_completed_pages(progress: dict, columns: list) -> int:
    """
    מחזיר כמה עמודים הושלמו (סופרים רק את העמודים שסומנו כ"לימוד").
    תומך גם במבנה חדש (מילון) וגם במבנה ישן (בוליאני).
    """
    completed_count = 0
    for daf_data in progress.values():
        for amud_data in daf_data.values():
            if isinstance(amud_data, dict):
                if amud_data.get("learn", False):
                    completed_count += 1
            elif isinstance(amud_data, bool):
                if amud_data:
                    completed_count += 1
    return completed_count
