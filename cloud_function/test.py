import requests
import json
import hmac
import hashlib

URL = ""
API_KEY = ""

text_to_classify = "Hello world!"

request_body = {"text": text_to_classify}
request_body_bytes = json.dumps(request_body).encode('utf-8')
signature = hmac.new(API_KEY.encode('utf-8'), request_body_bytes, hashlib.sha256).hexdigest()
headers = {"Content-Type": "application/json", "Authorization": f"HMAC {signature}"}

response = requests.post(URL, data=request_body_bytes, headers=headers)
print(response.json())