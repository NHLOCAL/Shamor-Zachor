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


def load_data():
    def load_json_file(filename):
        try:
            with open(filename, "r", encoding="utf-8") as f:
                data = json.load(f)
                if not isinstance(data, dict):
                    raise ValueError(f"Invalid data format in {filename}. Expected a dictionary.")
                for masechta_data in data.values():
                    if "pages" not in masechta_data or not isinstance(masechta_data["pages"], int):
                        raise ValueError(f"Invalid masechta data format in {filename}. 'pages' key missing or not an integer.")
                return data
        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
            print(f"Error loading {filename}: {e}")
            return {}

    # Load data from different sources
    shas_data = load_json_file("data/shas.json")
    tanach_data = load_json_file("data/tanach.json")
    rambam_data = load_json_file("data/rambam.json")
    shulchan_aruch_data = load_json_file("data/shulchan_aruch.json")

    # Combine all data into a single dictionary
    combined_data = {
        "תלמוד בבלי": shas_data,
        "תנ״ך": tanach_data,
        "רמב״ם": rambam_data,
        "שולחן ערוך": shulchan_aruch_data
    }

    return combined_data
