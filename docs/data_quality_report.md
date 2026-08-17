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

### 3.5 Self-referral inflates last-touch revenue by 63%

| Last-touch source | Sessions | Revenue | % of total revenue |
|---|---|---|---|
| `shop.googlemerchandisestore.com` | 104,977 | $217,803 | 60.1% |
| `googlemerchandisestore.com` | 7,251 | $10,076 | 2.8% |
| **Combined** | **112,228** | **$227,879** | **62.9%** |

Both are the store's **own domains** appearing as an external referral source — a
cross-domain tracking artifact, typically caused by a payment-gateway redirect or a
subdomain hop that breaks session continuity. It is not an acquisition channel.

**Decision:** bucket as `Self-referral (artifact)` and exclude from all channel and
budget analysis. Retained in totals so revenue still reconciles to $362,165.

**Why this matters:** left uncorrected, 42% of attributable sessions and 63% of revenue
would be credited to a non-existent channel, making every downstream budget
recommendation invalid.

### 3.6 Internal traffic present

`analytics.google.com` contributed 2,982 sessions, 1 purchase and **$0 revenue** — users
browsing the Google Analytics demo account rather than shopping. Bucketed as `Internal`
and excluded from channel analysis.

### 3.7 Attribution model materially changes channel ranking

After excluding the artifacts above:

| Channel | First-touch revenue | Last-touch revenue | Last-touch effect | FT rev/session |
|---|---|---|---|---|
| Organic Search | $104,007 | $53,518 | −48.5% | $0.847 |
| Direct | $79,650 | $12,190 | −84.7% | $0.954 |
| Referral | $37,000 | $52,756 | **+42.6%** | $1.067 |
| Paid Search | $9,056 | $1,982 | −78.1% | $0.580 |

Both models reconcile exactly: first-touch sessions sum to 360,129 and revenue to
$362,165; last-touch covers the 264,811 attributable sessions.

**Rank reordering (genuine channels only, share of attributable revenue):**

| Rank | First-touch | Share | Last-touch | Share |
|---|---|---|---|---|
| 1 | Organic Search | 45.3% | Organic Search | 44.4% |
| 2 | Direct | 34.7% | Referral | 43.8% |
| 3 | Referral | 16.1% | Direct | 10.1% |
| 4 | Paid Search | 3.9% | Paid Search | 1.7% |

Referral moves from 3rd to a near-tie for 1st; Direct falls from 2nd to 3rd. The model
choice changes the ranking, not merely the magnitudes.

**Recommendation nuance.** Last-touch understates Paid Search by 78.1%, so the channel is
measured unfairly. But on first-touch revenue per session it is still the weakest genuine
channel at $0.580 — 42% below the $1.006 site average. The correct action is to fix the
measurement before changing the budget; this is a measurement problem *and* a performance
problem, and they should not be conflated.

### 3.8 Roughly 24% of revenue cannot be attributed to a real channel

The `Redacted` bucket carries $50,461 (13.9% of revenue) at $2.23 per session — the
highest efficiency of any bucket, and unresolvable. With `Other / obfuscated` ($35,470,
9.8%), about 24% of revenue sits in buckets Google's obfuscation makes unrecoverable.
This caps the precision of any channel-level conclusion and is stated wherever channel
shares are quoted.

## 4. Known limitations

| # | Limitation | Handling |
|---|---|---|
| L1 | Dataset is obfuscated with placeholder values | All figures reported as rates; stated in README and BRD |
| L2 | No ad spend data | CAC modelled from stated benchmarks, flagged as assumption |
| L3 | `user_pseudo_id` is device-scoped | Cohort retention is approximate and labelled as such |
| L4 | 3-month window | No seasonality or year-over-year analysis attempted |
| L6 | Window falls in peak-COVID e-commerce (Nov 2020 – Jan 2021) | Online retail behaviour was atypical: inflated traffic, unusual conversion patterns, disrupted fulfilment. Absolute rates should not be read as a steady-state benchmark; the funnel *shape* and the analytical method are the transferable output. |
| L5 | 26.5% of sessions lack attribution source | Excluded from channel analysis — see §3.2 |
