# E-Commerce Growth & Unit Economics Analytics

> Where does a D2C store lose customers, which channels actually pay for themselves, and
> what does next quarter look like? An end-to-end analysis of **4.3M GA4 events across
> 360K sessions** — from BigQuery ETL to funnel diagnostics, channel attribution, unit
> economics, and a driver-based revenue forecast.

**Stack:** Python · SQL · Google BigQuery · dbt · Power BI (DAX) · Tableau · Excel · A/B Testing

🔗 **Live dashboard:** _Tableau Public link — publishing in progress_

<!-- When the dashboard is assembled and published:
     1. Screenshot the full dashboard -> reports/figures/tableau_dashboard.png
     2. Replace the line above with the public URL
     3. Uncomment the image line below                                        -->
<!-- [![Dashboard](reports/figures/tableau_dashboard.png)](TABLEAU_PUBLIC_URL) -->

---

## Key findings

> _Populated as the analysis completes. Each finding = a number, a "so what", and an action._

1. **56.4% of sessions that begin checkout never purchase** — 6,258 high-intent sessions
   lost after the user has already committed. The loss concentrates at a single step:
   **38.6% drop between entering shipping details and entering payment** (4,290 sessions),
   followed by a further **28.9% drop between payment entry and purchase**.
2. **80.3% of sessions that view a product never add it to cart** (61,832 sessions) — the
   largest proportional leak, but a slower, merchandising-led fix than checkout.
3. **Attribution coverage is 73.5%, and the missing 26.5% converts at 0.001% with zero
   revenue** — systematic, not random. Blended CVR (1.346%) understates attributable CVR
   (1.830%) by 36% relative, so the denominator choice is material.
4. **A statistically significant result that should not be acted on.** Mobile converts
   *above* desktop (1.393% vs 1.316%) at **p = 0.0497** — yet **no individual funnel step
   differs significantly** (p = 0.29, 0.22, 0.17, 0.35) and the 95% CIs overlap. The
   headline result is four indistinguishable differences accumulating across 350K
   sessions. Recommendation: **no device-specific action**; the checkout collapse is
   structural to the flow, not a mobile UX problem.
5. **63% of revenue was attributed to the store referring to itself.** `shop.google
   merchandisestore.com` appears as an external last-touch source for 112,228 sessions
   carrying $227,879 — a cross-domain tracking artifact, not a channel. Identified,
   quantified and excluded before any channel analysis was run.
6. **Attribution model flips the channel ranking, not just the magnitudes.** Last-touch
   understates Direct by 84.7%, Paid Search by 78.1% and Organic by 48.5%, while
   overstating Referral by 42.6% — moving Referral from 3rd to a near-tie for 1st and
   dropping Direct from 2nd to 3rd. Yet on revenue-per-session, Paid Search is still the
   weakest genuine channel ($0.58 vs $1.006 site average), so the recommendation is to
   **fix the measurement before changing the budget** — a measurement problem and a
   performance problem, separated.
7. **The traffic cannot support small-effect experimentation.** Power analysis on the
   payment step (61.37% baseline, 121 eligible sessions/day) shows a 1pp lift would need
   **37,031 sessions per arm and 88 weeks** to detect at 80% power. The viable design is a
   **3pp MDE, 4,070 per arm, ~10 weeks** — anything finer is undetectable before
   seasonality contaminates the read.
8. **Acquisition quality collapsed 85% post-holiday while traffic volume held.** Week-0
   revenue per cohort user fell from **$1.62 (Black Friday week) to $0.24 (4 Jan)** with
   cohort sizes still above 20K — January traffic is high-volume, low-intent. Week-1
   retention traced the same V-shape, from **6.68% down to 2.46%** and back to 4.12%:
   holiday-acquired users are one-time seasonal buyers.
9. **Low retention ≠ low retention value.** Despite week-1 retention of only ~6%,
   **57% of the 2 Nov cohort's total revenue arrived after the acquisition week**
   ($28,483 vs $21,276) — repeated for the 9 Nov (54%) and 16 Nov (42%) cohorts. The
   returning minority is disproportionately valuable per head, which changes the strategy
   from pure acquisition to defending a small but economically material repeat base.
10. _TBD — forecast variance decomposition_

**Baseline:** 360,129 sessions · 270,154 users · $362,165 revenue · $63.63 AOV · $1.006 revenue/session

## Recommendations

1. _TBD_
2. _TBD_
3. _TBD_

---

## Data

| | |
|---|---|
| Source | `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` |
| Period | 1 Nov 2020 – 31 Jan 2021 |
| Grain | One row per GA4 event; `event_params` and `items` are nested arrays |
| Access | BigQuery sandbox — free, no credit card required |

> ⚠️ **Data note.** Google labels this dataset as *obfuscated*, with placeholder values and
> limited internal consistency. All figures are **illustrative of the methodology rather than
> actual store performance**, and are reported as rates rather than dollar amounts where possible.

> ⚠️ **Sandbox note.** BigQuery sandbox tables expire after 60 days. Aggregated outputs are
> exported to `data/processed/` and committed so results remain reproducible.

---

## Repository structure

```
├── data/
│   ├── raw/           # BigQuery extracts (gitignored — reproducible from sql/)
│   ├── interim/       # Intermediate transforms (gitignored)
│   └── processed/     # Aggregated outputs (committed — sandbox tables expire)
├── sql/               # BigQuery queries: sessions, funnel, attribution, cohorts
├── src/
│   ├── etl/           # Extract → clean → build marts
│   └── utils/         # Shared config and helpers
├── notebooks/         # EDA, hypothesis tests, power analysis
├── powerbi/           # Data model spec, DAX measures, .pbix
├── tableau/           # Workbook and published-view notes
├── excel/             # Driver-based forecast and variance model
├── docs/              # BRD, data quality report, experiment brief, insights memo
└── reports/figures/   # Exported charts
```

---

## Setup

```bash
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

BigQuery access requires a free sandbox project — see `docs/setup_bigquery.md` (Step 2).

---

## Build log

- [x] **Step 1** — Repo foundation, BRD, metric definitions
- [ ] **Step 2** — BigQuery sandbox setup + funnel/session queries
- [ ] **Step 3** — Python ETL + data quality report
- [ ] **Step 4** — Attribution, cohorts, statistical tests, power analysis
- [ ] **Step 5** — Power BI star-schema model + DAX
- [ ] **Step 6** — Excel forecast/variance model + Tableau Public
- [ ] **Step 7** — Docs, experiment brief, insights memo, process map

---

## Author

**Joevita Faustina Doss** — [GitHub](https://github.com/Joevita20)
