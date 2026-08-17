# BigQuery Sandbox Setup

One-time setup, ~10 minutes, **no credit card required**.

---

## 1. Create the sandbox project

1. Go to **https://console.cloud.google.com/bigquery**
2. Sign in with any Google account (a personal Gmail is fine).
3. Accept the terms. When prompted, **do not** add a billing account — the sandbox is the
   no-billing mode and it is what keeps this free.
4. Create a project. Suggested name: **`ga4-growth-analytics`**.
5. Note the **Project ID** shown in the console (it may have a numeric suffix, e.g.
   `ga4-growth-analytics-482913`). You will paste it into the SQL files.

## 2. Create your working dataset

In the BigQuery console, click your project → **Create dataset**:

| Field | Value |
|---|---|
| Dataset ID | `ga4_growth` |
| Location type | **Multi-region → US** |

> ⚠️ **The location must be `US`.** The public GA4 dataset lives in the US multi-region,
> and BigQuery cannot join across locations. Picking `EU` here will break every query.

## 3. Confirm you can reach the public dataset

Paste this into the query editor and run it. It should return 5 rows.

```sql
SELECT event_name, COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
  AND event_name IN ('view_item','add_to_cart','begin_checkout','add_payment_info','purchase')
GROUP BY event_name
ORDER BY users DESC
```

If it runs, setup is done.

---

## Sandbox limits and how to stay inside them

| Limit | Value | What it means for you |
|---|---|---|
| Query processing | **1 TB / month** | Plenty, *if* you filter `_TABLE_SUFFIX` |
| Active storage | **10 GB** | Your derived tables are small — not a concern |
| Table expiry | **60 days** | ⚠️ Your tables auto-delete. Export results to `data/processed/` and commit them. |
| Billing | None possible | You get blocked before you can be charged |

### Three habits that keep you under 1 TB

1. **Always filter `_TABLE_SUFFIX`.** Without it, the `events_*` wildcard scans every
   table in the dataset.
2. **Select only the columns you need.** BigQuery is columnar and bills on bytes scanned,
   so `SELECT *` is the expensive mistake, not row count.
3. **Read the cost estimate before running.** The top-right of the query editor shows
   *"This query will process X"* before you click Run. Check it every time.

### Useful notes on the GA4 schema

- `event_params` and `items` are **nested arrays** — you need `UNNEST()` to read them.
- `ga_session_id` lives in `event_params` as an **int_value**, not a top-level column.
  A session is the pair `user_pseudo_id` + `ga_session_id`.
- `event_date` is a **STRING** in `YYYYMMDD` form — parse it with
  `PARSE_DATE('%Y%m%d', event_date)`.
- `traffic_source` at the top level is the user's **first-touch** acquisition source.
- `ecommerce.purchase_revenue_in_usd` is only populated on `purchase` events.

---

## Running the SQL in this repo

Files in `sql/` are numbered in execution order. Before running, replace the placeholder
`YOUR_PROJECT` with your actual Project ID from step 1.

```
sql/00_explore_schema.sql     -- sanity checks; run first
sql/01_sessions.sql           -- builds ga4_growth.fct_sessions
sql/02_funnel.sql             -- funnel conversion and drop-off by step
```
