"""Shared configuration for the E-Commerce Growth & Unit Economics project."""

from pathlib import Path

# ---- BigQuery ----
PROJECT_ID = "ga4-growth-analytics-505818"
DATASET = "ga4_growth"
SESSIONS_TABLE = f"{PROJECT_ID}.{DATASET}.fct_sessions"

# Public source dataset
GA4_SOURCE = "bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*"
DATE_START = "20201101"
DATE_END = "20210131"

# ---- Paths ----
ROOT = Path(__file__).resolve().parents[2]
DATA_RAW = ROOT / "data" / "raw"
DATA_INTERIM = ROOT / "data" / "interim"
DATA_PROCESSED = ROOT / "data" / "processed"
FIGURES = ROOT / "reports" / "figures"

for _p in (DATA_RAW, DATA_INTERIM, DATA_PROCESSED, FIGURES):
    _p.mkdir(parents=True, exist_ok=True)

# ---- Analysis constants ----
FUNNEL_STEPS = [
    ("reached_session_start", "Session start"),
    ("reached_view_item", "View item"),
    ("reached_add_to_cart", "Add to cart"),
    ("reached_begin_checkout", "Begin checkout"),
    ("reached_add_payment", "Add payment"),
    ("reached_purchase", "Purchase"),
]
# add_shipping deliberately omitted: it differs from begin_checkout by 1 session.
# See docs/data_quality_report.md §3.4.

ALPHA = 0.05
POWER = 0.80
