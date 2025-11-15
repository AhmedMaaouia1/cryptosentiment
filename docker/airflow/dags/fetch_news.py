"""
DAG : fetch_news
----------------
Objectif :
  - Extraire les actualités crypto via NewsAPI
  - Valider les données avec Great Expectations
  - Stocker dans S3 (gzip JSON)
  - Alerter via SNS en cas d’erreur

Auteur : Ahmed Maaouia
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta, timezone
import requests
import backoff
import json

# Utils internes
from common_utils import (
    utc_now,
    env_var,
    aws_clients,
    write_json_gz_to_s3,
    s3_key_exists,
    publish_sns,
)
from ge_validation import run_ge_checkpoint


# ==============================================================
# Configuration du DAG
# ==============================================================

DEFAULT_ARGS = {
    "owner": "cryptosentiment",
    "depends_on_past": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
    "retry_exponential_backoff": True,
}

def on_failure_callback(context):
    ti = context.get("ti")
    dag_id = context["dag"].dag_id
    ex = context.get("exception")
    publish_sns(f"[{dag_id}] Task {ti.task_id} failed: {ex}")


# ==============================================================
# Path S3 partitionné
# ==============================================================

def s3_path(ts):
    bucket = env_var("S3_BUCKET")
    dt = ts.strftime("%Y-%m-%d")
    hm = ts.strftime("%H%M")
    key = f"raw/news/dt={dt}/{hm}.json.gz"
    return bucket, key


# ==============================================================
# Appel API NewsAPI avec Retry exponentiel
# ==============================================================

@backoff.on_exception(backoff.expo, requests.exceptions.RequestException, max_time=60)
def fetch_news():
    url = "https://newsapi.org/v2/everything"

    params = {
        "q": "crypto OR bitcoin OR ethereum",
        "language": "en",
        "sortBy": "publishedAt",
        "apiKey": env_var("NEWSAPI_KEY"),
        "pageSize": 50,         # Free Tier max
    }

    r = requests.get(url, params=params, timeout=20)
    if r.status_code == 429:
        raise requests.exceptions.RequestException("429 Too Many Requests")

    r.raise_for_status()

    articles = r.json().get("articles", [])
    normalized = []

    for a in articles:
        normalized.append({
            "title": a.get("title"),
            "description": a.get("description"),
            "url": a.get("url"),
            "source": a.get("source", {}).get("name"),
            "publishedAt": a.get("publishedAt"),
            "fetched_at": utc_now().isoformat(),
        })

    return normalized


# ==============================================================
# Logic principal
# ==============================================================

def task_fetch_news(**_):
    s3, _, _ = aws_clients()
    ts = utc_now()

    # 1) Appel API
    data = fetch_news()

    if not data:
        raise ValueError("NewsAPI returned no data")

    # 2) Validation GE
    result = run_ge_checkpoint("news_checkpoint", data)
    if not result["success"]:
        raise ValueError(f"GE validation failed for news (score={result['score']})")

    # 3) S3 path
    bucket, key = s3_path(ts)

    # Idempotence : ne pas double charger
    if s3_key_exists(s3, bucket, key):
        print(f"⏭️  File already exists : s3://{bucket}/{key}")
        return

    # 4) Save gzip JSON
    write_json_gz_to_s3(s3, bucket, key, data)
    print(f"✅ News saved → s3://{bucket}/{key}")


# ==============================================================
# Définition du DAG
# ==============================================================

with DAG(
    dag_id="fetch_news",
    start_date=datetime(2025, 1, 1, tzinfo=timezone.utc),
    schedule_interval="0 * * * *",   # every hour
    catchup=False,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    tags=["cryptosentiment", "news", "ingestion"],
    description="Extraction des actualités crypto via NewsAPI → S3",
) as dag:

    run = PythonOperator(
        task_id="fetch_news_task",
        python_callable=task_fetch_news,
    )
