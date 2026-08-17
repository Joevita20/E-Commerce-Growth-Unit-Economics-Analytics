# Tableau Public — Executive View Build Guide

**Goal:** one polished dashboard page, published to a public URL you can put on
your resume. One good page beats three mediocre ones.

---

## 0. Setup

1. Download **Tableau Public** (free, native macOS): https://public.tableau.com/app/discover
2. Create a free Tableau Public account — you'll need it, because Tableau Public
   **cannot save locally**. Every save goes to the web.
3. Install the colour palettes:
   ```
   cp tableau/Preferences.tps ~/Documents/My\ Tableau\ Repository/Preferences.tps
   ```
   Then **restart Tableau**. Three custom palettes appear in the colour dropdown.

> Because Tableau Public is public-only, never put private data in it. This project
> uses a Google public dataset, so there is nothing to protect.

## 1. Connect the data

**Connect → To a File → Text file**, and add each of these from `data/processed/`
as a **separate data source** (they have different grains — do not join them):

| File | Feeds |
|---|---|
| `kpi_tiles.csv` | KPI row |
| `funnel_tableau.csv` | Funnel |
| `device_cvr_ci.csv` | Device conversion |
| `attribution_long.csv` | Attribution dumbbell |
| `cohort_retention.csv` | Cohort heatmap |

---

## 2. Sheet 1 — "KPI Row"

*Source: `kpi_tiles.csv`*

1. Drag **kpi** to **Columns**. Sort by **sort** ascending.
2. Mark type → **Text**.
3. Drag **display_value** to **Text**.
4. Click **Text → Edit label**. Arrange three lines:
   - `<kpi>` — 10pt, grey, uppercase
   - `<display_value>` — **28pt bold**, near-black
   - `<context>` — 9pt, grey
5. Hide field labels for columns. Format → remove all borders, gridlines, shading.

> These are **stat tiles, not a chart.** Five headline numbers do not belong in a
> bar chart — the reader wants to read them, not compare their lengths.

## 3. Sheet 2 — "Funnel"

*Source: `funnel_tableau.csv`*

1. **Rows:** `step_name` (sort by **step_no** ascending — semantic order, never by value).
2. **Columns:** `SUM(sessions)`.
3. Mark type → **Bar**.
4. Drag **emphasis** to **Colour** → palette **"Growth Emphasis"**.
   Assign `Focus` → blue, `Context` → grey.
5. Drag **cumulative_conv_pct** to **Label**, format `0.00"%"`.
6. **Tooltip:** sessions, dropoff_pct, sessions_lost.
7. Title: **"56% of checkout starts never convert"** — state the finding, don't
   describe the chart.

> **Why one accent and not a colour ramp per step:** the bar length already encodes
> magnitude. A ramp would encode the same variable twice while adding nothing. The
> accent instead marks the step that carries the *argument* — the payment drop.

## 4. Sheet 3 — "Device conversion"

*Source: `device_cvr_ci.csv`*

The point of this chart is that the intervals **overlap**, so the intervals must be
visible. Point estimates alone would imply a difference that isn't there.

1. Create calculated field **`CI width`** = `[Ci Upper Pct] - [Ci Lower Pct]`
2. **Rows:** `device_category`. **Columns:** `ci_lower_pct`.
3. Mark type → **Gantt Bar**. Drag **`CI width`** to **Size**. Colour: grey `#b7b6b0`.
4. Drag `cvr_pct` to **Columns** again → right-click the second axis →
   **Dual Axis** → right-click → **Synchronise Axis**.
5. Second marks card → **Circle**, size ~10, colour blue `#2a78d6`.
6. Title: **"Device is not a conversion lever (p = 0.0497, intervals overlap)"**

> Synchronised dual axis is fine here — both marks are the same measure on the same
> scale. What's forbidden is two *different* measures on two *different* scales.

**If step 3–4 gets fiddly:** fall back to a plain bar of `cvr_pct` with the CI
bounds in the tooltip and the conclusion in the title. Honest and quick.

## 5. Sheet 4 — "Attribution: first vs last touch"

*Source: `attribution_long.csv`*

1. **Filter:** `genuine_channel` = `yes` (drops the self-referral artifact, internal
   traffic and the obfuscated buckets).
