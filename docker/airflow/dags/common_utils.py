"""
common_utils.py
----------------
Utilitaires partagés pour les DAGs CryptoSentiment :
- Fonctions AWS (S3, SNS, DynamoDB)
- Gestion des variables et connexions Airflow
- Aide pour l’écriture/lecture S3
- Horodatage UTC
"""

import os
import json
import io
import gzip
from datetime import datetime, timezone

import boto3
import botocore
from airflow.models import Variable
from airflow.hooks.base import BaseHook
from botocore.exceptions import ClientError




# ==============================================================
# 1️⃣ Fonctions générales
# ==============================================================

def utc_now():
    """Retourne la date/heure actuelle en UTC."""
    return datetime.now(timezone.utc)


def env_var(name, default=None):
    """
    Récupère une variable d'environnement (Docker)
    ou une Variable Airflow si non trouvée.
    """
    return os.getenv(name, default) or Variable.get(name, default_var=default)


# ==============================================================
# 2️⃣ Fonctions AWS (boto3 clients)
# ==============================================================

def aws_clients():
    """
    Retourne un tuple (s3_client, ddb_resource, sns_client)
    configurés avec la région AWS définie dans .env ou Airflow Variables.
    """
    region = env_var("AWS_REGION", "eu-west-3")
    s3 = boto3.client("s3", region_name=region)
    ddb = boto3.resource("dynamodb", region_name=region)
    sns = boto3.client("sns", region_name=region)
    return s3, ddb, sns



# ==============================================================
# 3️⃣ Fonctions S3
# ==============================================================

def s3_key_exists(s3, bucket, key):
    """
    Vérifie si un objet existe dans S3 (idempotence).
    Retourne True si trouvé, False sinon.
    """
    try:
        s3.head_object(Bucket=bucket, Key=key)
        return True
    except ClientError as e:
        if e.response["Error"]["Code"] in ("404", "NotFound"):
            return False
        raise


def write_json_gz_to_s3(s3, bucket, key, data):
    """
    Écrit un objet JSON compressé (gzip) dans S3.
    - data : dict ou list
    - bucket : nom du bucket
    - key : chemin S3 complet
    """
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode="wb") as gz:
        gz.write(json.dumps(data, ensure_ascii=False, default=str).encode("utf-8"))

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=buf.getvalue(),
        ContentEncoding="gzip",
        ContentType="application/json"
    )


# ==============================================================
# 4️⃣ Connexions et alerting
# ==============================================================

def get_conn_password(conn_id):
    """
    Récupère le champ 'password' d'une connexion Airflow (utile pour API keys).
    """
    conn = BaseHook.get_connection(conn_id)
    return conn.password


def publish_sns(message, subject="CryptoSentiment Alert"):
    """
    Envoie un message SNS à partir du topic défini dans la variable :
    - SNS_TOPIC_ARN
    """
    _, _, sns = aws_clients()
    topic_arn = env_var("SNS_TOPIC_ARN")
    sns.publish(TopicArn=topic_arn, Subject=subject, Message=message)
    print(f"📢 SNS alert sent: {subject} -> {topic_arn}")
