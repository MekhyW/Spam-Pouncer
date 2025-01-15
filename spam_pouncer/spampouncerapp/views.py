from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Account
from dotenv import load_dotenv
import os
import json

load_dotenv()

def index(request):
    return render(request, 'spampouncerapp/index.html')

@csrf_exempt
def verify_token(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        token = data.get('token').strip()
        stored_token = os.getenv('TOKEN').strip()
        return JsonResponse({'valid': token == stored_token})

def check_token(token):
    stored_token = os.getenv('TOKEN')
    return token == stored_token

@csrf_exempt
def get_user_score(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        token = data.get('token')
        
        if not check_token(token):
            return JsonResponse({'error': 'Invalid token'}, status=401)
            
        user_id = data.get('user_id')
        try:
            account = Account.objects.get(user_id=user_id)
            return JsonResponse({
                'found': True,
                'trust_score': account.trust_score
            })
        except Account.DoesNotExist:
            return JsonResponse({
                'found': False,
                'message': 'User not found'
            })

@csrf_exempt
def classify_text(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        token = data.get('token')
        
        if not check_token(token):
            return JsonResponse({'error': 'Invalid token'}, status=401)
            
        text = data.get('text')
        # Dummy classifier that always returns 1
        return JsonResponse({'score': 1})

