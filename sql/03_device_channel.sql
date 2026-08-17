-- =====================================================================
-- 03_device_channel.sql
-- Device segmentation and channel attribution.
--
-- Depends on: ga4_growth.fct_sessions
-- Project ID is already set. Paste straight into the BigQuery editor.
--
-- RUN ORDER: block A, then block B. Block C/D are finalised once we know
-- which source/medium values actually exist (block B tells us).
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. Funnel and economics by device category
--
--    Feeds finding #4 (mobile vs desktop gap) and the two-proportion
--    z-test in notebooks/02_funnel_stats.ipynb.
--
--    Note: begin_checkout and add_shipping are treated as one stage
--    (they differ by 1 session — see docs/data_quality_report.md §3.4).
-- ---------------------------------------------------------------------
SELECT
  device_category,
  COUNT(*)                                                              AS sessions,
  COUNTIF(reached_view_item)                                            AS view_item,
  COUNTIF(reached_add_to_cart)                                          AS add_to_cart,
  COUNTIF(reached_begin_checkout)                                       AS begin_checkout,
  COUNTIF(reached_add_payment)                                          AS add_payment,
  COUNTIF(reached_purchase)                                             AS purchase,

  -- Headline conversion
  ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 3)      AS cvr_pct,

  -- Step-level rates, so we can see WHERE devices differ, not just THAT they differ
  ROUND(SAFE_DIVIDE(COUNTIF(reached_view_item), COUNT(*)) * 100, 2)     AS session_to_view_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_add_to_cart),
                    COUNTIF(reached_view_item)) * 100, 2)               AS view_to_cart_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_begin_checkout),
                    COUNTIF(reached_add_to_cart)) * 100, 2)             AS cart_to_checkout_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_add_payment),
                    COUNTIF(reached_begin_checkout)) * 100, 2)          AS checkout_to_payment_pct,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase),
                    COUNTIF(reached_begin_checkout)) * 100, 2)          AS checkout_completion_pct,

  -- Economics
  ROUND(SUM(revenue_usd), 2)                                            AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), NULLIF(SUM(purchases), 0)), 2)    AS aov,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 3)                     AS revenue_per_session,
  ROUND(AVG(session_duration_sec), 1)                                   AS avg_duration_sec,
  ROUND(AVG(page_views), 2)                                             AS avg_page_views

FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
GROUP BY device_category
ORDER BY sessions DESC;


-- ---------------------------------------------------------------------
-- B. What source / medium values actually exist?
--
--    RUN THIS BEFORE WRITING ANY CHANNEL GROUPING. Hardcoding a CASE
--    statement against assumed values is how channel analyses quietly
--    end up 100% "Other".
--
--    Restricted to attributable sessions only (see data quality §3.2).
-- ---------------------------------------------------------------------
SELECT
  last_touch_source,
  last_touch_medium,
  COUNT(*)                                                              AS sessions,
  COUNTIF(reached_purchase)                                             AS purchases,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 3)      AS cvr_pct,
  ROUND(SUM(revenue_usd), 2)                                            AS revenue_usd
FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
WHERE last_touch_source IS NOT NULL
GROUP BY last_touch_source, last_touch_medium
ORDER BY sessions DESC
LIMIT 40;


-- ---------------------------------------------------------------------
-- C. First-touch source / medium values
--    Same check for the other attribution model. These often differ,
--    which is the whole point of the comparison.
-- ---------------------------------------------------------------------
SELECT
  first_touch_source,
  first_touch_medium,
  COUNT(*)                                                              AS sessions,
  COUNTIF(reached_purchase)                                             AS purchases,
  ROUND(SUM(revenue_usd), 2)                                            AS revenue_usd
FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
GROUP BY first_touch_source, first_touch_medium
ORDER BY sessions DESC
LIMIT 40;


-- ---------------------------------------------------------------------
-- D. Channel grouping + first vs last touch comparison
--    TO BE WRITTEN once blocks B and C confirm the real values.
-- ---------------------------------------------------------------------
