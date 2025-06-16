import os
import json

def create_mishna_json(input_dir, output_file):
    """
    Scans a directory of Mishna analysis JSON files (one for each Seder),
    consolidates them into a single structured JSON file, and ensures both
    the Sedarim and Masechtot are in their canonical order.

    Args:
        input_dir (str): The path to the directory containing the source JSON files.
        output_file (str): The path where the final consolidated JSON will be saved.
    """
    # Define the canonical order of all Sedarim and their Masechtot
    MISHNA_ORDER = {
        "סדר זרעים": [
            "ברכות", "פאה", "דמאי", "כלאים", "שביעית", "תרומות",
            "מעשרות", "מעשר שני", "חלה", "ערלה", "ביכורים"
        ],
        "סדר מועד": [
            "שבת", "עירובין", "פסחים", "שקלים", "יומא", "סוכה",
            "ביצה", "ראש השנה", "תענית", "מגילה", "מועד קטן", "חגיגה"
        ],
        "סדר נשים": [
            "יבמות", "כתובות", "נדרים", "נזיר", "סוטה", "גיטין", "קידושין"
        ],
        "סדר נזיקין": [
            "בבא קמא", "בבא מציעא", "בבא בתרא", "סנהדרין", "מכות",
            "שבועות", "עדיות", "עבודה זרה", "אבות", "הוריות"
        ],
        "סדר קדשים": [
            "זבחים", "מנחות", "חולין", "בכורות", "ערכין", "תמורה",
            "כריתות", "מעילה", "תמיד", "מדות", "קינים"
        ],
        "סדר טהרות": [
            "כלים", "אהלות", "נגעים", "פרה", "טהרות", "מקואות", "נדה",
            "מכשירין", "זבים", "טבול יום", "ידים", "עוקצים"
        ]
    }

    # --- שלב 1: איסוף כל המידע מהקבצים למבנה נתונים זמני ---
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
                
                # Prepare a dictionary for this Seder's Masechtot
                collected_data[seder_name] = {}

                for full_masechet_name, details in masechtot_data.items():
                    # Clean name "משנה אהלות" -> "אהלות"
                    cleaned_name = full_masechet_name.replace("משנה ", "").strip()
                    chapter_count = details.get("count")
                    
                    if chapter_count is not None:
                        collected_data[seder_name][cleaned_name] = chapter_count

            except Exception as e:
                print(f"  [שגיאה] אירעה שגיאה בעיבוד הקובץ {filename}: {e}")

    # --- שלב 2: בניית מבנה ה-JSON הסופי לפי הסדר שהוגדר ---
    print("\nשלב 2: מרכיב את קובץ הפלט הסופי לפי הסדר המלא.")
    
    final_json_data = {
        "name": "משנה",
        "content_type": "פרק",
        "subcategories": []
    }

    # Iterate through the Sedarim in the predefined order
    for seder_name, masechtot_in_order in MISHNA_ORDER.items():
        if seder_name not in collected_data:
            print(f"  [אזהרה] לא נמצא קובץ מתאים עבור '{seder_name}'. מדלג על סדר זה.")
            continue
        
        print(f"  מרכיב את '{seder_name}'...")
        
        ordered_books_dict = {}
        # Iterate through the Masechtot for this Seder in the predefined order
        for masechet_name in masechtot_in_order:
            if masechet_name in collected_data[seder_name]:
                chapter_count = collected_data[seder_name][masechet_name]
                # The output format requires 'pages' as the key
                ordered_books_dict[masechet_name] = {"pages": chapter_count}
            else:
                print(f"    [אזהרה] לא נמצאה מסכת '{masechet_name}' בנתונים של '{seder_name}'.")

        seder_subcategory = {
            "name": seder_name,
            "content_type": "פרק",
            "books": ordered_books_dict
        }
        final_json_data["subcategories"].append(seder_subcategory)

    # --- שלב 3: שמירה לקובץ ---
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(final_json_data, f, ensure_ascii=False, indent=2)

    print(f"\nהתהליך הושלם. המידע המאוחד והמסודר נשמר בקובץ: {output_file}")


if __name__ == "__main__":
    # --- הגדרות ---
    # הגדר את שם תיקיית הקלט שבה נמצאים קובצי ה-JSON של סדרי המשנה
    input_directory = "משנה"
    
    # הגדר את שם קובץ הפלט
    output_filename = "mishna_complete_ordered.json"

    # ודא שתיקיית הקלט קיימת
    if not os.path.isdir(input_directory):
        print(f"שגיאה: תיקיית הקלט '{input_directory}' לא נמצאה.")
        print("אנא צור את התיקיה והנח בתוכה את קובצי ה-JSON של המשנה.")
    else:
        create_mishna_json(input_directory, output_filename)