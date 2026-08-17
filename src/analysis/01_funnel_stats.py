"""
Hypothesis testing on the funnel.

Two questions:
  1. Is the desktop-vs-mobile conversion gap real, or noise?
  2. Where in the funnel do devices actually differ?

Reads the exported CSVs in data/processed/ so it runs without BigQuery access.

Run as a script, or cell-by-cell in VS Code / Jupyter (# %% markers).

    python src/analysis/01_funnel_stats.py
"""

# %%
import sys
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from statsmodels.stats.proportion import (
    proportion_confint,
    proportions_ztest,
)

sys.path.append(str(Path(__file__).resolve().parents[1]))
from utils.config import DATA_PROCESSED, FIGURES  # noqa: E402

pd.set_option("display.width", 120)

# %%
# ---------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------
device = pd.read_csv(DATA_PROCESSED / "device_performance.csv")
funnel = pd.read_csv(DATA_PROCESSED / "funnel_overall.csv")

print(device.to_string(index=False))

# %%
# ---------------------------------------------------------------------
# 1. Two-proportion z-test: desktop vs mobile conversion
#
# H0: CVR_desktop == CVR_mobile
# H1: CVR_desktop != CVR_mobile   (two-sided; we had no prior direction)
# alpha = 0.05
# ---------------------------------------------------------------------
d = device.set_index("device_category")

successes = [d.loc["desktop", "purchase"], d.loc["mobile", "purchase"]]
trials = [d.loc["desktop", "sessions"], d.loc["mobile", "sessions"]]

stat, pval = proportions_ztest(count=successes, nobs=trials, alternative="two-sided")

p_desktop = successes[0] / trials[0]
p_mobile = successes[1] / trials[1]
abs_diff_pp = (p_mobile - p_desktop) * 100
rel_diff_pct = (p_mobile / p_desktop - 1) * 100

print("\n--- Desktop vs Mobile conversion ---")
print(f"Desktop CVR      : {p_desktop*100:.3f}%  ({successes[0]:,} / {trials[0]:,})")
print(f"Mobile CVR       : {p_mobile*100:.3f}%  ({successes[1]:,} / {trials[1]:,})")
print(f"Absolute diff    : {abs_diff_pp:+.3f} pp")
print(f"Relative diff    : {rel_diff_pct:+.1f}%")
print(f"z-statistic      : {stat:.4f}")
print(f"p-value          : {pval:.4f}")
print(f"Significant @.05 : {'YES' if pval < 0.05 else 'NO'}")

for label, s, n in zip(["desktop", "mobile"], successes, trials):
    lo, hi = proportion_confint(s, n, alpha=0.05, method="wilson")
    print(f"95% CI {label:<8}: [{lo*100:.3f}%, {hi*100:.3f}%]")

# %%
# ---------------------------------------------------------------------
# INTERPRETATION (written here so the conclusion travels with the code)
#
# The gap is ~0.08pp and sits on the significance boundary. With 350K+
# sessions, even a trivial difference reaches p ~ 0.05 — which is exactly
# why statistical significance must not be read as business significance.
#
# Practical conclusion: device is NOT a conversion lever here. The 95% CIs
# overlap substantially and the effect is far too small to justify a
# device-specific redesign.
# ---------------------------------------------------------------------

# %%
# ---------------------------------------------------------------------
# 2. Where do devices differ? Test each funnel step separately.
# ---------------------------------------------------------------------
steps = [
    ("View -> Cart", "add_to_cart", "view_item"),
    ("Cart -> Checkout", "begin_checkout", "add_to_cart"),
    ("Checkout -> Payment", "add_payment", "begin_checkout"),
    ("Payment -> Purchase", "purchase", "add_payment"),
]

rows = []
for name, num, den in steps:
    cnt = [d.loc["desktop", num], d.loc["mobile", num]]
    nob = [d.loc["desktop", den], d.loc["mobile", den]]
    z, p = proportions_ztest(count=cnt, nobs=nob, alternative="two-sided")
    rows.append(
        {
            "step": name,
            "desktop_pct": round(cnt[0] / nob[0] * 100, 2),
            "mobile_pct": round(cnt[1] / nob[1] * 100, 2),
            "diff_pp": round((cnt[1] / nob[1] - cnt[0] / nob[0]) * 100, 2),
            "z": round(z, 3),
            "p_value": round(p, 4),
            "significant": p < 0.05,
        }
    )

step_tests = pd.DataFrame(rows)
print("\n--- Step-level device comparison ---")
print(step_tests.to_string(index=False))
step_tests.to_csv(DATA_PROCESSED / "device_step_tests.csv", index=False)

# %%
# ---------------------------------------------------------------------
# 3. Funnel chart
# ---------------------------------------------------------------------
f = funnel[funnel["step_name"] != "Add shipping"].copy()  # collapsed: see DQ report 3.4

fig, ax = plt.subplots(figsize=(9, 5))
bars = ax.barh(f["step_name"][::-1], f["sessions"][::-1], color="#4C78A8")
ax.set_xlabel("Sessions")
ax.set_title("Purchase funnel — session-scoped", loc="left", fontsize=13, weight="bold")

for bar, pct in zip(bars, f["cumulative_conv_pct"][::-1]):
    ax.text(
        bar.get_width() * 1.01,
        bar.get_y() + bar.get_height() / 2,
        f"{pct:.2f}%",
        va="center",
        fontsize=9,
    )

ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig(FIGURES / "funnel.png", dpi=150)
print(f"\nSaved -> {FIGURES / 'funnel.png'}")
