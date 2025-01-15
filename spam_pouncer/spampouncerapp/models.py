from django.db import models

class Account(models.Model):
    user_id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=255)
    trust_score = models.IntegerField()
    num_updates = models.IntegerField()

    def __str__(self):
        return f"Account(user_id={self.user_id}, trust_score={self.trust_score}, num_updates={self.num_updates})"
