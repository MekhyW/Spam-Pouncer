import pandas as pd
import logging
import json
import random

logging.basicConfig(level=logging.INFO)

CLASSIFIER_PROMPT = """You are a spam classifier, specialized in distinguishing normal announcements and conversation from monetary scams, cryptocurrency/NFT scams, illegal content and fraudulent schemes. Your task is to classify a message as spam or clear (not spam)."""

def clean_dataframe(df):
    df = df[['text']]
    df = df[df['text'].notna()]
    df = df.dropna(axis=1, how='all')
    return df

def main(spam_path, clear_path, output_path):
    logging.info(f"Processing {spam_path} and {clear_path} to {output_path}")
    df_spam = clean_dataframe(pd.read_parquet(spam_path))
    df_clear = clean_dataframe(pd.read_parquet(clear_path))
    result = []
    for text in df_spam['text']:
        entry = {
            "systemInstruction": {"role": "system", "parts": [{"text": CLASSIFIER_PROMPT}]},
            "contents": [
                {"role": "user", "parts": [{"text": text}]},
                {"role": "model", "parts": [{"text": "spam"}]}
            ]
        }
        result.append(entry)
    for text in df_clear['text']:
        entry = {
            "systemInstruction": {"role": "system", "parts": [{"text": CLASSIFIER_PROMPT}]},
            "contents": [
                {"role": "user", "parts": [{"text": text}]},
                {"role": "model", "parts": [{"text": "clear"}]}
            ]
        }
        result.append(entry)
    random.shuffle(result)
    with open(output_path, 'w', encoding='utf-8') as f:
        for entry in result:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    logging.info(f"Created {len(result)} entries in {output_path}")

if __name__ == "__main__":
    main("data/spam.parquet", "data/clear.parquet", "data/dataset_formatted.jsonl")