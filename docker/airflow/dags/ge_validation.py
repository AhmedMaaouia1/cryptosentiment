import os
import json

def run_ge_checkpoint(checkpoint_name, data):
    """
    Exécute un checkpoint Great Expectations (version simplifiée maison).
    """
    dags_folder = os.environ.get("AIRFLOW__CORE__DAGS_FOLDER", "/opt/airflow/dags")

    checkpoint_path = os.path.join(
        dags_folder,
        "great_expectations",
        "checkpoints",
        f"{checkpoint_name}.json"
    )

    expectations_path = os.path.join(
        dags_folder,
        "great_expectations",
        "expectations",
        "prices_expectation.json"
    )

    # Charger checkpoint
    with open(checkpoint_path, "r") as f:
        checkpoint_cfg = json.load(f)

    # Charger expectations
    with open(expectations_path, "r") as f:
        expectation_cfg = json.load(f)

    # === Validation maison minimaliste ===
    for exp in expectation_cfg["expectations"]:
        col = exp["kwargs"]["column"]

        if exp["expectation_type"] == "expect_column_to_exist":
            if col not in data[0]:
                print(f"[GE] ❌ missing column: {col}")
                return False

        if exp["expectation_type"] == "expect_column_values_to_not_be_null":
            if data[0].get(col) is None:
                print(f"[GE] ❌ null value: {col}")
                return False

    print("[GE] ✅ Validation OK")
    return True
