from django.urls import path

from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("verify-token/", views.verify_token, name="verify_token"),
    path("get-user-score/", views.get_user_score, name="get_user_score"),
    path("classify-text/", views.classify_text, name="classify_text"),
]