2. **Rows:** `channel`, sorted by first-touch revenue descending.
3. **Columns:** `SUM(revenue)`. Mark type → **Line**. Drag **model** to **Path**.
   Colour: grey.
4. Duplicate `SUM(revenue)` on Columns → **Dual Axis** → **Synchronise Axis**.
5. Second marks card → **Circle**, size ~12. Drag **model** to **Colour** →
   palette **"Growth Dumbbell"**.
6. Title: **"Last-touch understates Direct by 85% and Paid Search by 78%"**

> **Why a dumbbell and not grouped bars:** the job is *before → after per item*.
> A dumbbell puts the shift itself on screen as the connecting segment; grouped bars
> make the reader compute the gap. Two shades of one hue, not two hues — these are
> two states of the same measure, not two unrelated series.

## 6. Sheet 5 — "Weekly cohort retention"

*Source: `cohort_retention.csv`*

1. **Filters:** exclude cohort `2020-10-26` (partial week, 2,365 users — see data
   quality report L8). Limit `week_number` to **0–8** for legibility.
2. **Rows:** `cohort_week` (discrete, exact date). **Columns:** `week_number` (discrete).
3. Mark type → **Square**.
4. Drag `retention_pct` to **Colour** → palette **"Growth Sequential Blue"**.
   Right-click the legend → **Edit Colours** → tick **Use Full Colour Range**.
5. Drag `retention_pct` to **Label**, format `0.0"%"`.
6. Title: **"Holiday cohorts retain at half the rate — 6.7% → 2.5%"**

> Sequential, single hue, light→dark. Never a rainbow or red-green ramp on a
> heatmap: one hue means the reader decodes magnitude from lightness alone.

---

## 7. Assemble the dashboard

**Dashboard → New Dashboard.** Size: **Automatic**, or fixed `1200 × 1400`.

```
┌──────────────────────────────────────────────────────────┐
│  E-Commerce Growth & Unit Economics                      │  title
│  Google Merchandise Store · Nov 2020 – Jan 2021          │  subtitle
├──────────────────────────────────────────────────────────┤
│  [KPI Row — 5 tiles]                                     │
├───────────────────────────────┬──────────────────────────┤
│  Funnel                       │  Device conversion       │
│  (60%)                        │  (40%)                   │
├───────────────────────────────┴──────────────────────────┤
│  Attribution: first vs last touch                        │
├──────────────────────────────────────────────────────────┤
│  Weekly cohort retention                                 │
├──────────────────────────────────────────────────────────┤
│  Source / caveats footer                                 │
└──────────────────────────────────────────────────────────┘
```

**Footer text** — add as a Text object. This is not boilerplate; it is the thing
that makes an analyst trust the rest of the page:

> Source: `bigquery-public-data.ga4_obfuscated_sample_ecommerce` · 4,295,584 events,
> 360,129 sessions, 1 Nov 2020 – 31 Jan 2021. Data is obfuscated by Google;
> figures illustrate the method rather than actual store performance. 26.5% of
> sessions lack an attribution source and convert at 0.001% — excluded from channel
> analysis. Self-referral traffic (63% of last-touch revenue) identified as a
> cross-domain tracking artifact and excluded. Full notes: `docs/data_quality_report.md`.

**Formatting pass:**
- Remove every worksheet border and shading
- Dashboard background `#fcfcfb`
- Titles left-aligned, bold, ~14pt; subtitles grey, ~10pt
- Delete legends that repeat a direct label

---

## 8. Publish

**File → Save to Tableau Public As…** → name it
**"E-Commerce Growth Analytics — Executive View"**.

Then on public.tableau.com: open the viz → **Edit Details** → write a 2–3 sentence
description with the headline findings, and set a thumbnail.

Copy the URL into:
- `README.md` (replace the "coming in Step 6" placeholder)
- Your resume project line
- Your LinkedIn featured section

---

## Checklist before you call it done

- [ ] Every title states a **finding**, not a chart description
- [ ] No dual axis with two *different* measures on different scales
- [ ] Heatmap uses one hue, light→dark
- [ ] Funnel sorted by step order, not by value
- [ ] Confidence intervals visible on the device chart
- [ ] Footer carries the data caveats
- [ ] Viewed at 100% zoom — no clipped labels or overlapping text
