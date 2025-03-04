import json
import random
import os
from dotenv import load_dotenv
load_dotenv()

SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT")
spam_text = []
clear_text = []

def process_message(data):
    for message in data['messages']:
        if message['type'] == 'message' and 'text' in message:
            if type(message['text']) == list:
                text = ''
                for submessage in message['text']:
                    text += submessage['text'] + ' ' if 'text' in submessage else submessage
                message['text'] = text
    return data

def prepare_data(spam, clear):
    spam_text = []
    clear_text = []
    for key, value in [(spam, "spam"), (clear, "clear")]:
        processed_messages = process_message(key)
        for message in processed_messages['messages']:
            if len(message['text']):
                spam_text.append({'messages': [{'role': 'system', 'content': SYSTEM_PROMPT}, 
                                           {'role': 'user', 'content': message['text'].strip()},
                                           {'role': 'model', 'content': value}]})
    return spam_text, clear_text

if __name__ == '__main__':
    with open('dataset/spam.json', encoding='utf-8') as f:
        data_spam = json.load(f)
    with open('dataset/clear.json', encoding='utf-8') as f:
        data_clear = json.load(f)
    spam_text, clear_text = prepare_data(data_spam, data_clear)
    with open('dataset/dataset.json', 'w', encoding='utf-8') as f:
        dataset = spam_text + clear_text
        random.shuffle(dataset)
        json.dump(dataset, f, ensure_ascii=False, indent=4)
    print("Dataset created successfully!")