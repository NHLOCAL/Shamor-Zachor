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
    def save_progress(page: Page, masechta_name: str, daf: int, amud: str, value: bool, category: str):
        """
        שומר את התקדמות המשתמש עבור מסכת/ספר מסוים (daf, amud).
        משתמש ב-setdefault כדי לצמצם קוד כפול.
        מוסיף לוגיקה למחיקת מסכת אם אין התקדמות.
        """
        progress_data = page.client_storage.get(ProgressManager._get_storage_key("progress_data")) or {}
        masechta_progress = progress_data.setdefault(category, {}).setdefault(masechta_name, {})
        masechta_progress.setdefault(str(daf), {})[amud] = value

        # בדיקה אם יש התקדמות - אם לא, נמחק את המסכת
        if not any(amud_val for daf_data in masechta_progress.values() for amud_val in daf_data.values()):
            if masechta_name in progress_data.get(category, {}):
                del progress_data[category][masechta_name]
            if not progress_data.get(category, {}):
                del progress_data[category]

        page.client_storage.set(ProgressManager._get_storage_key("progress_data"), progress_data)

    @staticmethod
    def save_all_masechta(page: Page, masechta_name: str, total_pages: int, value: bool, category: str):
        """
        מסמן את כל הדפים והעמודים כגמורים/לא גמורים עבור מסכת/ספר מסוים.
        מוסיף לוגיקה למחיקת מסכת אם מסמנים שהכל לא גמור
        """
        progress_data = page.client_storage.get(ProgressManager._get_storage_key("progress_data")) or {}
        if value == False:
            if masechta_name in progress_data.get(category, {}):
                 del progress_data[category][masechta_name]
            if not progress_data.get(category, {}):
                del progress_data[category]
        else:
            progress_data.setdefault(category, {}).setdefault(masechta_name, {})
            for daf in range(1, total_pages + 1):
                progress_data[category][masechta_name][str(daf)] = {
                    "a": value,
                    "b": value
                }


        page.client_storage.set(ProgressManager._get_storage_key("progress_data"), progress_data)

        # אם סימנו כגמור - שומרים תאריך סיום
        if value:
            ProgressManager.save_completion_date(page, masechta_name, category)

    @staticmethod
    def save_completion_date(page: Page, masechta_name: str, category: str):
        """
        שמירת תאריך סיום עבור מסכת/ספר ב-client_storage.
        """
        completion_dates = page.client_storage.get(ProgressManager._get_storage_key("completion_dates")) or {}
        completion_dates.setdefault(category, {})[masechta_name] = datetime.now().strftime("%Y-%m-%d")
        page.client_storage.set(ProgressManager._get_storage_key("completion_dates"), completion_dates)

    @staticmethod
    def get_completion_date(page: Page, masechta_name: str, category: str) -> str:
        """
        מחזיר את מחרוזת תאריך הסיום עבור מסכת/ספר מסוים (פורמט עברי).
        """
        completion_dates = page.client_storage.get(ProgressManager._get_storage_key("completion_dates")) or {}
        date_str = completion_dates.get(category, {}).get(masechta_name)
        return date_str  # מחזירים את התאריך בפורמט 'YYYY-MM-DD'. נעשה המרה בתצוגה עצמה.


def get_completed_pages(progress: dict, columns: list) -> int:
    """
    מחזיר כמה עמודים הושלמו (משמש לפונקציות חיצוניות).
    """
    if columns == ["עמוד א", "עמוד ב"]:
        return sum(
            1 for daf_data in progress.values() for amud_value in daf_data.values() if amud_value
        )
    return sum(1 for daf_data in progress.values() if daf_data.get("a", False))