-- =====================================================================
-- 04_attribution.sql
-- Channel grouping + first-touch vs last-touch comparison.
--
-- Depends on: ga4_growth.fct_sessions
-- Project ID is already set. Paste straight into the BigQuery editor.
--
-- WHY THE GROUPING LOOKS LIKE THIS
-- Block B of 03_device_channel.sql revealed two things that force
-- decisions before any channel number can be trusted:
--
--   1. SELF-REFERRAL. `shop.googlemerchandisestore.com` and
--      `googlemerchandisestore.com` are the store's own domains, yet they
--      appear as the last-touch source for 112,228 sessions carrying
--      $227,879 (63% of all revenue). This is a cross-domain tracking
--      artifact, not an acquisition channel. Treated as its own bucket and
--      excluded from channel comparisons.
--
--   2. INTERNAL TRAFFIC. `analytics.google.com` sent 2,982 sessions with
--      1 purchase and $0 revenue — people browsing the GA demo account.
--      Excluded.
--
-- Both exclusions are quantified in docs/data_quality_report.md.
-- =====================================================================


-- ---------------------------------------------------------------------
-- A. First-touch vs last-touch revenue by channel
-- ---------------------------------------------------------------------
WITH base AS (
  SELECT
    session_key,
    revenue_usd,
    reached_purchase,

    -- ---- First-touch channel (user acquisition source) ----
    CASE
      WHEN first_touch_source IN ('shop.googlemerchandisestore.com',
                                  'googlemerchandisestore.com') THEN 'Self-referral (artifact)'
      WHEN first_touch_source = 'analytics.google.com'          THEN 'Internal'
      WHEN first_touch_source = '(data deleted)'
        OR first_touch_medium = '(data deleted)'                THEN 'Redacted'
      WHEN first_touch_medium = 'organic'                       THEN 'Organic Search'
      WHEN first_touch_medium = 'cpc'                           THEN 'Paid Search'
      WHEN first_touch_medium = 'affiliate'                     THEN 'Affiliate'
      WHEN first_touch_source = '(direct)'                      THEN 'Direct'
      WHEN first_touch_medium = 'referral'                      THEN 'Referral'
      ELSE 'Other / obfuscated'
    END AS first_touch_channel,

    -- ---- Last-touch channel (session source) ----
    CASE
      WHEN last_touch_source IS NULL                            THEN NULL
      WHEN last_touch_source IN ('shop.googlemerchandisestore.com',
                                 'googlemerchandisestore.com')  THEN 'Self-referral (artifact)'
      WHEN last_touch_source = 'analytics.google.com'           THEN 'Internal'
      WHEN last_touch_source = '(data deleted)'
        OR last_touch_medium = '(data deleted)'                 THEN 'Redacted'
      WHEN last_touch_medium = 'organic'                        THEN 'Organic Search'
      WHEN last_touch_medium = 'cpc'                            THEN 'Paid Search'
      WHEN last_touch_medium = 'affiliate'                      THEN 'Affiliate'
      WHEN last_touch_source = '(direct)'                       THEN 'Direct'
      WHEN last_touch_medium = 'referral'                       THEN 'Referral'
      ELSE 'Other / obfuscated'
    END AS last_touch_channel

  FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
),

first_touch AS (
  SELECT
    first_touch_channel                AS channel,
    COUNT(*)                           AS ft_sessions,
    COUNTIF(reached_purchase)          AS ft_purchases,
    ROUND(SUM(revenue_usd), 2)         AS ft_revenue
  FROM base
  GROUP BY channel
),

last_touch AS (
  SELECT
    last_touch_channel                 AS channel,
    COUNT(*)                           AS lt_sessions,
    COUNTIF(reached_purchase)          AS lt_purchases,
    ROUND(SUM(revenue_usd), 2)         AS lt_revenue
  FROM base
  WHERE last_touch_channel IS NOT NULL
  GROUP BY channel
)

SELECT
  COALESCE(f.channel, l.channel)                                    AS channel,
  IFNULL(f.ft_sessions, 0)                                          AS ft_sessions,
  IFNULL(f.ft_revenue, 0)                                           AS ft_revenue,
  IFNULL(l.lt_sessions, 0)                                          AS lt_sessions,
  IFNULL(l.lt_revenue, 0)                                           AS lt_revenue,

  -- How much credit does last-touch give versus first-touch?
  ROUND(IFNULL(l.lt_revenue, 0) - IFNULL(f.ft_revenue, 0), 2)       AS revenue_delta,
  ROUND((SAFE_DIVIDE(IFNULL(l.lt_revenue, 0),
                     NULLIF(f.ft_revenue, 0)) - 1) * 100, 1)        AS lt_vs_ft_pct,

  -- Share of total revenue under each model
  ROUND(SAFE_DIVIDE(IFNULL(f.ft_revenue, 0),
                    SUM(IFNULL(f.ft_revenue, 0)) OVER ()) * 100, 2) AS ft_revenue_share_pct,
  ROUND(SAFE_DIVIDE(IFNULL(l.lt_revenue, 0),
                    SUM(IFNULL(l.lt_revenue, 0)) OVER ()) * 100, 2) AS lt_revenue_share_pct

FROM first_touch f
FULL OUTER JOIN last_touch l USING (channel)
ORDER BY ft_revenue DESC;


-- ---------------------------------------------------------------------
-- B. Genuine channels only — the version that supports a budget decision.
--    Excludes the self-referral artifact, internal traffic, and the
--    obfuscated buckets. Re-bases shares to 100% of attributable revenue.
-- ---------------------------------------------------------------------
-- Wrap block A in an outer query and filter:
--   WHERE channel NOT IN ('Self-referral (artifact)', 'Internal',
--                         'Redacted', 'Other / obfuscated')


-- ---------------------------------------------------------------------
-- C. Self-referral scale check — the number quoted in the report
-- ---------------------------------------------------------------------
-- SELECT
--   COUNT(*)                                                          AS sessions,
--   ROUND(SUM(revenue_usd), 2)                                        AS revenue,
--   ROUND(SAFE_DIVIDE(SUM(revenue_usd),
--         (SELECT SUM(revenue_usd)
--          FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`)) * 100, 2)
--                                                                     AS pct_of_total_revenue
-- FROM `ga4-growth-analytics-505818.ga4_growth.fct_sessions`
-- WHERE last_touch_source IN ('shop.googlemerchandisestore.com',
--                             'googlemerchandisestore.com');
