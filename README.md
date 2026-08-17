# E-Commerce Growth & Unit Economics Analytics

> Where does a D2C store lose customers, which channels actually pay for themselves, and
> what does next quarter look like? An end-to-end analysis of 2M+ GA4 events — from
> BigQuery ETL to funnel diagnostics, channel attribution, unit economics, and a
> driver-based revenue forecast.

**Stack:** Python · SQL · Google BigQuery · dbt · Power BI (DAX) · Tableau · Excel · A/B Testing

🔗 **Live dashboard:** _Tableau Public link — coming in Step 6_

---

## Key findings

> _Populated as the analysis completes. Each finding = a number, a "so what", and an action._

1. _TBD — funnel drop-off_
2. _TBD — mobile vs desktop conversion gap_
3. _TBD — first-touch vs last-touch attribution shift_
4. _TBD — channel unit economics_
5. _TBD — forecast variance decomposition_

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
