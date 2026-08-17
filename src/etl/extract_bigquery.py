"""
Extract fct_sessions from BigQuery into a local parquet file.

Everything downstream (stats, power analysis, Power BI, Tableau, Excel) reads
from the local extract rather than hitting BigQuery repeatedly. Two reasons:
  1. Sandbox tables expire after 60 days — the extract is the durable copy.
  2. It keeps query quota free for exploration.

Usage:
    python src/etl/extract_bigquery.py

Prerequisites:
    pip install -r requirements.txt
    gcloud auth application-default login
"""

import sys

import pandas as pd
from google.cloud import bigquery

sys.path.append(str(__import__("pathlib").Path(__file__).resolve().parents[1]))
from utils.config import DATA_RAW, PROJECT_ID, SESSIONS_TABLE  # noqa: E402


def extract_sessions(client: bigquery.Client) -> pd.DataFrame:
    """Pull the full session fact table."""
    query = f"SELECT * FROM `{SESSIONS_TABLE}`"
    print(f"Querying {SESSIONS_TABLE} ...")
    df = client.query(query).to_dataframe()
    print(f"  -> {len(df):,} rows x {len(df.columns)} columns")
    return df


def summarise(df: pd.DataFrame) -> None:
    """Print the reconciliation numbers that go in the data quality report."""
    purchases = int(df["purchases"].sum())
    revenue = float(df["revenue_usd"].sum())
    purchase_sessions = int(df["reached_purchase"].sum())

    print("\n--- Reconciliation ---")
    print(f"Sessions              : {len(df):,}")
    print(f"Users                 : {df['user_pseudo_id'].nunique():,}")
    print(f"Purchases             : {purchases:,}")
    print(f"Purchase sessions     : {purchase_sessions:,}")
    print(f"Revenue               : ${revenue:,.2f}")
    print(f"AOV                   : ${revenue / purchases:,.2f}")
    print(f"Revenue per session   : ${revenue / len(df):,.3f}")
    print(f"Blended CVR           : {purchase_sessions / len(df) * 100:.3f}%")

    attributable = df[df["last_touch_source"].notna()]
    print(
        f"Attributable CVR      : "
        f"{attributable['reached_purchase'].sum() / len(attributable) * 100:.3f}%"
    )
    print(f"Attribution coverage  : {len(attributable) / len(df) * 100:.2f}%")


def main() -> None:
    client = bigquery.Client(project=PROJECT_ID)

    df = extract_sessions(client)
    summarise(df)

    out = DATA_RAW / "fct_sessions.parquet"
    df.to_parquet(out, index=False)
    print(f"\nSaved -> {out}")


if __name__ == "__main__":
    main()
