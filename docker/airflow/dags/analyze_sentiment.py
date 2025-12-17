"""
DAG : analyze_sentiment
-----------------------
Objectif :
  - Lire les dernières news brutes dans S3 (produites par fetch_news)
  - Appeler le modèle Hugging Face (twitter-roberta-base-sentiment)
  - Normaliser les scores et labels
  - Sauvegarder les résultats dans DynamoDB (clé : asset + ts)
"""

# ==============================================================
# Imports
# ==============================================================

from airflow import DAG
import decimal
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta, timezone
import json
import gzip
import hashlib
import requests
import backoff
from botocore.exceptions import ClientError

from common_utils import (
    utc_now,
    env_var,
    aws_clients,
    publish_sns,
)

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

MAX_NEWS_PER_RUN = int(env_var("MAX_NEWS_PER_RUN", "50"))

# ==============================================================
# Callbacks
# ==============================================================

def on_failure_callback(context):
    ti = context.get("ti")
    dag_id = context.get("dag").dag_id
    ex = context.get("exception")
    publish_sns(f"[{dag_id}] Task {ti.task_id} failed: {ex}")


# ==============================================================
# Helpers S3
# ==============================================================

def load_latest_news_batch():
    """
    Récupère le dernier fichier raw/news/... dans S3.
    """
    s3, _, _ = aws_clients()
    bucket = env_var("S3_BUCKET")

    prefix = "raw/news/"
    resp = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)

    contents = resp.get("Contents")
    if not contents:
        raise ValueError(f"Aucun objet trouvé sous s3://{bucket}/{prefix}")

    latest_obj = max(contents, key=lambda o: o["LastModified"])
    key = latest_obj["Key"]

    print(f"[S3] Dernier batch de news : s3://{bucket}/{key}")

    body = s3.get_object(Bucket=bucket, Key=key)["Body"].read()
    raw = gzip.decompress(body).decode("utf-8")
    data = json.loads(raw)

    print(f"[S3] {len(data)} news chargées depuis s3://{bucket}/{key}")
    return bucket, key, data


# ==============================================================
# Helpers Hugging Face
# ==============================================================

HF_DEFAULT_URL = "https://router.huggingface.co/hf-inference/models/cardiffnlp/twitter-roberta-base-sentiment"


def _map_hf_output_to_score(hf_output):
    if not hf_output:
        return 0.0, "neutral"

    preds = hf_output[0] if isinstance(hf_output[0], list) else hf_output

    neg = neu = pos = 0.0
    for p in preds:
        label = p.get("label", "").lower()
        score = float(p.get("score", 0))

        if "neg" in label:
            neg += score
        elif "pos" in label:
            pos += score
        elif "neu" in label:
            neu += score

    final_score = pos - neg

    if final_score > 0.2:
        return final_score, "positive"
    elif final_score < -0.2:
        return final_score, "negative"
    else:
        return final_score, "neutral"


@backoff.on_exception(backoff.expo, requests.exceptions.RequestException, max_time=60)
def hf_analyze_sentiment(text: str) -> dict:
    api_url = env_var("HF_API_URL", HF_DEFAULT_URL)
    token = env_var("HF_API_TOKEN")

    if not token:
        raise RuntimeError("HF_API_TOKEN manquant")

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    payload = {"inputs": text}
    r = requests.post(api_url, headers=headers, json=payload, timeout=30)

    if r.status_code == 429:
        raise requests.exceptions.RequestException("429 Too Many Requests")

    r.raise_for_status()
    result = r.json()

    score, label = _map_hf_output_to_score(result)

    return {
        "sentiment_score": score,
        "label": label,
        "raw": result,
    }


# ==============================================================
# Helpers DynamoDB
# ==============================================================

def make_ddb_keys(article: dict) -> tuple[str, str]:
    """
    Terraform a défini :

      hash_key  = "asset"
      range_key = "ts"

    Donc :
      asset = nom de la crypto extraite de l'article (fallback: 'unknown')
      ts    = timestamp publiéAt + hash(url)
    """

    # Extraire asset depuis la source (ex: title "Bitcoin jumps...")
    # -> version simple (améliorable plus tard)
    title = (article.get("title") or "").lower()
    asset = "unknown"
    for coin in ("bitcoin", "btc", "eth", "ethereum"):
        if coin in title:
            asset = coin
            break

    published_at = article.get("publishedAt") or utc_now().isoformat()
    date_hash = hashlib.sha1(article.get("url", "").encode()).hexdigest()[:8]

    ts = f"{published_at}#{date_hash}"

    return asset, ts


def upsert_sentiment_item(ddb, table_name: str, article: dict, sentiment: dict):
    """
    Correct version — uses HIGH-LEVEL boto3 resource API (native dicts)
    Compatible with Terraform table (asset + ts)
    """
    table = ddb.Table(table_name)

    pk, sk = make_ddb_keys(article)   # pk = asset, sk = ts
    now = utc_now().isoformat()

    # DynamoDB high-level format = simple Python dict
    item = {
        "asset": pk,          # <-- STRING, pas {"S": ...}
        "ts": sk,             # <-- STRING

        "url": article.get("url", ""),
        "source": article.get("source", ""),
        "title": article.get("title", ""),
        "publishedAt": article.get("publishedAt", ""),
        "fetched_at": article.get("fetched_at", ""),

        "sentiment_score": decimal.Decimal(str(sentiment["sentiment_score"])),
        "label": sentiment["label"],
        "model": "cardiffnlp/twitter-roberta-base-sentiment",
        "processed_at": now,
    }

    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(asset) AND attribute_not_exists(ts)"
        )
        print(f"[DDB] ✅ Insert {pk} / {sk}")

    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            print(f"[DDB]   Already exists {pk} / {sk} — skip")
        else:
            raise

# ==============================================================
# Tâche principale
# ==============================================================

def task_analyze_sentiment(**context):
    _, ddb, _ = aws_clients()
    table_name = env_var("DYNAMODB_TABLE")

    bucket, key, articles = load_latest_news_batch()

    count = 0
    for article in articles:
        if count >= MAX_NEWS_PER_RUN:
            break

        title = article.get("title", "")
        desc = article.get("description", "")

        text = f"{title}. {desc}".strip()
        if not text:
            continue

        print(f"[Sentiment] Analyse {count+1}/{len(articles)} : {article.get('url')}")

        sentiment = hf_analyze_sentiment(text)

        upsert_sentiment_item(ddb, table_name, article, sentiment)

        count += 1

    print(f"[Sentiment] Terminé — {count} articles traités.")


# ==============================================================
# DAG
# ==============================================================

with DAG(
    dag_id="analyze_sentiment",
    start_date=datetime(2025, 1, 1, tzinfo=timezone.utc),
    schedule_interval="0 * * * *",  # hourly
    catchup=False,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    tags=["cryptosentiment", "sentiment", "huggingface"],
) as dag:

    run = PythonOperator(
        task_id="analyze_sentiment_task",
        python_callable=task_analyze_sentiment,
        provide_context=True,
    )
