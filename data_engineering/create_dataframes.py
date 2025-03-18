import pandas as pd
import json
import logging

logging.basicConfig(level=logging.INFO)

def concatenate_telegram_entities(entities):
    if isinstance(entities, str):
        return entities
    result = ""
    for entity in entities:
        if isinstance(entity, str):
            result += entity
        elif isinstance(entity, dict) and "text" in entity:
            result += entity["text"]
    return result

def json2df(json_file):
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    relevant_data = data['messages']
    df = pd.DataFrame(relevant_data)
    df['text'] = df['text'].apply(concatenate_telegram_entities)
    df['chat_id'] = data['id']
    df = df.drop(columns=['text_entities'])
    return df

def save_df(df, file_path):
    df = df.replace('', None)
    for col in df.columns:
        non_null_values = df[col].dropna()
        if len(non_null_values) > 0:
            numeric_values = pd.to_numeric(non_null_values, errors='coerce')
            if numeric_values.notna().sum() / len(non_null_values) > 0.5:
                df[col] = pd.to_numeric(df[col], errors='coerce')
    df.to_parquet(file_path, index=False)

def main(input_path, output_path):
    logging.info(f"Processing {input_path} to {output_path}")
    df = json2df(input_path)
    logging.info(f"Saving dataframe to {output_path}")
    save_df(df, output_path)

if __name__ == "__main__":
    main("data/spam.json", "data/spam.parquet")
    main("data/clear.json", "data/clear.parquet")