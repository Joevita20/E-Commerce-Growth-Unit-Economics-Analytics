-- =====================================================================
-- 00_explore_schema.sql
-- Sanity checks before building anything. Run each block separately.
-- Purpose: confirm access, date coverage, event vocabulary, and the
--          shape of the nested columns.
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. Date coverage and overall volume
--    Confirms the window is what the docs claim (2020-11-01 to 2021-01-31).
-- ---------------------------------------------------------------------
SELECT
  MIN(event_date)                  AS first_date,
  MAX(event_date)                  AS last_date,
  COUNT(*)                         AS total_events,
  COUNT(DISTINCT user_pseudo_id)   AS total_users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';


-- ---------------------------------------------------------------------
-- B. Event vocabulary
--    Which events exist, and how common are they? This tells you which
--    funnel steps are actually usable.
-- ---------------------------------------------------------------------
SELECT
  event_name,
  COUNT(*)                       AS events,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
ORDER BY events DESC;


-- ---------------------------------------------------------------------
-- C. What keys live inside event_params?
--    You need this to know what you can extract. Note that ga_session_id
--    is here, NOT as a top-level column.
-- ---------------------------------------------------------------------
SELECT
  ep.key,
  COUNT(*) AS occurrences
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
  UNNEST(event_params) AS ep
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY ep.key
ORDER BY occurrences DESC;


-- ---------------------------------------------------------------------
-- D. Revenue sanity check
--    Confirms purchase_revenue_in_usd is only populated on purchase events,
--    and gives you a baseline total to reconcile against later.
-- ---------------------------------------------------------------------
SELECT
  event_name,
  COUNT(*)                                        AS events,
  COUNTIF(ecommerce.purchase_revenue_in_usd > 0)  AS events_with_revenue,
  ROUND(SUM(ecommerce.purchase_revenue_in_usd),2) AS total_revenue_usd
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY event_name
HAVING events_with_revenue > 0
ORDER BY total_revenue_usd DESC;


-- ---------------------------------------------------------------------
-- E. First-touch traffic source distribution
--    traffic_source at top level = user acquisition source (first touch).
-- ---------------------------------------------------------------------
SELECT
  traffic_source.source,
  traffic_source.medium,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY 1, 2
ORDER BY users DESC
LIMIT 25;


-- ---------------------------------------------------------------------
-- F. Device split
--    Expect mobile to carry heavy traffic. The conversion gap comes later.
-- ---------------------------------------------------------------------
SELECT
  device.category,
  COUNT(DISTINCT user_pseudo_id) AS users,
  COUNT(*)                       AS events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
GROUP BY 1
ORDER BY users DESC;
