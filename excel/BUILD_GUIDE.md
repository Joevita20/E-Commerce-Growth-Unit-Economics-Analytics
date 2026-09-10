# Excel — Driver-Based Forecast & Variance Model

**Goal:** a 4-sheet workbook — actuals, forecast assumptions, a volume/rate variance
bridge, and a sensitivity ("what-if") table — that turns the weekly trend data into a
finance-flavoured deliverable.

**Why two factors, not three.** A classic revenue bridge splits variance into Volume ×
Rate × Price (Sessions × CVR × AOV). In this dataset, CVR is session-based and AOV is
purchase-event-based — different denominators — which leaves a large unreconciled
residual (10–20%) if you multiply them together. Rather than publish a bridge that
doesn't add up, this model uses **Sessions × Revenue-per-Session**, which reconciles
*exactly* (it's `revenue = sessions × (revenue / sessions)`, true by construction). Two
clean, exact factors are more defensible than three approximate ones.

---

## Sheet 1 — `Weekly_Actuals`

1. Open Excel → **New Workbook** → rename `Sheet1` to `Weekly_Actuals`
2. Enter this table starting at `A1` (type it in, or copy-paste from
   `data/processed/weekly_trend.csv`):

| Week | Sessions | Purchases | CVR % | Revenue | AOV | Rev/Session | Include? |
|---|---|---|---|---|---|---|---|
| 10/26/2020 | 2625 | 13 | 0.495% | 773 | 55.21 | 0.2945 | No — partial week |
| 11/2/2020 | 24991 | 249 | 0.996% | 21820 | 74.98 | 0.8731 | Yes |
| 11/9/2020 | 22508 | 341 | 1.515% | 23694 | 64.74 | 1.0527 | Yes |
| 11/16/2020 | 25914 | 374 | 1.443% | 38086 | 67.65 | 1.4697 | Yes |
| 11/23/2020 | 27780 | 515 | 1.854% | 47973 | 70.44 | 1.7269 | Yes |
| 11/30/2020 | 31088 | 590 | 1.898% | 43042 | 66.84 | 1.3845 | Yes |
| 12/7/2020 | 38729 | 772 | 1.993% | 59721 | 69.04 | 1.5420 | Yes |
| 12/14/2020 | 33411 | 549 | 1.643% | 47276 | 69.02 | 1.4150 | Yes |
| 12/21/2020 | 22083 | 233 | 1.055% | 14716 | 57.26 | 0.6664 | Yes |
| 12/28/2020 | 20444 | 138 | 0.675% | 10368 | 62.84 | 0.5071 | Yes |
| 1/4/2021 | 29029 | 162 | 0.558% | 9402 | 55.31 | 0.3239 | Yes |
| 1/11/2021 | 27707 | 227 | 0.819% | 13150 | 51.98 | 0.4746 | Yes |
| 1/18/2021 | 27478 | 375 | 1.365% | 26966 | 67.42 | 0.9814 | Yes |
| 1/25/2021 | 26342 | 310 | 1.177% | 5178 | 15.32 | 0.1966 | No — AOV anomaly |

3. Format the Week column as dates, CVR% as percentage, Revenue/AOV/Rev-per-Session as
   currency (2–4 decimals).
4. Add a note cell below the table:
   > 10/26 excluded as a partial boundary week; 1/25 excluded — AOV collapses to $15.32
   > against a $55–75 baseline, consistent with an artifact at the edge of the extraction
   > window rather than genuine buyer behaviour. See `docs/data_quality_report.md`.

---

## Sheet 2 — `Forecast_Assumptions`

This sheet computes the "plan" — what December was expected to do, based on November's
run rate.

1. New sheet, rename `Forecast_Assumptions`
2. Build this table with **live formulas referencing Sheet 1**, not typed numbers:

| Cell | Label | Formula |
|---|---|---|
| B1 | Forecast basis | `November actuals (5 weeks: 11/2–11/30)` |
| B2 | Avg weekly sessions | `=AVERAGE(Weekly_Actuals!B3:B7)` |
| B3 | Avg revenue/session | `=AVERAGE(Weekly_Actuals!G3:G7)` |
| B4 | **Forecast weekly revenue** | `=B2*B3` |

*(Adjust row numbers B3:B7 to match wherever your November rows actually landed once
pasted — they should be the 5 rows from 11/2 through 11/30.)*

This should compute to **≈26,456 sessions**, **≈$1.301/session**, **≈$34,433/week
forecast**. If your numbers are close to these, the formulas are wired correctly.

---

## Sheet 3 — `Variance_Bridge` (the centrepiece)

1. New sheet, rename `Variance_Bridge`
2. Build this table for the 4 December weeks:

| Week | Actual Sessions | Actual Rev/Session | Actual Revenue | Forecast Revenue | Volume Variance | Rate Variance | Total Variance |
|---|---|---|---|---|---|---|---|
| 12/7 | =Weekly_Actuals!B8 | =Weekly_Actuals!G8 | =Weekly_Actuals!E8 | =Forecast_Assumptions!$B$4 | =(B2-Forecast_Assumptions!$B$2)*Forecast_Assumptions!$B$3 | =B2*(C2-Forecast_Assumptions!$B$3) | =F2+G2 |
| 12/14 | … | … | … | … | … | … | … |
| 12/21 | … | … | … | … | … | … | … |
| 12/28 | … | … | … | … | … | … | … |
| **Total** | | | `=SUM(D2:D5)` | `=SUM(E2:E5)` | `=SUM(F2:F5)` | `=SUM(G2:G5)` | `=SUM(H2:H5)` |

**The formulas, explained:**
- `Volume Variance = (Actual Sessions − Forecast Sessions) × Forecast Rev/Session`
  → how much revenue moved *purely because traffic differed from plan*
- `Rate Variance = Actual Sessions × (Actual Rev/Session − Forecast Rev/Session)`
  → how much revenue moved *purely because monetization differed from plan*
- These two sum **exactly** to `Actual Revenue − Forecast Revenue` — verify this with a
  check row: `=H2-(D2-E2)` should equal 0 (or a cent of rounding) on every row.

**Add a waterfall chart:** select the Total row's Forecast Revenue, Volume Variance, Rate
Variance, and Actual Revenue → **Insert → Waterfall Chart** (Excel 2016+has this natively
under Insert → Charts → Waterfall). Title it:
> **"December missed plan by $5.6K — but traffic beat it. Monetization is the whole story."**

You should land on: **Total Volume Variance ≈ +$11,508**, **Total Rate Variance ≈
−$17,145**, **Total Variance ≈ −$5,637**.

---

## Sheet 4 — `Sensitivity` (the forward-looking what-if)

This answers: *"If we recovered monetization to November's level, what would that be
worth?"*

1. New sheet, rename `Sensitivity`
2. Set up the inputs:

| Cell | Label | Value |
|---|---|---|
| B1 | Sessions (current trend) | `=AVERAGE(Weekly_Actuals!B10:B13)` *(Jan weeks)* |
| B2 | Revenue/Session (current trend) | `=AVERAGE(Weekly_Actuals!G10:G13)` |
| B3 | **Weekly Revenue** | `=B1*B2` |

3. Build the two-variable data table:
   - In a new area, put **Revenue/Session scenarios** down a column (e.g. `0.35, 0.50,
     0.65, 0.80, 1.00, 1.30` — spanning worst-December to full-November-recovery)
   - Put **Sessions scenarios** across a row (e.g. current, `+10%`, `+20%`)
   - In the top-left corner cell of that grid, put `=B3` (referencing the Weekly Revenue
     formula)
   - Select the whole grid (including that corner formula cell) → **Data → What-If
     Analysis → Data Table**
   - **Row input cell:** `B1` (sessions) · **Column input cell:** `B2` (rev/session)
   - Excel fills in the grid automatically, showing weekly revenue under every
     combination

4. Apply conditional formatting (colour scale) to the grid so the answer is visually
   obvious — worst-case bottom-left, best-case top-right.

**The number this produces is your recommendation's headline:** recovering
revenue-per-session from the January trend back to November's ~$1.30 level, holding
sessions constant, is worth roughly **(1.30 − current) × current sessions** in
incremental weekly revenue — read the exact figure off your grid.

---

## What this feeds

- **README finding #10** — the variance bridge numbers (already drafted, see below)
- **Recommendations section** — the sensitivity table's "what would recovery be worth"
  number becomes your headline ask
- **Resume bullet** — "driver-based revenue forecast (sessions × revenue-per-session),
  volume/rate variance bridge, and a two-variable sensitivity model in Excel"

Save the file as `excel/ecommerce_forecast_model.xlsx` and commit it to the repo.
