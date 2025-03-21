import functions_framework
from flask import Flask, jsonify, Request
import os
from google.cloud import aiplatform
import hmac
import hashlib

app = Flask(__name__)

CLASSIFIER_PROMPT = """You are a spam classifier, specialized in distinguishing normal announcements and conversation from monetary scams, cryptocurrency/NFT scams, illegal content and fraudulent schemes. Your task is to classify a message as spam or clear (not spam)."""

API_KEY = os.environ.get("API_KEY")
PROJECT_ID = os.environ.get("PROJECT_ID")
LOCATION = os.environ.get("LOCATION")
ENDPOINT_ID = "6279747412344963072"
PORT = int(os.environ.get("PORT", 8080))

def authenticate_request(request: Request) -> bool:
    """Authenticate the request using HMAC"""
    if not API_KEY:
        print("Warning: API_KEY not configured")
        return False
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("HMAC "):
        return False
    received_signature = auth_header.replace("HMAC ", "")
    request_body = request.get_data()
    expected_signature = hmac.new(API_KEY.encode("utf-8"), request_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(received_signature, expected_signature)

def predict_spam(text):
    """Make a prediction using the classifier model"""
    request_body = {
        "systemInstruction": {
            "role": "system",
            "parts": [{"text": CLASSIFIER_PROMPT}]
        },
        "contents": [
            {
                "role": "user",
                "parts": [{"text": text}]
            }
        ]
    }
    endpoint = aiplatform.Endpoint(f"projects/{PROJECT_ID}/locations/{LOCATION}/endpoints/{ENDPOINT_ID}")
    response = endpoint.predict(instances=[request_body])
    prediction = response.predictions[0]
    if isinstance(prediction, dict) and "contents" in prediction:
        for content in prediction["contents"]:
            if content.get("role") == "model" and content.get("parts"):
                for part in content["parts"]:
                    if "text" in part:
                        return part["text"].strip()
    return prediction

@functions_framework.http
def classify_text(request):
    """HTTP Cloud Function that classifies text as spam or clear"""
    if request.method != "POST":
        return jsonify({"error": "Method not allowed"}), 405
    if not authenticate_request(request):
        return jsonify({"error": "Unauthorized"}), 401
    try:
        request_json = request.get_json(silent=True)
        if not request_json or "text" not in request_json:
            return jsonify({"error": "Invalid request: missing 'text' field"}), 400
        text = request_json["text"]
    except Exception as e:
        return jsonify({"error": f"Invalid request: {str(e)}"}), 400
    try:
        aiplatform.init(project=PROJECT_ID, location=LOCATION)
    except Exception as e:
        return jsonify({"error": f"Failed to initialize Vertex AI: {str(e)}"}), 500
    try:
        result = predict_spam(text)
        return jsonify({"result": result}), 200
    except Exception as e:
        return jsonify({"error": f"Prediction failed: {str(e)}"}), 500
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT)