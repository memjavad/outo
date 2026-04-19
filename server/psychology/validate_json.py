import json
import os

FILE_PATH = "campaign_data.json"

def validate_campaign():
    if not os.path.exists(FILE_PATH):
        print(f"Error: {FILE_PATH} does not exist. Did the generation script finish?")
        return

    print("Loading JSON payload data...")
    try:
        with open(FILE_PATH, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"CRITICAL ERROR: JSON is malformed and cannot be parsed. Error: {e}")
        return
    except Exception as e:
        print(f"CRITICAL ERROR: Could not read file. Error: {e}")
        return

    print(f"JSON parsed safely. Validating Schema...\n")
    
    total_levels = len(data)
    total_questions = 0
    total_options = 0
    errors = []

    for idx, level in enumerate(data):
        level_order = level.get("level_order", idx + 1)
        questions = level.get("questions", [])
        
        if not questions:
            errors.append(f"Level {level_order} has NO questions generated.")
            continue
            
        for q_idx, q in enumerate(questions):
            total_questions += 1
            if "question_text" not in q or not q["question_text"]:
                errors.append(f"Level {level_order}, Question {q_idx+1} is missing 'question_text'.")
            
            options = q.get("options", [])
            if len(options) != 4:
                errors.append(f"Level {level_order}, Question {q_idx+1} has {len(options)} options instead of 4.")
            
            correct_count = 0
            for opt in options:
                total_options += 1
                if "option_text" not in opt or not opt["option_text"]:
                    errors.append(f"Level {level_order}, Question {q_idx+1} has a blank option.")
                if str(opt.get("is_correct", "0")) == "1":
                    correct_count += 1
            
            if correct_count != 1:
                errors.append(f"Level {level_order}, Question {q_idx+1} has {correct_count} correct options (should be exactly 1).")

    print(f"--- VALIDATION REPORT ---")
    print(f"Total Levels Detected: {total_levels}")
    print(f"Total Questions Detected: {total_questions}")
    print(f"Total Options Detected: {total_options}")
    
    if errors:
        print(f"\n[!] WARNING: Found {len(errors)} structural errors:")
        for e in errors[:20]: # Show first 20 errors to prevent console flood
            print(f" - {e}")
        if len(errors) > 20:
            print(f" ... and {len(errors) - 20} more errors.")
    else:
        print(f"\n[+] SUCCESS: The JSON file is 100% structurally sound, perfectly formatted, and ready for Database Seeding!")

if __name__ == "__main__":
    validate_campaign()
