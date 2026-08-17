-- =====================================================================
-- 02_funnel.sql
-- Purchase funnel: how many sessions reach each step, step-to-step
-- conversion, and drop-off.
--
-- Depends on: sql/01_sessions.sql (fct_sessions)
-- Project ID is already set. Paste this straight into the BigQuery editor.
--
-- Funnel definition (session-scoped, non-strict):
--   session_start -> view_item -> add_to_cart -> begin_checkout
--                 -> add_shipping_info -> add_payment_info -> purchase
--
-- "Non-strict" means we count whether a session reached a step at all,
-- not whether it did so in order. This is the standard GA4 approach and
-- is stated explicitly in docs/BRD.md so the definition is auditable.
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. Overall funnel with step conversion and drop-off
-- ---------------------------------------------------------------------
WITH steps AS (
  SELECT 1 AS step_no, 'Session start'   AS step_name, COUNTIF(reached_session_start)  AS sessions FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 2, 'View item',        COUNTIF(reached_view_item)      FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 3, 'Add to cart',      COUNTIF(reached_add_to_cart)    FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 4, 'Begin checkout',   COUNTIF(reached_begin_checkout) FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 5, 'Add shipping',     COUNTIF(reached_add_shipping)   FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 6, 'Add payment',      COUNTIF(reached_add_payment)    FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  UNION ALL
  SELECT 7, 'Purchase',         COUNTIF(reached_purchase)       FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
)
SELECT
  step_no,
  step_name,
  sessions,

  -- Window function: previous step's session count
  LAG(sessions) OVER (ORDER BY step_no)                                    AS prev_step_sessions,

  -- Step-to-step conversion
  ROUND(SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_no)) * 100, 2)
                                                                           AS step_conversion_pct,

  -- Drop-off from the previous step
  ROUND((1 - SAFE_DIVIDE(sessions, LAG(sessions) OVER (ORDER BY step_no))) * 100, 2)
                                                                           AS step_dropoff_pct,

  -- Absolute sessions lost at this step
  LAG(sessions) OVER (ORDER BY step_no) - sessions                         AS sessions_lost,

  -- Cumulative conversion from the top of the funnel
  ROUND(SAFE_DIVIDE(sessions, FIRST_VALUE(sessions) OVER (ORDER BY step_no)) * 100, 2)
                                                                           AS cumulative_conversion_pct
FROM steps
ORDER BY step_no;


-- ---------------------------------------------------------------------
-- B. Funnel by device category
--    The mobile-vs-desktop gap usually shows up here. Feeds the
--    two-proportion z-test in notebooks/02_funnel_stats.
-- ---------------------------------------------------------------------
-- SELECT
--   device_category,
--   COUNT(*)                                                            AS sessions,
--   COUNTIF(reached_view_item)                                          AS view_item,
--   COUNTIF(reached_add_to_cart)                                        AS add_to_cart,
--   COUNTIF(reached_begin_checkout)                                     AS begin_checkout,
--   COUNTIF(reached_purchase)                                           AS purchase,
--   ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 3)    AS cvr_pct,
--   ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase),
--                     COUNTIF(reached_add_to_cart)) * 100, 2)           AS cart_to_purchase_pct,
--   ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 3)                   AS revenue_per_session,
--   ROUND(SAFE_DIVIDE(SUM(revenue_usd), NULLIF(SUM(purchases), 0)), 2)  AS aov
-- FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
-- GROUP BY device_category
-- ORDER BY sessions DESC;


-- ---------------------------------------------------------------------
-- C. Cart abandonment rate, overall and by device
--    Defined in the BRD as: 1 - (purchase sessions / add-to-cart sessions)
-- ---------------------------------------------------------------------
-- SELECT
--   device_category,
--   COUNTIF(reached_add_to_cart)                                        AS carts_created,
--   COUNTIF(reached_purchase)                                           AS purchases,
--   ROUND((1 - SAFE_DIVIDE(COUNTIF(reached_purchase),
--                          COUNTIF(reached_add_to_cart))) * 100, 2)     AS cart_abandonment_pct
-- FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
-- GROUP BY device_category
-- ORDER BY carts_created DESC;


-- ---------------------------------------------------------------------
-- D. Weekly funnel trend
--    Needed for the Power BI trend page and the Excel forecast drivers.
-- ---------------------------------------------------------------------
-- SELECT
--   session_week,
--   COUNT(*)                                                            AS sessions,
--   COUNTIF(reached_add_to_cart)                                        AS add_to_cart,
--   COUNTIF(reached_purchase)                                           AS purchases,
--   ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 3)    AS cvr_pct,
--   ROUND(SUM(revenue_usd), 2)                                          AS revenue_usd,
--   ROUND(SAFE_DIVIDE(SUM(revenue_usd), NULLIF(SUM(purchases), 0)), 2)  AS aov,
--   -- Week-over-week revenue growth
--   ROUND((SAFE_DIVIDE(SUM(revenue_usd),
--          LAG(SUM(revenue_usd)) OVER (ORDER BY session_week)) - 1) * 100, 2) AS wow_revenue_pct
-- FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
-- GROUP BY session_week
-- ORDER BY session_week;
