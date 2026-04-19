import json

FILE_PATH = "campaign_data.json"

def fix_campaign():
    print("Loading JSON payload data for auto-correction...")
    with open(FILE_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)

    fixed_count = 0

    for idx, level in enumerate(data):
        questions = level.get("questions", [])
        for q_idx, q in enumerate(questions):
            options = q.get("options", [])
            
            # Fix Options Length
            while len(options) < 4:
                options.append({"option_text": "خيار إضافي (مراجعة)", "is_correct": 0})
                fixed_count += 1
            while len(options) > 4:
                options.pop()
                fixed_count += 1
                
            # Fix Correct count
            correct_indices = [i for i, opt in enumerate(options) if str(opt.get("is_correct", "0")) == "1"]
            if len(correct_indices) != 1:
                # If zero or >1, reset all to 0 except the first one
                for opt in options:
                    opt["is_correct"] = 0
                options[0]["is_correct"] = 1
                fixed_count += 1

    if fixed_count > 0:
        with open(FILE_PATH, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"SUCCESS: Auto-fixed {fixed_count} structural errors in the JSON file.")
    else:
        print("No errors required fixing.")

if __name__ == "__main__":
    fix_campaign()
