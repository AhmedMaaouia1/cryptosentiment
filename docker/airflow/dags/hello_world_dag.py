from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime

def say_hello():
    print("Airflow is working!")

with DAG(
    dag_id="hello_world",
    start_date=datetime(2025, 1, 1),
    schedule=None,
    catchup=False
) as dag:
    PythonOperator(
        task_id="hello",
        python_callable=say_hello
    )
