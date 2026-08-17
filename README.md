# E-Commerce Growth & Unit Economics Analytics

> Where does a D2C store lose customers, which channels actually pay for themselves, and
> what does next quarter look like? An end-to-end analysis of **4.3M GA4 events across
> 360K sessions** — from BigQuery ETL to funnel diagnostics, channel attribution, unit
> economics, and a driver-based revenue forecast.

**Stack:** Python · SQL · Google BigQuery · dbt · Power BI (DAX) · Tableau · Excel · A/B Testing

🔗 **Live dashboard:** _Tableau Public link — coming in Step 6_

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
4. _TBD — mobile vs desktop conversion gap_
5. _TBD — first-touch vs last-touch attribution shift_
6. _TBD — forecast variance decomposition_

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
