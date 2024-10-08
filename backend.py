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
            return progress.get(masechta, {})
    except FileNotFoundError:
        return {}


def load_shas_data(filename):
    try:
        with open(filename, "r", encoding="utf-8") as f:
            data = json.load(f)
            # Validate data structure if necessary
            if not isinstance(data, dict):
                raise ValueError("Invalid shas data format. Expected a dictionary.")
            for masechta_data in data.values():
                if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                    raise ValueError("Invalid masechta data format. 'pages' key missing or not an integer.")
            return data
    except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
        print(f"Error loading shas data: {e}")
        return None