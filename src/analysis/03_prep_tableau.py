"""
Reshape the analysis outputs into Tableau-friendly extracts.

Tableau wants long/tidy data for dumbbell and small-multiple forms, and it
cannot compute Wilson confidence intervals, so those are precomputed here.

    python src/analysis/03_prep_tableau.py
"""

# %%
import sys
from pathlib import Path

import pandas as pd
from statsmodels.stats.proportion import proportion_confint

sys.path.append(str(Path(__file__).resolve().parents[1]))
from utils.config import DATA_PROCESSED  # noqa: E402

# %%
# ---------------------------------------------------------------------
# 1. Attribution -> long format for the dumbbell chart
# ---------------------------------------------------------------------
attr = pd.read_csv(DATA_PROCESSED / "attribution_comparison.csv")

long = pd.concat(
    [
        attr.assign(
            model="First touch",
            revenue=attr["ft_revenue"],
            sessions=attr["ft_sessions"],
        ),
        attr.assign(
            model="Last touch",
            revenue=attr["lt_revenue"],
            sessions=attr["lt_sessions"],
        ),
    ]
)[["channel", "genuine_channel", "model", "revenue", "sessions"]]

long["revenue_per_session"] = (long["revenue"] / long["sessions"]).round(3)
long = long.sort_values(["channel", "model"])

long.to_csv(DATA_PROCESSED / "attribution_long.csv", index=False)
print(f"attribution_long.csv       -> {len(long)} rows")

# %%
# ---------------------------------------------------------------------
# 2. Device conversion with Wilson 95% confidence intervals
#
# The finding is that the devices are NOT meaningfully different, so the
# chart must show the intervals overlapping. Tableau can't compute Wilson
# intervals, so they are precomputed as columns.
# ---------------------------------------------------------------------
device = pd.read_csv(DATA_PROCESSED / "device_performance.csv")

ci = []
for _, r in device.iterrows():
    lo, hi = proportion_confint(
        int(r["purchase"]), int(r["sessions"]), alpha=0.05, method="wilson"
    )
    ci.append(
        {
            "device_category": r["device_category"],
            "sessions": int(r["sessions"]),
            "purchases": int(r["purchase"]),
            "cvr_pct": round(r["purchase"] / r["sessions"] * 100, 3),
            "ci_lower_pct": round(lo * 100, 3),
            "ci_upper_pct": round(hi * 100, 3),
            "revenue_per_session": r["revenue_per_session"],
            "aov": r["aov"],
        }
    )

device_ci = pd.DataFrame(ci)
device_ci.to_csv(DATA_PROCESSED / "device_cvr_ci.csv", index=False)
print(f"device_cvr_ci.csv          -> {len(device_ci)} rows")
print(device_ci.to_string(index=False))

# %%
# ---------------------------------------------------------------------
# 3. Funnel with an emphasis flag
#
# "Emphasis" rather than a colour ramp: one accent on the step that is the
# story, everything else recessive. The bar length already encodes magnitude,
# so a per-step colour ramp would be redundant double-encoding.
# ---------------------------------------------------------------------
funnel = pd.read_csv(DATA_PROCESSED / "funnel_overall.csv")
funnel = funnel[funnel["step_name"] != "Add shipping"].copy()  # DQ report 3.4

# Recompute step transitions after collapsing the shipping step
funnel["prev_step"] = funnel["sessions"].shift(1)
funnel["step_conv_pct"] = (funnel["sessions"] / funnel["prev_step"] * 100).round(2)
funnel["dropoff_pct"] = (100 - funnel["step_conv_pct"]).round(2)
funnel["sessions_lost"] = (funnel["prev_step"] - funnel["sessions"]).astype("Int64")
funnel["cumulative_conv_pct"] = (
    funnel["sessions"] / funnel["sessions"].iloc[0] * 100
).round(2)

# Emphasise the highest-intent leak: the checkout payment step
funnel["emphasis"] = funnel["step_name"].apply(
    lambda s: "Focus" if s == "Add payment" else "Context"
)

funnel.to_csv(DATA_PROCESSED / "funnel_tableau.csv", index=False)
print(f"\nfunnel_tableau.csv         -> {len(funnel)} rows")
print(funnel[["step_name", "sessions", "dropoff_pct", "emphasis"]].to_string(index=False))

# %%
# ---------------------------------------------------------------------
# 4. KPI tiles
# ---------------------------------------------------------------------
# display_value is precomputed as a string: a single Tableau text tile cannot
# carry three different number formats ($ / % / count) off one measure.
kpis = pd.DataFrame(
    [
        {"sort": 1, "kpi": "Sessions", "value": 360129,
         "display_value": "360,129", "context": "270,154 users"},
        {"sort": 2, "kpi": "Revenue", "value": 362165.00,
         "display_value": "$362,165", "context": "5,692 orders"},
        {"sort": 3, "kpi": "Conversion rate", "value": 1.346,
         "display_value": "1.35%", "context": "1.83% on attributable traffic"},
        {"sort": 4, "kpi": "Average order value", "value": 63.63,
         "display_value": "$63.63", "context": "mobile $62.32 / desktop $64.73"},
        {"sort": 5, "kpi": "Revenue per session", "value": 1.006,
         "display_value": "$1.006", "context": "Referral highest at $1.07"},
    ]
)
kpis.to_csv(DATA_PROCESSED / "kpi_tiles.csv", index=False)
print(f"\nkpi_tiles.csv              -> {len(kpis)} rows")
