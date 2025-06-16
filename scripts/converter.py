import json

def convert_analysis_to_structure(source_file_path, target_file_path):
    """
    Converts a JSON file from the 'analysis' format to the 'structured' format.

    Args:
        source_file_path (str): The path to the input JSON file (e.g., 'משנה ברורה_analysis.json').
        target_file_path (str): The path to save the output JSON file.
    """
    try:
        # Step 1: Read the source JSON file with UTF-8 encoding
        with open(source_file_path, 'r', encoding='utf-8') as f:
            source_data = json.load(f)

        books_data = source_data.get("books_data", {})
        if not books_data:
            print("Warning: No 'books_data' found in the source file.")
            return

        # Determine the content type from the first book, default to 'פרק'
        first_book_info = next(iter(books_data.values()), {})
        content_type = first_book_info.get("division_type", "פרק")

        # Step 2: Build the basic structure of the target JSON
        target_data = {
            "name": source_data.get("collection_name", "N/A"),
            "content_type": content_type,
            "subcategories": [
                {
                    "name": "ספרים",  # Generic subcategory name
                    "content_type": content_type,
                    "books": {}
                }
            ]
        }

        # Step 3: Iterate through each book in the source data
        for book_name, book_info in books_data.items():
            # Create a single part for the book
            part = {
                "name": book_name,  # Use the book's name for the part name
                "start": 1,
                "end": book_info.get("last_identifier_gematria", 0)
            }

            # Add 'exclude' field only if 'missing_divisions' exists and is not empty
            missing_divisions = book_info.get("missing_divisions")
            if missing_divisions:
                part["exclude"] = missing_divisions

            # Add the book with its single part to the 'books' dictionary
            target_data["subcategories"][0]["books"][book_name] = {
                "parts": [part]
            }

        # Step 4: Write the new structure to the target file
        with open(target_file_path, 'w', encoding='utf-8') as f:
            # ensure_ascii=False for correct Hebrew output, indent for readability
            json.dump(target_data, f, ensure_ascii=False, indent=4)

        print(f"Successfully converted '{source_file_path}' to '{target_file_path}'")

    except FileNotFoundError:
        print(f"Error: The file '{source_file_path}' was not found.")
    except json.JSONDecodeError:
        print(f"Error: The file '{source_file_path}' is not a valid JSON file.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


# --- Usage Example ---

# Define the input and output file names
source_file = "משנה ברורה_analysis.json"
output_file = "mishna_berura_structured.json"

# Run the conversion
convert_analysis_to_structure(source_file, output_file)