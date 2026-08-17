"""
Experiment design for the checkout-payment step.

The funnel shows a 38.6% drop between entering shipping details and entering
payment (4,290 sessions lost). That is the highest-intent abandonment in the
funnel and the strongest experiment candidate.

This script answers the question a growth team actually asks BEFORE running a
test: how big a lift can we realistically detect, how many sessions does that
need, and how long will it take?

    python src/analysis/02_power_analysis.py
"""

# %%
import sys
from pathlib import Path

import pandas as pd
from statsmodels.stats.power import NormalIndPower
from statsmodels.stats.proportion import proportion_effectsize

sys.path.append(str(Path(__file__).resolve().parents[1]))
from utils.config import ALPHA, DATA_PROCESSED, POWER  # noqa: E402

# %%
# ---------------------------------------------------------------------
# Observed baseline (from sql/02_funnel.sql)
# ---------------------------------------------------------------------
BASELINE_RATE = 0.6137          # add_shipping -> add_payment conversion
SESSIONS_AT_STEP = 11_105       # sessions reaching add_shipping
WINDOW_DAYS = 92                # 2020-11-01 to 2021-01-31

daily_traffic = SESSIONS_AT_STEP / WINDOW_DAYS

print("--- Baseline ---")
print(f"Step                : add_shipping_info -> add_payment_info")
print(f"Baseline conversion : {BASELINE_RATE*100:.2f}%")
print(f"Sessions at step    : {SESSIONS_AT_STEP:,} over {WINDOW_DAYS} days")
print(f"Daily eligible      : {daily_traffic:.1f} sessions/day")
print(f"Alpha / power       : {ALPHA} / {POWER}")

# %%
# ---------------------------------------------------------------------
# Sample size across a range of minimum detectable effects
#
# Two-sided test, equal allocation, alpha=0.05, power=0.80.
# ---------------------------------------------------------------------
analysis = NormalIndPower()
rows = []

for mde_pp in [1.0, 2.0, 3.0, 4.0, 5.0, 7.5, 10.0]:
    treatment_rate = BASELINE_RATE + mde_pp / 100
    effect = proportion_effectsize(treatment_rate, BASELINE_RATE)

    n_per_arm = analysis.solve_power(
        effect_size=effect,
        alpha=ALPHA,
        power=POWER,
        ratio=1.0,
        alternative="two-sided",
    )
    n_per_arm = int(round(n_per_arm))
    n_total = n_per_arm * 2

    rows.append(
        {
            "mde_pp": mde_pp,
            "mde_relative_pct": round(mde_pp / (BASELINE_RATE * 100) * 100, 1),
            "treatment_rate_pct": round(treatment_rate * 100, 2),
            "n_per_arm": n_per_arm,
            "n_total": n_total,
            "days_required": round(n_total / daily_traffic, 1),
            "weeks_required": round(n_total / daily_traffic / 7, 1),
        }
    )

power_table = pd.DataFrame(rows)
print("\n--- Sample size by minimum detectable effect ---")
print(power_table.to_string(index=False))

power_table.to_csv(DATA_PROCESSED / "power_analysis.csv", index=False)
print(f"\nSaved -> {DATA_PROCESSED / 'power_analysis.csv'}")

# %%
# ---------------------------------------------------------------------
# RECOMMENDATION
#
# Anything below ~3pp needs a runtime long enough that seasonality and
# site changes would contaminate the result. The practical design is:
#
#   - Target MDE : 3pp absolute (61.4% -> 64.4%, a 4.9% relative lift)
#   - Runtime    : see days_required above; round UP to whole weeks so
#                  every weekday is represented equally in both arms.
#
# GUARDRAIL METRICS (must not degrade):
#   - AOV                 — a lift driven by discounting is not a win
#   - Refund / return rate — if available
#   - Payment error rate
#   - Overall site CVR    — confirms we moved the step, not just shifted
#                           abandonment upstream
#
# PRE-LAUNCH DIAGNOSTIC:
#   - Sample Ratio Mismatch (SRM): chi-square the actual arm split against
#     the intended 50/50. A significant SRM invalidates the test regardless
#     of how good the result looks.
#
# ANALYSIS DISCIPLINE:
#   - Fixed horizon, no peeking. Checking daily and stopping on the first
#     significant reading inflates the false-positive rate well above 5%.
#     If continuous monitoring is required, use a sequential testing
#     procedure with alpha spending rather than repeated fixed-horizon tests.
#   - CUPED (using pre-experiment session behaviour as a covariate) would
#     reduce variance and shorten runtime materially. Noted as the next
#     methodological step; not applied here because the sample data lacks a
#     clean pre-period per user.
# ---------------------------------------------------------------------
