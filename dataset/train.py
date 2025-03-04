import vertexai
from vertexai.generative_models import GenerativeModel
from vertexai.preview.tuning import sft
import os
from dotenv import load_dotenv
load_dotenv()

vertexai.init(project=os.getenv('GCP_PROJECT'), location=os.getenv('GCP_LOCATION'))

gemini_pro = GenerativeModel("gemini-1.0-pro-002")

if __name__ == "__main__":
    sft_tuning_job = sft.train(
        source_model=gemini_pro,
        train_dataset="gs://cloud-samples-data/vertex-ai/model-evaluation/gemini_pro_peft_train_sample.jsonl",
        validation_dataset="gs://cloud-samples-data/vertex-ai/model-evaluation/gemini_pro_peft_eval_sample.jsonl",
        tuned_model_display_name="test2",
        epochs=4,
        learning_rate_multiplier=1,
    )
    print("Tuning job started. Check the status on the Vertex AI console.")