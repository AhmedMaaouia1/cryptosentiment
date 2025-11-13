"""
config.py
---------
Centralisation de la configuration pour les DAGs CryptoSentiment.

Toutes les valeurs proviennent du fichier .env
(ou de Variables Airflow si .env n'est pas présent).
"""

from common_utils import env_var

# ==============================================================
# AWS Configuration
# ==============================================================

AWS_REGION = env_var("AWS_REGION", "eu-west-3")
S3_BUCKET = env_var("S3_BUCKET")
DDB_TABLE = env_var("DYNAMODB_TABLE")
SNS_TOPIC_ARN = env_var("SNS_TOPIC_ARN")

# ==============================================================
# APIs externes
# ==============================================================

NEWSAPI_KEY = env_var("NEWSAPI_KEY")
HF_API_TOKEN = env_var("HF_API_TOKEN")
HF_API_URL = env_var(
    "HF_API_URL",
    "https://api-inference.huggingface.co/models/cardiffnlp/twitter-roberta-base-sentiment",
)

# ==============================================================
# Paramètres applicatifs
# ==============================================================

COINGECKO_ASSETS = env_var("COINGECKO_ASSETS", "bitcoin,ethereum")

# ==============================================================
# Fonctions utilitaires
# ==============================================================

def show_config_summary():
    """Affiche un résumé (debug uniquement)"""
    print("=== CONFIG SUMMARY ===")
    print(f"AWS_REGION       = {AWS_REGION}")
    print(f"S3_BUCKET        = {S3_BUCKET}")
    print(f"DDB_TABLE        = {DDB_TABLE}")
    print(f"SNS_TOPIC_ARN    = {SNS_TOPIC_ARN}")
    print(f"HF_API_URL       = {HF_API_URL}")
    print(f"COINGECKO_ASSETS = {COINGECKO_ASSETS}")
