"""
DAG : fetch_prices
------------------
Objectif :
  - Extraire les prix crypto depuis CoinGecko (API publique)
  - Valider les données avec Great Expectations
  - Stocker les fichiers JSON compressés sur S3
  - Déclencher une alerte SNS en cas d’échec

Auteur : Ahmed Maaouia
"""

# ==============================================================
# Importations
# ==============================================================

from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta, timezone
import requests
import backoff

from common_utils import (
    utc_now,
    aws_clients,
    s3_key_exists,
    write_json_gz_to_s3,
    publish_sns,
)
from ge_validation import run_ge_checkpoint
from config import S3_BUCKET, COINGECKO_ASSETS

# ==============================================================
# Paramètres Airflow
# ==============================================================

DEFAULT_ARGS = {
    "owner": "cryptosentiment",
    "depends_on_past": False,
    "retries": 3,
    "retry_delay": timedelta(minutes=2),
    "retry_exponential_backoff": True,
}

def on_failure_callback(context):
    """En cas d’échec d’une tâche, envoie une alerte SNS."""
    ti = context.get("ti")
    dag_id = context.get("dag").dag_id
    ex = context.get("exception")
    publish_sns(f"[{dag_id}] Task {ti.task_id} failed: {ex}")

# ==============================================================
# Fonctions métiers
# ==============================================================

def s3_path(symbol, ts):
    dt = ts.strftime("%Y-%m-%d")
    hm = ts.strftime("%H%M")
    key = f"raw/prices/asset={symbol}/dt={dt}/{hm}.json.gz"
    return S3_BUCKET, key

@backoff.on_exception(backoff.expo, requests.exceptions.RequestException, max_time=60)
def fetch_cg_price(symbol):
    url = "https://api.coingecko.com/api/v3/simple/price"
    params = {"ids": symbol, "vs_currencies": "usd"}
    r = requests.get(url, params=params, timeout=20)
    if r.status_code == 429:
        raise requests.exceptions.RequestException("429 Too Many Requests")
    r.raise_for_status()
    data = r.json()
    return {
        "asset": symbol,
        "price_usd": data.get(symbol, {}).get("usd"),
        "fetched_at": utc_now().isoformat(),
    }

def task_fetch_prices(**_):
    """Extrait les prix depuis CoinGecko et les sauvegarde sur S3."""
    s3, _, _ = aws_clients()
    symbols = [s.strip() for s in COINGECKO_ASSETS.split(",")]
    ts = utc_now()

    for symbol in symbols:
        payload = fetch_cg_price(symbol)

        # Validation GE
        result = run_ge_checkpoint("prices_checkpoint", [payload])
        if not result["success"]:
            raise ValueError(f"GE validation failed for {symbol} (score={result['score']})")

        bucket, key = s3_path(symbol, ts)
        if s3_key_exists(s3, bucket, key):
            print(f"⏭️  Fichier déjà présent : s3://{bucket}/{key}")
            continue

        write_json_gz_to_s3(s3, bucket, key, payload)
        print(f"✅ Prix {symbol} sauvegardé dans s3://{bucket}/{key}")

# ==============================================================
# DAG Definition
# ==============================================================

with DAG(
    dag_id="fetch_prices",
    start_date=datetime(2025, 1, 1, tzinfo=timezone.utc),
    schedule_interval="*/30 * * * *",
    catchup=False,
    default_args=DEFAULT_ARGS,
    on_failure_callback=on_failure_callback,
    tags=["cryptosentiment", "ingestion", "coingecko"],
    description="Extraction des prix crypto depuis CoinGecko vers S3",
) as dag:

    run = PythonOperator(
        task_id="fetch_prices_task",
        python_callable=task_fetch_prices,
        provide_context=True,
    )
