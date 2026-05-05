import json
import os
import requests
import time
import math
import re

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
TEXT_FILE_PATH = 'C:/the ai/outo platfrom/psychology/thebook.txt'
OUTPUT_FILE_PATH = 'C:/the ai/outo platfrom/psychology/campaign_data.json'
MODEL_NAME = 'gemini-3.1-flash-lite-preview'
TOTAL_LEVELS = 200
QUESTIONS_PER_LEVEL = 20

api_keys_env = os.environ.get("GEMINI_API_KEYS", "")
API_KEYS = [k.strip() for k in api_keys_env.split(",") if k.strip()]
if not API_KEYS:
    raise ValueError("GEMINI_API_KEYS environment variable is not set or empty")

# Track API key usage
key_usage_counts = {key: 0 for key in API_KEYS}
REQUEST_LIMIT_PER_KEY = 450 # Stay slightly below 500 to be safe

def get_next_available_key():
    for key in API_KEYS:
        if key_usage_counts[key] < REQUEST_LIMIT_PER_KEY:
            key_usage_counts[key] += 1
            return key
    raise Exception("All API keys have exhausted their 500 request limits.")

# ---------------------------------------------------------
# TEXT PREPARATION
# ---------------------------------------------------------
def load_and_chunk_text(filepath, num_chunks):
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    
    # Split into paragraphs to respect natural boundaries if possible
    paragraphs = [p for p in text.split('\n') if len(p.strip()) > 10]
    
    total_length = len(text)
    chunk_size = math.ceil(total_length / num_chunks)
    
    chunks = []
    current_chunk = ""
    
    # Simple character-based splitting to ensure exactly 200 chunks evenly distributed.
    # We will slice roughly by chunk_size, finding the nearest period or newline.
    start = 0
    for i in range(num_chunks):
        if i == num_chunks - 1:
            chunks.append(text[start:]) # Take the rest
            break
            
        end_idx = min(start + chunk_size, total_length)
        
        # Try to find a good breaking point
        next_break = text.find('\n', end_idx)
        if next_break != -1 and next_break - end_idx < 1000:
            end_idx = next_break + 1
            
        chunks.append(text[start:end_idx].strip())
        start = end_idx

    print(f"Divided text into {len(chunks)} chunks.")
    return chunks

# ---------------------------------------------------------
# API CALL
# ---------------------------------------------------------
def invoke_gemini(chunk_text, level_num):
    api_key = get_next_available_key()
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL_NAME}:generateContent?key={api_key}"
    
    system_instruction = (
        "You are an expert Arabic Psychology professor crafting a university-level multiple-choice exam. "
        "Your task is to generate EXACTLY 20 questions based on the provided text. "
        "If the text is too short, infer and extrapolate general psychology concepts related to the given text to ensure there are exactly 20 questions. "
        "OUTPUT STRICTLY AS JSON without any markdown formatting, backticks, or additional text. "
        "The response MUST conform exactly to the following structure:\n"
        "{\n"
        '  "level_title": "A short, engaging Arabic title representing this section (e.g. الفصل 5: مبادئ الإدراك)",\n'
        '  "questions": [\n'
        "    {\n"
        '      "question_text": "The arabic question text here?",\n'
        '      "options": [\n'
        '        {"option_text": "Correct Answer", "is_correct": 1},\n'
        '        {"option_text": "Wrong Answer 1", "is_correct": 0},\n'
        '        {"option_text": "Wrong Answer 2", "is_correct": 0},\n'
        '        {"option_text": "Wrong Answer 3", "is_correct": 0}\n'
        "      ]\n"
        "    }\n"
        "  ]\n"
        "}"
    )

    payload = {
        "contents": [
            {
                "parts": [
                    {"text": system_instruction + "\n\nSource Text:\n" + chunk_text[:8000]} # Limit source text size to avoid token overflow
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "responseMimeType": "application/json"
        }
    }
    
    headers = {'Content-Type': 'application/json'}
    
    try:
        response = requests.post(url, json=payload, headers=headers)
        if response.status_code == 200:
            data = response.json()
            raw_text = data['candidates'][0]['content']['parts'][0]['text']
            # Clean possible markdown wrap
            raw_text = re.sub(r'^```json\s*', '', raw_text)
            raw_text = re.sub(r'\s*```$', '', raw_text)
            
            parsed_json = json.loads(raw_text)
            if 'questions' in parsed_json and len(parsed_json['questions']) > 0:
                parsed_json['level_order'] = level_num
                return parsed_json
            else:
                return None
        elif response.status_code == 429:
            print(f"Rate limited on key {api_key[:10]}... Wait and retry.")
            time.sleep(5)
            # Rollback key usage count so we shift to next
            key_usage_counts[api_key] = 9999
            return invoke_gemini(chunk_text, level_num)
        else:
            print(f"Error {response.status_code}: {response.text}")
            return None
    except Exception as e:
        print(f"Exception during API call: {e}")
        return None

# ---------------------------------------------------------
# MAIN EXECUTION
# ---------------------------------------------------------
def generate_campaign():
    if os.path.exists(OUTPUT_FILE_PATH):
        with open(OUTPUT_FILE_PATH, 'r', encoding='utf-8') as f:
            try:
                campaign_data = json.load(f)
            except:
                campaign_data = []
    else:
        campaign_data = []

    start_idx = len(campaign_data)
    print(f"Resuming from Level {start_idx + 1}")

    if start_idx >= TOTAL_LEVELS:
        print("Campaign generation is already complete!")
        return

    chunks = load_and_chunk_text(TEXT_FILE_PATH, TOTAL_LEVELS)

    for i in range(start_idx, TOTAL_LEVELS):
        print(f"Generating Level {i+1} / {TOTAL_LEVELS}...")
        
        chunk = chunks[i]
        result = None
        attempts = 0
        
        while result is None and attempts < 3:
            result = invoke_gemini(chunk, i + 1)
            if result is None:
                attempts += 1
                print(f"Retrying Level {i+1} (Attempt {attempts}/3)...")
                time.sleep(2)
        
        if result is None:
            print(f"CRITICAL FAILURE: Could not generate data for Level {i+1} after 3 attempts. Stopping to prevent data corruption.")
            break
            
        campaign_data.append(result)
        
        # Save incrementally
        with open(OUTPUT_FILE_PATH, 'w', encoding='utf-8') as f:
            json.dump(campaign_data, f, ensure_ascii=False, indent=2)
            
        print(f"Level {i+1} Saved successfully!")
        
        # Polite delay to prevent API 429 bursts
        time.sleep(2)

    print("Generation cycle completed.")

if __name__ == "__main__":
    generate_campaign()
