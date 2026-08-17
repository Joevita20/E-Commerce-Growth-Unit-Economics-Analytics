-- =====================================================================
-- 01_sessions.sql
-- Builds the core session-level fact table.
--
-- Grain: one row per session (user_pseudo_id + ga_session_id).
-- Output: `YOUR_PROJECT.ga4_growth.fct_sessions`
--
-- BEFORE RUNNING: replace YOUR_PROJECT with your BigQuery Project ID.
--
-- Why this table exists: GA4 stores one row per *event* with nested
-- arrays. Almost every growth metric (CVR, AOV, revenue per session,
-- funnel drop-off) is defined at session grain, so we flatten once here
-- and reuse it everywhere downstream.
-- =====================================================================

CREATE OR REPLACE TABLE `YOUR_PROJECT.ga4_growth.fct_sessions` AS

WITH events AS (
  SELECT
    user_pseudo_id,

    -- ga_session_id is buried in event_params as an int_value.
    -- This is the single most important extraction in the whole project.
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'ga_session_id')                       AS ga_session_id,

    event_name,
    event_timestamp,
    PARSE_DATE('%Y%m%d', event_date)                       AS event_dt,

    -- Device / geo are top-level structs
    device.category                                        AS device_category,
    device.operating_system                                AS operating_system,
    device.web_info.browser                                AS browser,
    geo.country                                            AS country,
    geo.region                                             AS region,
    geo.city                                               AS city,

    -- Top-level traffic_source = user-level FIRST TOUCH acquisition
    traffic_source.source                                  AS first_touch_source,
    traffic_source.medium                                  AS first_touch_medium,
    traffic_source.name                                    AS first_touch_campaign,

    -- Session-scoped source/medium, when present in params (used for LAST TOUCH).
    -- Verify coverage with sql/00_explore_schema.sql block C before relying on it.
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'source')                              AS session_source,
    (SELECT ep.value.string_value
     FROM UNNEST(event_params) AS ep
     WHERE ep.key = 'medium')                              AS session_medium,

    -- Revenue is only populated on purchase events
    ecommerce.purchase_revenue_in_usd                      AS purchase_revenue_usd,
    ecommerce.transaction_id                               AS transaction_id,
    ecommerce.total_item_quantity                          AS item_quantity

  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)

SELECT
  -- ---------- Keys ----------
  CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING))   AS session_key,
  user_pseudo_id,
  ga_session_id,

  -- ---------- Timing ----------
  MIN(event_dt)                                                AS session_date,
  DATE_TRUNC(MIN(event_dt), WEEK(MONDAY))                      AS session_week,
  TIMESTAMP_MICROS(MIN(event_timestamp))                       AS session_start_ts,
  TIMESTAMP_MICROS(MAX(event_timestamp))                       AS session_end_ts,
  ROUND((MAX(event_timestamp) - MIN(event_timestamp)) / 1e6, 1) AS session_duration_sec,

  -- ---------- Dimensions (first non-null wins) ----------
  ANY_VALUE(device_category)                                   AS device_category,
  ANY_VALUE(operating_system)                                  AS operating_system,
  ANY_VALUE(browser)                                           AS browser,
  ANY_VALUE(country)                                           AS country,
  ANY_VALUE(region)                                            AS region,
  ANY_VALUE(city)                                              AS city,

  ANY_VALUE(first_touch_source)                                AS first_touch_source,
  ANY_VALUE(first_touch_medium)                                AS first_touch_medium,
  ANY_VALUE(first_touch_campaign)                              AS first_touch_campaign,

  -- Last-touch = source/medium observed on this session
  MAX(session_source)                                          AS last_touch_source,
  MAX(session_medium)                                          AS last_touch_medium,

  -- ---------- Engagement ----------
  COUNT(*)                                                     AS event_count,
  COUNTIF(event_name = 'page_view')                            AS page_views,

  -- ---------- Funnel step flags ----------
  -- Boolean per step: did this session reach it at least once?
  COUNTIF(event_name = 'session_start')     > 0                AS reached_session_start,
  COUNTIF(event_name = 'view_item')         > 0                AS reached_view_item,
  COUNTIF(event_name = 'add_to_cart')       > 0                AS reached_add_to_cart,
  COUNTIF(event_name = 'begin_checkout')    > 0                AS reached_begin_checkout,
  COUNTIF(event_name = 'add_shipping_info') > 0                AS reached_add_shipping,
  COUNTIF(event_name = 'add_payment_info')  > 0                AS reached_add_payment,
  COUNTIF(event_name = 'purchase')          > 0                AS reached_purchase,

  -- ---------- Commercial outcome ----------
  COUNTIF(event_name = 'purchase')                             AS purchases,
  COUNT(DISTINCT IF(event_name = 'purchase', transaction_id, NULL)) AS transactions,
  ROUND(SUM(IF(event_name = 'purchase', purchase_revenue_usd, 0)), 2) AS revenue_usd,
  SUM(IF(event_name = 'purchase', item_quantity, 0))           AS items_purchased

FROM events
-- Events without a ga_session_id cannot be attributed to a session.
-- Count how many you drop and record it in docs/data_quality_report.md.
WHERE ga_session_id IS NOT NULL
GROUP BY session_key, user_pseudo_id, ga_session_id;


-- ---------------------------------------------------------------------
-- POST-BUILD CHECKS — run these and log the results in the data quality report.
-- ---------------------------------------------------------------------

-- 1. Table size and revenue reconciliation against the raw event total (00, block D)
-- SELECT COUNT(*) AS sessions,
--        COUNT(DISTINCT user_pseudo_id) AS users,
--        ROUND(SUM(revenue_usd), 2) AS total_revenue,
--        ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 2) AS cvr_pct
-- FROM `YOUR_PROJECT.ga4_growth.fct_sessions`;

-- 2. How many events were dropped for a missing ga_session_id?
-- SELECT COUNTIF((SELECT ep.value.int_value FROM UNNEST(event_params) ep
--                 WHERE ep.key='ga_session_id') IS NULL) AS dropped_events,
--        COUNT(*) AS total_events
-- FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
-- WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';
