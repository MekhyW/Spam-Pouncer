# Generated by Django 5.1.4 on 2025-01-15 20:07

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Account',
            fields=[
                ('user_id', models.IntegerField(primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255)),
                ('trust_score', models.IntegerField()),
                ('num_updates', models.IntegerField()),
            ],
        ),
    ]
