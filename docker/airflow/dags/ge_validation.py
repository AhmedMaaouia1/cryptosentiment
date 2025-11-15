import os
import json
import re
from datetime import datetime, timezone

def parse_iso(date_str):
    """
    Parse une date ISO 8601, retourne un datetime ou None.
    """
    if not date_str:
        return None
    try:
        return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except Exception:
        return None


def run_ge_checkpoint(checkpoint_name, data):
    """
    Exécute un checkpoint Great Expectations simplifié avec :
      - severité: error / warning
      - scoring qualité (0-100)
      - logs détaillés

    Retourne un dict :
    {
      "success": bool,           # True si aucune erreur bloquante
      "score": float,            # 0-100
      "total_checks": int,
      "failed_errors": int,
      "failed_warnings": int,
      "errors": [...],
      "warnings": [...]
    }
    """

    dags_folder = os.environ.get("AIRFLOW__CORE__DAGS_FOLDER", "/opt/airflow/dags")

    # 1) Charger le checkpoint
    checkpoint_path = os.path.join(
        dags_folder,
        "great_expectations",
        "checkpoints",
        f"{checkpoint_name}.json",
    )
    with open(checkpoint_path, "r") as f:
        checkpoint_cfg = json.load(f)

    suite_name = checkpoint_cfg["validations"][0]["expectation_suite_name"]

    # 2) Charger la suite d'expectations
    expectations_path = os.path.join(
        dags_folder,
        "great_expectations",
        "expectations",
        f"{suite_name}.json",
    )
    with open(expectations_path, "r") as f:
        expectation_cfg = json.load(f)

    expectations = expectation_cfg.get("expectations", [])

    if not data:
        msg = "[GE] ❌ No data provided"
        print(msg)
        return {
            "success": False,
            "score": 0.0,
            "total_checks": 0,
            "failed_errors": 1,
            "failed_warnings": 0,
            "errors": [msg],
            "warnings": [],
        }

    total_checks = 0
    failed_errors = 0
    failed_warnings = 0
    error_details = []
    warning_details = []

    urls_seen = set()

    # 3) Boucle sur chaque ligne
    for idx, row in enumerate(data):
        for exp in expectations:
            etype = exp["expectation_type"]
            kwargs = exp.get("kwargs", {})
            severity = exp.get("severity", "error")  # défaut = error

            def fail(msg):
                nonlocal failed_errors, failed_warnings
                detail = f"{severity.upper()} [{etype}] row={idx} :: {msg}"
                if severity == "error":
                    failed_errors += 1
                    error_details.append(detail)
                else:
                    failed_warnings += 1
                    warning_details.append(detail)

            # Chaque expectation = un check
            total_checks += 1

            # ------------- règles colonne / valeur -------------

            if etype == "expect_column_to_exist":
                col = kwargs["column"]
                if col not in row:
                    fail(f"missing column '{col}'")
                continue

            if etype == "expect_column_values_to_not_be_null":
                col = kwargs["column"]
                v = row.get(col)
                if v is None or v == "":
                    fail(f"null or empty value in '{col}'")
                continue

            if etype == "expect_column_value_lengths_to_be_between":
                col = kwargs["column"]
                v = row.get(col, "")
                if not isinstance(v, str):
                    fail(f"'{col}' is not a string")
                    continue

                min_v = kwargs.get("min_value")
                max_v = kwargs.get("max_value")

                if min_v is not None and len(v) < min_v:
                    fail(f"'{col}' too short (len={len(v)} < {min_v})")
                if max_v is not None and len(v) > max_v:
                    fail(f"'{col}' too long (len={len(v)} > {max_v})")
                continue

            if etype == "expect_column_values_to_match_regex":
                col = kwargs["column"]
                regex = kwargs["regex"]
                v = row.get(col, "")
                if not isinstance(v, str) or not re.match(regex, v):
                    fail(f"'{col}' does not match regex '{regex}' (value='{v}')")
                continue

            # ------------- règles dates -------------

            if etype == "expect_published_before_fetched":
                p = parse_iso(row.get("publishedAt"))
                f = parse_iso(row.get("fetched_at"))
                if p is None or f is None:
                    fail("invalid datetime for publishedAt/fetched_at")
                elif p > f:
                    fail(f"publishedAt ({p}) > fetched_at ({f})")
                continue

            if etype == "expect_no_future_dates":
                col = kwargs["column"]
                d = parse_iso(row.get(col))
                now = datetime.now(timezone.utc)
                if d is None:
                    fail(f"invalid datetime in '{col}'")
                elif d > now:
                    fail(f"future datetime in '{col}': {d} > {now}")
                continue

            # ------------- règles globales sur le dataset -------------

            if etype == "expect_no_duplicate_urls":
                url = row.get("url")
                if url in urls_seen:
                    fail(f"duplicate url: {url}")
                else:
                    urls_seen.add(url)
                continue

            # Si on tombe sur un type inconnu
            fail(f"Unknown expectation_type: {etype}")

    # 4) Calcul du score
    if total_checks == 0:
        score = 0.0
    else:
        # On pénalise plus les erreurs que les warnings
        effective_failures = failed_errors + 0.5 * failed_warnings
        score = max(0.0, 100.0 * (1.0 - (effective_failures / total_checks)))

    success = failed_errors == 0

    # 5) Logs de synthèse
    if success and failed_warnings == 0:
        print(f"[GE] ✅ All validations passed. score={score:.2f}")
    elif success and failed_warnings > 0:
        print(
            f"[GE] ⚠ Passed with warnings. "
            f"score={score:.2f}, warnings={failed_warnings}"
        )
    else:
        print(
            f"[GE] ❌ Validation failed. "
            f"score={score:.2f}, errors={failed_errors}, warnings={failed_warnings}"
        )

    # (optionnel) on peut logguer quelques détails
    for msg in error_details[:5]:
        print("[GE][ERROR] ", msg)
    for msg in warning_details[:5]:
        print("[GE][WARN]  ", msg)

    return {
        "success": success,
        "score": round(score, 2),
        "total_checks": total_checks,
        "failed_errors": failed_errors,
        "failed_warnings": failed_warnings,
        "errors": error_details,
        "warnings": warning_details,
    }
