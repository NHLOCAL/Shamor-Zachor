import os
import json

def create_tanach_json(input_dir, output_file):
    """
    Scans a directory of Tanach analysis JSON files (one for each main part
    like Torah, Nevi'im, etc.), consolidates them into a single structured
    JSON file, and ensures the canonical order of all books.

    Args:
        input_dir (str): The path to the directory containing the source JSON files.
        output_file (str): The path where the final consolidated JSON will be saved.
    """
    # Define the canonical order of all parts and their books
    TANACH_ORDER = {
        "תורה": [
            "בראשית", "שמות", "ויקרא", "במדבר", "דברים"
        ],
        "נביאים": [
            "יהושע", "שופטים", "שמואל א", "שמואל ב", "מלכים א", "מלכים ב",
            "ישעיהו", "ירמיהו", "יחזקאל", "הושע", "יואל", "עמוס", "עובדיה", "יונה", "מיכה", "נחום", "חבקוק", "צפניה", "חגי", "זכריה", "מלאכי"
        ],
        "כתובים": [
            "תהילים", "משלי", "איוב", "שיר השירים", "רות", "איכה",
            "קהלת", "אסתר", "דניאל", "עזרא", "נחמיה", "דברי הימים א", "דברי הימים ב"
        ]
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

                category_name = data.get("collection_name") # e.g., "תורה"
                books_data = data.get("books_data")

                if not category_name or not books_data:
                    print(f"  [אזהרה] קובץ {filename} חסר מידע. מדלג.")
                    continue
                
                print(f"  מעבד את הקובץ עבור: {category_name}")
                
                collected_data[category_name] = {}
                for book_name, details in books_data.items():
                    chapter_count = details.get("count")
                    if chapter_count is not None:
                        # The key is already the clean book name
                        collected_data[category_name][book_name.strip()] = chapter_count
                    else:
                        print(f"    [אזהרה] לא נמצא 'count' עבור '{book_name}'.")

            except Exception as e:
                print(f"  [שגיאה] אירעה שגיאה בעיבוד הקובץ {filename}: {e}")

    # --- שלב 2: בניית מבנה ה-JSON הסופי לפי הסדר שהוגדר ---
    print("\nשלב 2: מרכיב את קובץ הפלט הסופי לפי הסדר המלא.")
    
    final_json_data = {
        "name": "תנ\"ך",
        "content_type": "פרק",
        "subcategories": []
    }

    # Iterate through the categories in the predefined order
    for category_name, books_in_order in TANACH_ORDER.items():
        if category_name not in collected_data:
            print(f"  [אזהרה] לא נמצא קובץ מתאים עבור '{category_name}'. מדלג על קטגוריה זו.")
            continue
        
        print(f"  מרכיב את '{category_name}'...")
        
        ordered_books_dict = {}
        # Iterate through the books for this category in the predefined order
        for book_name in books_in_order:
            if book_name in collected_data[category_name]:
                chapter_count = collected_data[category_name][book_name]
                ordered_books_dict[book_name] = {"pages": chapter_count}
            else:
                print(f"    [אזהרה] לא נמצא הספר '{book_name}' בנתונים של '{category_name}'.")

        category_subcategory = {
            "name": category_name,
            "content_type": "פרק",
            "books": ordered_books_dict
        }
        final_json_data["subcategories"].append(category_subcategory)

    # --- שלב 3: שמירה לקובץ ---
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(final_json_data, f, ensure_ascii=False, indent=2)

    print(f"\nהתהליך הושלם. המידע המאוחד והמסודר נשמר בקובץ: {output_file}")


if __name__ == "__main__":
    # --- הגדרות ---
    # הגדר את שם תיקיית הקלט שבה נמצאים קובצי ה-JSON של התנ"ך
    input_directory = "תנך"
    
    # הגדר את שם קובץ הפלט
    output_filename = "tanach_complete_ordered.json"

    # ודא שתיקיית הקלט קיימת
    if not os.path.isdir(input_directory):
        print(f"שגיאה: תיקיית הקלט '{input_directory}' לא נמצאה.")
        print("אנא צור את התיקיה והנח בתוכה את קובצי ה-JSON של התנ\"ך.")
    else:
        create_tanach_json(input_directory, output_filename)