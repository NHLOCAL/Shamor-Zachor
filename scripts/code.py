import json
import os
from datasets import Dataset, Features, Value, Sequence

# רשימת קבצי ה-JSON לעיבוד
JSON_FILES = [
    'tanach.json',
    'mishna.json',
    'shas.json',
    'yerushalmi.json',
    'rambam.json',
    'halakha.json'
]

def process_data_structure(data):
    """
    Processes any of the given JSON structures and converts them to a list of records.
    Each record represents a 'block' of content (a book, a part of a book, etc.),
    preserving all original metadata like counts, ranges, and exclusions.
    """
    records = []
    category_name = data.get('name')

    for subcat_obj in data.get('subcategories', []):
        subcat_name = subcat_obj.get('name')
        subcat_unit_type = subcat_obj.get('content_type')

        for book_name, book_info in subcat_obj.get('books', {}).items():
            
            # Case 1: Complex structure with 'parts' (Rambam, Mishnah Berurah)
            if 'parts' in book_info:
                for part_info in book_info.get('parts', []):
                    record = {
                        'category': category_name,
                        'subcategory': subcat_name,
                        'book': book_name,
                        'part_name': part_info.get('name'),
                        'unit_type': subcat_unit_type,
                        'total_units': None,
                        'start_unit': part_info.get('start'),
                        'end_unit': part_info.get('end'),
                        'excluded_units': part_info.get('exclude', []),
                        'notes': None
                    }
                    records.append(record)
            
            # Case 2: Simple structure with 'pages' and optional 'exclude' (Tur, Shulchan Aruch, etc.)
            elif 'pages' in book_info:
                pages_val = book_info['pages']
                notes = None
                
                # Handle Talmud's half-pages
                if isinstance(pages_val, float):
                    total_units = int(pages_val)
                    notes = f"Contains {pages_val} daf in total (ends on Amud Aleph)."
                else:
                    total_units = pages_val

                record = {
                    'category': category_name,
                    'subcategory': subcat_name,
                    'book': book_name,
                    'part_name': None,
                    'unit_type': subcat_unit_type,
                    'total_units': total_units,
                    'start_unit': None,
                    'end_unit': None,
                    'excluded_units': book_info.get('exclude', []),
                    'notes': notes
                }
                records.append(record)

    return records

def main():
    """
    Main function to process all JSON files and create a Hugging Face Dataset.
    """
    all_records = []
    
    print("Starting dataset creation with new structure (preserving all metadata)...")
    
    for filename in JSON_FILES:
        if not os.path.exists(filename):
            print(f"Warning: File '{filename}' not found. Skipping.")
            continue
            
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"Processing {filename}...")
        records = process_data_structure(data)
        all_records.extend(records)
        print(f"-> Added {len(records)} records (blocks of content).")

    # Define the schema for the dataset
    features = Features({
        'category': Value('string'),
        'subcategory': Value('string'),
        'book': Value('string'),
        'part_name': Value('string'), # For Rambam hilkhot, MB chelek, etc.
        'unit_type': Value('string'),
        'total_units': Value('int64'),
        'start_unit': Value('int64'),
        'end_unit': Value('int64'),
        'excluded_units': Sequence(Value('int64')),
        'notes': Value('string'),
    })

    # Create the Hugging Face Dataset from the list of dictionaries
    hf_dataset = Dataset.from_list(all_records, features=features)
    
    print("\n--- Dataset creation complete ---")
    print(f"Total records in dataset: {len(hf_dataset)}")
    print("Dataset features (new schema):")
    print(hf_dataset.features)
    
    print("\n--- Sample records demonstrating preserved metadata ---")
    
    print("\n1. Tanach (simple structure):")
    print(next(r for r in hf_dataset if r['book'] == 'שמות'))
    
    print("\n2. Shas (with float pages):")
    print(next(r for r in hf_dataset if r['book'] == 'ברכות' and r['category'] == 'תלמוד בבלי'))

    print("\n3. Tur (with 'exclude' list):")
    print(next(r for r in hf_dataset if r['book'] == 'טור יורה דעה'))

    print("\n4. Rambam (with 'parts' structure):")
    print(next(r for r in hf_dataset if r['book'] == 'ספר המדע' and r['part_name'] == 'הלכות דעות'))
    
    print("\n5. Mishnah Berurah (with 'parts' and 'exclude'):")
    print(next(r for r in hf_dataset if r['book'] == 'ביאור הלכה' and r['part_name'] == "חלק ו'"))

    # To save the dataset locally
    hf_dataset.save_to_disk("./jewish_texts_metadata_dataset")
    print("\nDataset saved locally to './jewish_texts_metadata_dataset'")

    # --- How to push to Hub ---
    # 1. Login to your Hugging Face account in the terminal:
    #    huggingface-cli login
    #
    # 2. Uncomment the following line and replace with your repo name:
    # hf_dataset.push_to_hub("NHLOCAL/jewish-texts-structure")
    #
    # print("\nTo push to hub, uncomment the relevant line in the script.")

if __name__ == "__main__":
    main()