FROM apache/airflow:2.9.0

# On reste en user 'airflow' pour installer les libs Python
USER airflow

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir -r /requirements.txt
