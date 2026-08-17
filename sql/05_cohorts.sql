-- =====================================================================
-- 05_cohorts.sql
-- Weekly cohort retention and repeat-purchase behaviour.
--
-- Depends on: ga4_growth.fct_sessions
-- Project ID is already set.
--
-- CAVEAT THAT MUST TRAVEL WITH THESE NUMBERS
-- `user_pseudo_id` is device-scoped, not person-scoped. A user switching
-- from phone to laptop appears as two users. Retention here is therefore a
-- LOWER BOUND, and the 3-month window truncates every cohort after the
-- first. Both are stated in docs/data_quality_report.md.
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. Weekly session-retention cohorts
--    Cohort = week of a user's first observed session.
--    week_number 0 = acquisition week.
-- ---------------------------------------------------------------------
WITH user_first AS (
  SELECT
    user_pseudo_id,
    MIN(session_week) AS cohort_week
  FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
  GROUP BY user_pseudo_id
),

activity AS (
  SELECT
    s.user_pseudo_id,
    u.cohort_week,
    DATE_DIFF(s.session_week, u.cohort_week, WEEK) AS week_number,
    s.revenue_usd,
    s.reached_purchase
  FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions` s
  JOIN user_first u USING (user_pseudo_id)
),

cohort_size AS (
  SELECT cohort_week, COUNT(*) AS cohort_users
  FROM user_first
  GROUP BY cohort_week
)

SELECT
  a.cohort_week,
  c.cohort_users,
  a.week_number,
  COUNT(DISTINCT a.user_pseudo_id)                                        AS active_users,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT a.user_pseudo_id),
                    c.cohort_users) * 100, 2)                             AS retention_pct,
  COUNT(DISTINCT IF(a.reached_purchase, a.user_pseudo_id, NULL))          AS purchasing_users,
  ROUND(SUM(a.revenue_usd), 2)                                            AS revenue_usd,
  ROUND(SAFE_DIVIDE(SUM(a.revenue_usd), c.cohort_users), 3)               AS revenue_per_cohort_user
FROM activity a
JOIN cohort_size c USING (cohort_week)
GROUP BY a.cohort_week, c.cohort_users, a.week_number
ORDER BY a.cohort_week, a.week_number;


-- ---------------------------------------------------------------------
-- B. Repeat-purchase distribution
--    How concentrated is revenue among repeat buyers? This is the input
--    to the LTV assumption in the unit-economics model.
-- ---------------------------------------------------------------------
-- WITH per_user AS (
--   SELECT
--     user_pseudo_id,
--     SUM(purchases)      AS purchases,
--     SUM(revenue_usd)    AS revenue
--   FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
--   GROUP BY user_pseudo_id
--   HAVING purchases > 0
-- )
-- SELECT
--   purchases                                                          AS orders_per_user,
--   COUNT(*)                                                           AS users,
--   ROUND(SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) * 100, 2)       AS pct_of_buyers,
--   ROUND(SUM(revenue), 2)                                             AS revenue,
--   ROUND(SAFE_DIVIDE(SUM(revenue), SUM(SUM(revenue)) OVER ()) * 100, 2) AS pct_of_revenue,
--   ROUND(AVG(revenue), 2)                                             AS avg_revenue_per_user
-- FROM per_user
-- GROUP BY orders_per_user
-- ORDER BY orders_per_user;


-- ---------------------------------------------------------------------
-- C. Revenue concentration — the Pareto check
--    "What share of revenue comes from the top X% of buyers?"
-- ---------------------------------------------------------------------
-- WITH per_user AS (
--   SELECT user_pseudo_id, SUM(revenue_usd) AS revenue
--   FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
--   GROUP BY user_pseudo_id
--   HAVING revenue > 0
-- ),
-- ranked AS (
--   SELECT
--     user_pseudo_id,
--     revenue,
--     NTILE(10) OVER (ORDER BY revenue DESC) AS revenue_decile
--   FROM per_user
-- )
-- SELECT
--   revenue_decile,
--   COUNT(*)                                                           AS buyers,
--   ROUND(SUM(revenue), 2)                                             AS revenue,
--   ROUND(SAFE_DIVIDE(SUM(revenue), SUM(SUM(revenue)) OVER ()) * 100, 2) AS pct_of_revenue,
--   ROUND(SUM(SAFE_DIVIDE(SUM(revenue), SUM(SUM(revenue)) OVER ()) * 100)
--         OVER (ORDER BY revenue_decile), 2)                           AS cumulative_pct
-- FROM ranked
-- GROUP BY revenue_decile
-- ORDER BY revenue_decile;
