from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Account
from .classifiers import dummy_classifier
from dotenv import load_dotenv
import os
import json

load_dotenv()

def index(request):
    return render(request, 'spampouncerapp/index.html')

def docs(request):
    return render(request, 'spampouncerapp/docs.html')

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
def set_user_score(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        token = data.get('token')
        if not check_token(token):
            return JsonResponse({'error': 'Invalid token'}, status=401)
        user_id = data.get('user_id')
        name = data.get('name')
        score = data.get('score')
        try:
            account = Account.objects.get(user_id=user_id)
            account.trust_score = score
            account.num_updates += 1
            account.save()
        except Account.DoesNotExist:
            Account.objects.create(user_id=user_id, name=name, trust_score=score, num_updates=1)
        return JsonResponse({'score': score})

@csrf_exempt
def classify_text(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        token = data.get('token')
        user_id = data.get('user_id')
        name = data.get('name')
        if not check_token(token):
            return JsonResponse({'error': 'Invalid token'}, status=401)
        text = data.get('text')
        score = dummy_classifier(text)
        if user_id:
            try:
                account = Account.objects.get(user_id=user_id)
                account.trust_score += score
                account.num_updates += 1
                account.save()
            except Account.DoesNotExist:
                Account.objects.create(user_id=user_id, name=name, trust_score=score, num_updates=1)
            except Exception as e:
                return JsonResponse({'error': str(e)}, status=500)
        return JsonResponse({'score': score})

