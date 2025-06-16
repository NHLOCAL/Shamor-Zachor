import os
import json

def create_mishneh_torah_json(input_dir, output_file):
    """
    Scans a directory of Mishneh Torah analysis JSON files, consolidates them
    into a single structured JSON file, and ensures the Sefarim are in a
    predefined order.

    Args:
        input_dir (str): The path to the directory containing the source JSON files.
        output_file (str): The path where the final consolidated JSON will be saved.
    """
    # Define the canonical order of the 14 books of Mishneh Torah
    SEFARIM_ORDER = [
        "ספר המדע", "ספר אהבה", "ספר זמנים", "ספר נשים",
        "ספר קדושה", "ספר הפלאה", "ספר זרעים", "ספר עבודה",
        "ספר קרבנות", "ספר טהרה", "ספר נזיקין", "ספר קניין",
        "ספר משפטים", "ספר שופטים"
    ]

    # --- שלב 1: איסוף כל המידע מהקבצים ---
    collected_sefarim = {}
    print(f"שלב 1: מתחיל סריקה ואיסוף מידע מהתיקיה: {input_dir}")

    for filename in os.listdir(input_dir):
        if filename.endswith("_analysis.json"):
            file_path = os.path.join(input_dir, filename)
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)

                sefer_name = data.get("collection_name")
                hilchot_data = data.get("books_data")

                if not sefer_name or not hilchot_data:
                    print(f"  [אזהרה] קובץ {filename} חסר 'collection_name' או 'books_data'. מדלג.")
                    continue
                
                print(f"  מעבד את הקובץ עבור: {sefer_name}")

                parts_list = []
                for full_hilchot_name, details in hilchot_data.items():
                    cleaned_name = full_hilchot_name.replace("משנה תורה, ", "").strip()
                    chapter_count = details.get("count")

                    if chapter_count is not None:
                        parts_list.append({
                            "name": cleaned_name,
                            "start": 1,
                            "end": chapter_count
                        })
                
                # Store the processed data with the sefer name as the key
                collected_sefarim[sefer_name] = {"parts": parts_list}

            except Exception as e:
                print(f"  [שגיאה] אירעה שגיאה בעיבוד הקובץ {filename}: {e}")

    # --- שלב 2: בניית מבנה ה-JSON הסופי לפי הסדר הרצוי ---
    print("\nשלב 2: מרכיב את קובץ הפלט הסופי לפי הסדר שהוגדר.")
    
    # Use a standard dict, as Python 3.7+ and json.dump preserve insertion order
    ordered_books_dict = {}
    
    found_sefarim_in_order = []
    for sefer_name in SEFARIM_ORDER:
        if sefer_name in collected_sefarim:
            ordered_books_dict[sefer_name] = collected_sefarim[sefer_name]
            found_sefarim_in_order.append(sefer_name)
        else:
            print(f"  [אזהרה] לא נמצא קובץ מתאים עבור '{sefer_name}' בתיקיית הקלט.")

    # Check for any found books that were not in the predefined order list
    collected_keys = set(collected_sefarim.keys())
    ordered_keys = set(found_sefarim_in_order)
    extra_books = collected_keys - ordered_keys
    if extra_books:
        print(f"  [אזהרה] נמצאו ספרים נוספים שאינם ברשימת הסדר: {', '.join(extra_books)}")
        for book in extra_books:
            ordered_books_dict[book] = collected_sefarim[book]

    # Construct the final data structure
    final_json_data = {
        "name": "רמב\"ם",
        "content_type": "פרק",
        "subcategories": [
            {
                "name": "משנה תורה",
                "content_type": "פרק",
                "books": ordered_books_dict
            }
        ]
    }

    # --- שלב 3: שמירה לקובץ ---
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(final_json_data, f, ensure_ascii=False, indent=2)

    print(f"\nהתהליך הושלם. המידע המאוחד והמסודר נשמר בקובץ: {output_file}")


if __name__ == "__main__":
    # --- הגדרות ---
    # הגדר את שם תיקיית הקלט שבה נמצאים כל קובצי ה-JSON של ספרי הרמב"ם
    input_directory = "משנה תורה"
    
    # הגדר את שם קובץ הפלט
    output_filename = "mishneh_torah_complete_ordered.json"

    # ודא שתיקיית הקלט קיימת
    if not os.path.isdir(input_directory):
        print(f"שגיאה: תיקיית הקלט '{input_directory}' לא נמצאה.")
        print("אנא צור את התיקיה והנח בתוכה את קובצי ה-JSON של הרמב\"ם.")
    else:
        create_mishneh_torah_json(input_directory, output_filename)