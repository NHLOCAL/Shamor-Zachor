import os
import json

def create_shas_json(input_dir, output_file):
    """
    Scans a directory of Talmud Bavli analysis JSON files, consolidates them
    into a single structured JSON file, and ensures canonical order for
    Sedarim and Masechtot. It also calculates daf count from amud count.

    Args:
        input_dir (str): The path to the directory containing the source JSON files.
        output_file (str): The path where the final consolidated JSON will be saved.
    """
    # Define the canonical order based on the provided shas.json example
    SHAS_ORDER = {
        "סדר זרעים": ["ברכות"],
        "סדר מועד": [
            "שבת", "עירובין", "פסחים", "שקלים", "יומא", "סוכה",
            "ביצה", "ראש השנה", "תענית", "מגילה", "מועד קטן", "חגיגה"
        ],
        "סדר נשים": [
            "יבמות", "כתובות", "נדרים", "נזיר", "סוטה", "גיטין", "קידושין"
        ],
        "סדר נזיקין": [
            "בבא קמא", "בבא מציעא", "בבא בתרא", "סנהדרין", "מכות",
            "שבועות", "עבודה זרה", "הוריות"
        ],
        "סדר קדשים": [
            "זבחים", "מנחות", "חולין", "בכורות", "ערכין", "תמורה",
            "כריתות", "מעילה", "תמיד"
        ],
        "סדר טהרות": ["נדה"]
    }

    # --- שלב 1: איסוף כל המידע מהקבצים ---
    collected_data = {}
    print(f"שלב 1: מתחיל סריקה ואיסוף מידע מהתיקיה: {input_dir}")

    for filename in os.listdir(input_dir):
        if filename.endswith("_analysis.json"):
            file_path = os.path.join(input_dir, filename)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)

                seder_name = data.get("collection_name")
                masechtot_data = data.get("books_data")

                if not seder_name or not masechtot_data:
                    print(f"  [אזהרה] קובץ {filename} חסר מידע. מדלג.")
                    continue
                
                print(f"  מעבד את הקובץ עבור: {seder_name}")
                
                collected_data[seder_name] = {}

                for masechet_name, details in masechtot_data.items():
                    amud_count = details.get("count")
                    
                    if amud_count is not None:
                        # Logic to calculate daf count from amud count.
                        # The formula is count / 2, allowing for floating point numbers (e.g., 14.5).
                        daf_count = amud_count / 2
                        
                        # The key in books_data is already the clean Masechet name
                        collected_data[seder_name][masechet_name.strip()] = daf_count
                    else:
                        print(f"    [אזהרה] לא נמצא 'count' עבור '{masechet_name}'.")

            except Exception as e:
                print(f"  [שגיאה] אירעה שגיאה בעיבוד הקובץ {filename}: {e}")

    # --- שלב 2: בניית מבנה ה-JSON הסופי לפי הסדר שהוגדר ---
    print("\nשלב 2: מרכיב את קובץ הפלט הסופי לפי הסדר המלא.")
    
    final_json_data = {
        "name": "תלמוד בבלי",
        "content_type": "דף",
        "subcategories": []
    }

    # Iterate through the Sedarim in the predefined order
    for seder_name, masechtot_in_order in SHAS_ORDER.items():
        if seder_name not in collected_data:
            print(f"  [אזהרה] לא נמצא קובץ מתאים עבור '{seder_name}'. מדלג על סדר זה.")
            continue
        
        print(f"  מרכיב את '{seder_name}'...")
        
        ordered_books_dict = {}
        # Iterate through the Masechtot for this Seder in the predefined order
        for masechet_name in masechtot_in_order:
            if masechet_name in collected_data[seder_name]:
                daf_count = collected_data[seder_name][masechet_name]
                ordered_books_dict[masechet_name] = {"pages": daf_count}
            else:
                print(f"    [אזהרה] לא נמצאה מסכת '{masechet_name}' בנתונים של '{seder_name}'.")

        seder_subcategory = {
            "name": seder_name,
            "content_type": "דף",
            "books": ordered_books_dict
        }
        final_json_data["subcategories"].append(seder_subcategory)

    # --- שלב 3: שמירה לקובץ ---
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(final_json_data, f, ensure_ascii=False, indent=2)

    print(f"\nהתהליך הושלם. המידע המאוחד והמסודר נשמר בקובץ: {output_file}")


if __name__ == "__main__":
    # --- הגדרות ---
    # הגדר את שם תיקיית הקלט שבה נמצאים קובצי ה-JSON של סדרי הש"ס
    input_directory = "תלמוד בבלי"
    
    # הגדר את שם קובץ הפלט
    output_filename = "shas_complete_ordered.json"

    # ודא שתיקיית הקלט קיימת
    if not os.path.isdir(input_directory):
        print(f"שגיאה: תיקיית הקלט '{input_directory}' לא נמצאה.")
        print("אנא צור את התיקיה והנח בתוכה את קובצי ה-JSON של התלמוד הבבלי.")
    else:
        create_shas_json(input_directory, output_filename)