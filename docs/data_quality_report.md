# Data Quality Report

Source: `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
Window: 2020-11-01 → 2021-01-31
Built by: `sql/01_sessions.sql` → `ga4_growth.fct_sessions`

---

## 1. Volume reconciliation

| Measure | Value |
|---|---|
| Raw events | 4,295,584 |
| Distinct users (raw) | 270,154 |
| Sessions built | 360,129 |
| Sessions per user | 1.33 |
| Total revenue | $362,165.00 |
| Purchase events | 5,692 |
| AOV | $63.63 |
| Revenue per session | $1.006 |
| Session-level CVR (blended) | 1.346% |

## 2. Key rules applied

| # | Rule | Impact |
|---|---|---|
| R1 | Session key = `user_pseudo_id` + `ga_session_id` (extracted from `event_params`) | Required — GA4 has no top-level session column |
| R2 | Drop events with null `ga_session_id` | **0 rows dropped** — coverage is 100% (4,295,584 / 4,295,584) |
| R3 | Revenue taken only from `purchase` events via `ecommerce.purchase_revenue_in_usd` | Prevents double-counting across event types |
| R4 | Funnel steps modelled as session-scoped booleans (non-strict ordering) | Standard GA4 approach; stated in BRD §4 |
| R5 | Dimensions resolved with `ANY_VALUE()` within a session | Device/geo are stable within a session |

## 3. Findings

### 3.1 `ga_session_id` has perfect coverage
All 4,295,584 events carry a `ga_session_id`. No events were lost building the session
table — an unusually clean result, and worth verifying rather than assuming.

### 3.2 Attribution coverage is 73.5%, and the gap is systematic — not random

| Bucket | Sessions | Share | CVR | Revenue/session |
|---|---|---|---|---|
| Has `source` | 264,811 | 73.5% | **1.830%** | $1.368 |
| Missing `source` | 95,318 | 26.5% | **0.001%** | $0.000 |

Sessions lacking session-scoped `source`/`medium` produce effectively **zero conversions
and zero revenue** (~1 converting session out of 95,318).

**Decision:** exclude these sessions from *channel and attribution* analysis. This is safe
because they carry no revenue to misattribute. They remain in totals and funnel analysis.

**Consequence for reporting:** two conversion rates must be quoted and distinguished —
- **Blended CVR: 1.346%** (all sessions)
- **Attributable CVR: 1.830%** (sessions with a known source)

A 36% relative difference between them, so the choice of denominator is material.

**Interpretation:** a live site would not see 95K sessions convert at exactly zero purely
because a parameter is absent. This is almost certainly an artifact of Google's
obfuscation of the sample rather than genuine user behaviour, and is treated as such.

### 3.3 5,272 sessions have no `session_start` event
Sessions built: 360,129. Sessions with a `session_start` event: 354,857.
The 5,272 difference (1.46%) is consistent with sessions spanning midnight across daily
table boundaries. Immaterial; funnel step 1 uses `reached_session_start`, so these
sessions are correctly excluded from the top of the funnel.

### 3.4 `begin_checkout` and `add_shipping_info` are near-identical
At user level: 9,715 vs 9,714 users — a difference of one. Effectively every session that
begins checkout also submits shipping information.

**Decision:** treat these as a single funnel stage in reporting, and note that the checkout
flow either forces shipping entry or the two events fire together. Keeping them separate
would imply a decision point that does not exist.

## 4. Known limitations

| # | Limitation | Handling |
|---|---|---|
| L1 | Dataset is obfuscated with placeholder values | All figures reported as rates; stated in README and BRD |
| L2 | No ad spend data | CAC modelled from stated benchmarks, flagged as assumption |
| L3 | `user_pseudo_id` is device-scoped | Cohort retention is approximate and labelled as such |
| L4 | 3-month window | No seasonality or year-over-year analysis attempted |
| L5 | 26.5% of sessions lack attribution source | Excluded from channel analysis — see §3.2 |
