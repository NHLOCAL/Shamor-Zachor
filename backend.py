# backend.py (מאחורי הקלעים)
import json

def save_progress(masechta, daf, amud, value):
    try:
        with open("progress.json", "r") as f:
            progress = json.load(f)
    except FileNotFoundError:
        progress = {}

    if masechta not in progress:
        progress[masechta] = {}

    if str(daf) not in progress[masechta]:
        progress[masechta][str(daf)] = {}

    progress[masechta][str(daf)][amud] = value

    with open("progress.json", "w") as f:
        json.dump(progress, f, indent=4)
        
 
def save_all_masechta(masechta, pages_num, value):
    try:
        with open("progress.json", "r") as f:
            progress = json.load(f)
    except FileNotFoundError:
        progress = {}

    if masechta not in progress:
        progress[masechta] = {}


    if masechta in progress:
        for daf in range(1, pages_num + 1):

            if str(daf) not in progress[masechta]:
                progress[masechta][str(daf)] = {}        

            progress[masechta][str(daf)]['a'] = value
            progress[masechta][str(daf)]['b'] = value

    with open("progress.json", "w") as f:
        json.dump(progress, f, indent=4)



def load_progress(masechta):
    try:
        with open("progress.json", "r") as f:
            progress = json.load(f)
            return progress.get(masechta, {})  # returns an empty dictionary if the masechta is not in the progress file
    except FileNotFoundError:
        return {}
        
def load_shas_data(filename):
    try:
        with open(filename, "r", encoding="utf-8") as f:  # encoding for Hebrew
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        return None
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in '{filename}'.")
        return None