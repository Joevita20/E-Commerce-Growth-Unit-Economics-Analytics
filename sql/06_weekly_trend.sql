-- =====================================================================
-- 06_weekly_trend.sql
-- Weekly sessions, conversion, AOV and revenue — the time series the
-- Excel forecast model is built on.
--
-- Depends on: ga4_growth.fct_sessions
-- Project ID is already set. Paste straight into the BigQuery editor.
-- =====================================================================

SELECT
  session_week,
  COUNT(*)                                                            AS sessions,
  COUNT(DISTINCT user_pseudo_id)                                      AS users,
  COUNTIF(reached_purchase)                                           AS purchases,
  ROUND(SAFE_DIVIDE(COUNTIF(reached_purchase), COUNT(*)) * 100, 3)    AS cvr_pct,
  ROUND(SUM(revenue_usd), 2)                                          AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), NULLIF(SUM(purchases), 0)), 2)  AS aov,
  ROUND(SAFE_DIVIDE(SUM(revenue_usd), COUNT(*)), 4)                   AS revenue_per_session
FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
GROUP BY session_week
ORDER BY session_week;
