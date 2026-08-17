# Business Requirements Document
### E-Commerce Growth & Unit Economics Analytics

| | |
|---|---|
| **Author** | Joevita Faustina Doss |
| **Date** | August 2026 |
| **Status** | Draft |
| **Data source** | `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` |
| **Period analysed** | 1 Nov 2020 – 31 Jan 2021 |

---

## 1. Context

The Google Merchandise Store is a direct-to-consumer e-commerce site selling branded
apparel and accessories. Over the analysis window it recorded approximately 2M user
events across roughly 270K sessions, captured in Google Analytics 4 and exported to
BigQuery at event level.

## 2. Problem statement

Traffic is acquired across multiple channels, but the business cannot currently answer
three questions:

1. **Where in the purchase funnel are users lost, and what is that loss worth?**
2. **Which acquisition channels generate profitable revenue rather than just sessions?**
3. **What does next period's revenue look like under different conversion scenarios?**

Channel decisions are currently made on last-touch revenue alone, which systematically
undervalues upper-funnel channels.

## 3. Objectives

| # | Objective | Success criteria |
|---|---|---|
| O1 | Quantify funnel drop-off by step | Conversion and drop-off rate for every step from `view_item` to `purchase` |
| O2 | Compare acquisition channels on quality, not volume | CVR, AOV, and revenue-per-session by channel |
| O3 | Test whether attribution model changes channel ranking | First-touch vs last-touch revenue, side by side |
| O4 | Establish unit economics | Contribution margin and LTV:CAC by channel, assumptions documented |
| O5 | Produce a driver-based revenue forecast | Forecast with sensitivity table and volume/rate/mix variance decomposition |
| O6 | Recommend prioritised experiments | 3 RICE-scored tests, each sized with MDE, sample size and runtime |

## 4. Key metric definitions

| Metric | Definition |
|---|---|
| Session | Distinct `user_pseudo_id` + `ga_session_id` pair |
| Conversion Rate (CVR) | Sessions with a `purchase` event ÷ total sessions |
| AOV | Purchase revenue ÷ number of purchases |
| Revenue per Session | Purchase revenue ÷ total sessions |
| Cart Abandonment Rate | 1 − (sessions reaching `purchase` ÷ sessions reaching `add_to_cart`) |
| First-touch channel | `traffic_source` recorded at user acquisition |
| Last-touch channel | Channel of the session containing the purchase |
| Cohort | Week of a user's first recorded session |
| Contribution Margin | Revenue − COGS − variable fulfilment cost *(assumption-based — see §6)* |

## 5. Scope

**In scope:** funnel diagnostics, channel and attribution analysis, weekly cohort
retention, device and geographic segmentation, unit economics, revenue forecasting with
variance analysis, experiment design and power analysis.

**Out of scope:**
- **Paid media spend is not present in the dataset.** CAC is modelled from stated
  industry benchmarks and flagged as an assumption throughout.
- **Seasonality and year-over-year analysis** — the 3-month window cannot support it.
- **Cross-device identity resolution** — `user_pseudo_id` is device-scoped, so
  retention figures are approximate and stated as such.

## 6. Assumptions

| # | Assumption | Value | Source / rationale |
|---|---|---|---|
| A1 | COGS as % of revenue | TBD | Industry benchmark — to be cited |
| A2 | Variable fulfilment cost per order | TBD | Industry benchmark — to be cited |
| A3 | Blended CAC by channel | TBD | Industry benchmark — to be cited |
| A4 | Cohort retention proxies repeat purchase | — | No customer ID available |

## 7. Data limitations

Google labels this dataset as **obfuscated**, containing placeholder values with limited
internal consistency. All figures are therefore **illustrative of the methodology rather
than actual store performance**. Findings are expressed as rates and percentages rather
than absolute dollar amounts wherever possible.

## 8. Deliverables

- [ ] Cleaned session- and user-level tables (BigQuery + committed extracts)
- [ ] Data quality report
- [ ] Power BI dashboard — star-schema model, 4 pages, 18+ DAX measures
- [ ] Tableau Public executive view (shareable URL)
- [ ] Excel driver-based forecast with sensitivity and variance decomposition
- [ ] Experiment brief with power analysis
- [ ] Insights & recommendations memo
- [ ] Funnel / user journey process map

## 9. Stakeholders

| Role | Interest |
|---|---|
| Head of Growth | Channel efficiency, experiment roadmap |
| Finance / FP&A | Unit economics, forecast accuracy, variance drivers |
| Product | Funnel friction, device experience gaps |
| Merchandising | Product-level view-to-purchase performance |
