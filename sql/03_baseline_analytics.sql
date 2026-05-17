-- =========================================================
-- RETAIL MARKET PERFORMANCE ANALYSIS
-- PART 3: BASELINE MACRO PERFORMANCE & REGIONAL ANALYSIS
-- Sections 1 — 6 (Includes Original Operational Insights)
-- =========================================================

-- =========================================================
-- SECTION 1 — YEAR-OVER-YEAR SUMMARY .
-- =========================================================

-- Q1: How did 2024 and 2025 compare at the top level?
SELECT
    d.year,
    COUNT(*)                                                                   AS total_orders,
    SUM(s.quantity)                                                            AS total_units,
    ROUND(SUM(s.net_revenue), 2)                                               AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                    AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)           AS margin_pct,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2) AS blended_discount_pct,
    ROUND(SUM(s.net_revenue) / NULLIF(COUNT(*), 0), 2)                        AS avg_order_value
FROM silver.fact_sales AS s
JOIN silver.dim_date   AS d ON s.order_date = d.date
GROUP BY d.year
ORDER BY d.year;
-- ► 2024: $11.03M revenue, 23.85% margin, 4.46% blended discount rate — a solid baseline.
--   2025: $10.56M revenue, 20.86% margin, 7.55% blended discount rate.
--   Revenue fell 4.3% YoY while profit fell 16.3% and margin compressed 3pp.


-- Q2: How did each category perform YoY?
SELECT
    p.category,
    d.year,
    ROUND(SUM(s.net_revenue), 2)                                                  AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                       AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)               AS margin_pct,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2)    AS discount_pct
FROM silver.fact_sales   AS s
JOIN silver.dim_products AS p ON s.product_id = p.product_id
JOIN silver.dim_date     AS d ON s.order_date = d.date
GROUP BY p.category, d.year
ORDER BY p.category, d.year;
-- ► Electronics: margin fell from 14.7% (2024) to 9.11% (2025) as discount rate rose
--   from 5.6% to 10.7% — the entire YoY story is in this one category.
--   Grocery, Household, and Personal Care margins were essentially flat year-over-year,
--   confirming the problem is Electronics-specific, not a company-wide cost issue.
--   Personal Care stood out as the most resilient category: 44%+ margin both years,
--   lowest discount rate (2.57%), the strongest margin floor in the portfolio.


-- Q3: What was the quarterly revenue and margin trajectory across both years?
SELECT
    d.year,
    d.quarter,
    ROUND(SUM(s.net_revenue), 2)                                                      AS quarterly_revenue,
    ROUND(SUM(s.profit), 2)                                                           AS quarterly_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)                  AS margin_pct,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2)       AS discount_pct
FROM silver.fact_sales AS s
JOIN silver.dim_date   AS d ON s.order_date = d.date
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;
-- ► Q1–Q3 2024 held at ~25% margin with a 3.1% discount rate — the business in its
--   normal operating state. Q4 2024 saw the first discount spike (7.7% rate, margin
--   dropped to 21%) before recovering cleanly in Q1 2025. This establishes Q4 2024
--   as an earlier instance of the same pattern that became severe in H2 2025 —
--   the H2 2025 collapse was an escalation of a recurring seasonal tendency,
--   not an isolated policy failure.


-- =========================================================
-- SECTION 2 — OVERALL BUSINESS PERFORMANCE
-- =========================================================

-- Q1: What are the total revenue, profit, orders, and quantity sold?
SELECT
    ROUND(SUM(net_revenue), 2)                                                       AS total_revenue,
    ROUND(SUM(profit), 2)                                                            AS total_profit,
    ROUND(SUM(profit) / NULLIF(SUM(net_revenue), 0) * 100, 2)                        AS margin_pct,
    COUNT(*)                                                                         AS total_orders,
    SUM(quantity)                                                                    AS total_units_sold
FROM silver.fact_sales;
-- ► Revenue: $21.6M | Profit: $4.83M | Margin: 22.38% | Orders: 369,173 | Units: 842,451.
--   The blended margin of 22.38% is pulled down by Electronics (11.78% margin, 59% of revenue).
--   Strip Electronics out and the rest of the business runs at ~35% margin — the headline
--   number understates the underlying health of the non-Electronics portfolio.


-- Q2: How did monthly revenue and profit trend over time?
WITH monthly_metrics AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE AS month_start,
        SUM(net_revenue)                      AS monthly_revenue,
        SUM(profit)                           AS monthly_profit
    FROM silver.fact_sales
    GROUP BY 1
)
SELECT
    month_start,
    ROUND(monthly_revenue, 2)                                         AS monthly_revenue,
    ROUND(monthly_profit, 2)                                          AS monthly_profit,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month_start), 2)        AS running_revenue,
    ROUND(LAG(monthly_revenue) OVER (ORDER BY month_start), 2)        AS prev_month_revenue,
    ROUND(SUM(monthly_profit) OVER (ORDER BY month_start), 2)         AS running_profit,
    ROUND(LAG(monthly_profit) OVER (ORDER BY month_start), 2)         AS prev_month_profit
FROM monthly_metrics
ORDER BY month_start;
-- ► Revenue held broadly between $780K–$1.06M per month throughout the period,
--   with seasonal peaks in Nov–Dec of both years.
--   Profit declined sharply starting July 2025 despite flat-to-positive revenue —
--   a margin compression problem, not a volume problem.
--   The distinction matters: the fix is pricing policy, not a sales or marketing campaign.
--   Note: a smaller margin dip also appeared in Nov–Dec 2024 (see Section 2 Q3 and
--   Section 0 Q3), establishing a seasonal discount escalation pattern before H2 2025.


-- Q3: Did the business decline in H2 2025, and by how much?
WITH revenue_by_half AS (
    SELECT
        CASE WHEN d.quarter IN ('Q1','Q2') THEN 'H1' ELSE 'H2' END AS half_year,
        SUM(s.net_revenue)                                           AS total_revenue,
        SUM(s.profit)                                                AS total_profit
    FROM silver.fact_sales AS s
    JOIN silver.dim_date   AS d ON s.order_date = d.date
    WHERE d.year = 2025
    GROUP BY 1
)
SELECT
    ROUND(SUM(CASE WHEN half_year = 'H1' THEN total_revenue END), 2)    AS h1_revenue,
    ROUND(SUM(CASE WHEN half_year = 'H2' THEN total_revenue END), 2)    AS h2_revenue,
    ROUND(
        SUM(CASE WHEN half_year = 'H2' THEN total_revenue END)
        - SUM(CASE WHEN half_year = 'H1' THEN total_revenue END), 2
    )                                                                   AS revenue_difference,
    ROUND(SUM(CASE WHEN half_year = 'H1' THEN total_profit END), 2)     AS h1_profit,
    ROUND(SUM(CASE WHEN half_year = 'H2' THEN total_profit END), 2)     AS h2_profit,
    ROUND(
        (SUM(CASE WHEN half_year = 'H2' THEN total_profit END)
         - SUM(CASE WHEN half_year = 'H1' THEN total_profit END))
        * 100.0 / NULLIF(SUM(CASE WHEN half_year = 'H1' THEN total_profit END), 0), 2
    )                                                                   AS profit_change_pct
FROM revenue_by_half;
-- ► H2 revenue: $4.97M vs H1: $5.58M — a 10.9% revenue decline.
--   H2 profit: $824,853 vs H1: $1,377,066 — a 40.1% profit decline.
--   A 10.9% revenue drop producing a 40.1% profit decline is only possible if
--   discount depth changed dramatically. Section 2 and Section 8 provide the full
--   mechanism: the Electronics discount rate jumped from 4.36% to 17.22% in H2.


-- Q4: How did profit margin change month over month?
WITH monthly_margin AS (
    SELECT
        DATE_TRUNC('month', order_date)::DATE              AS month_start,
        SUM(profit) * 100.0 / NULLIF(SUM(net_revenue), 0) AS profit_margin_pct
    FROM silver.fact_sales
    GROUP BY 1
)
SELECT
    month_start,
    ROUND(profit_margin_pct, 2)                                           AS profit_margin_pct,
    ROUND(
        profit_margin_pct - LAG(profit_margin_pct) OVER (ORDER BY month_start),
        2
    )                                                                     AS mom_change
FROM monthly_margin
ORDER BY month_start;
-- ► Margin was broadly stable (±0.50pp MoM) from Jan 2024 through Oct 2024.
--   November 2024 saw the first anomaly: margin dropped ~5.8pp as discount depth spiked
--   to ~9.6% (vs the 3.1% seen throughout the rest of 2024). This recovered in Jan 2025.
--   July 2025 brought the second, larger break: margin dropped ~5.9pp in a single month
--   and never recovered, deteriorating further through Q4 2025.
--   The Nov 2024 episode and the July 2025 collapse share the same fingerprint —
--   a sudden, broad Electronics discount spike — but the 2025 version was four times
--   deeper and lasted six months instead of two.


-- =========================================================
-- SECTION 3 — DISCOUNTS AND PROFITABILITY
-- =========================================================

-- Q1: What is the total discount amount, and which categories drive it?
SELECT
    p.category,
    ROUND(SUM(s.discount_amount), 2)                                                AS total_discount,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2)     AS discount_pct,
    ROUND(SUM(s.profit)          * 100.0 / NULLIF(SUM(s.net_revenue),   0), 2)     AS profit_margin_pct
FROM silver.fact_sales    AS s
JOIN silver.dim_products  AS p ON s.product_id = p.product_id
GROUP BY p.category
ORDER BY discount_pct DESC;
-- ► Total discounts: $1.38M. Electronics accounts for $1.14M at an 8.22% blended rate —
--   every other category sits between 2.59–2.63%. This is not a company-wide discounting
--   problem; it is Electronics-specific. Section 8 establishes that Electronics discounting
--   is strategically justified as a loss-leader — 97%+ of Electronics buyers also purchase
--   high-margin categories. The issue is the ceiling, not the existence of the discount.
--   The H2 spike to ~17% (Section 8 Q6) is what broke the model.
--   Personal Care is the standout: 44.13% margin on a 2.63% discount rate — the most
--   margin-efficient category in the portfolio and a benchmark for what disciplined
--   pricing looks like across the board.


-- Q2: Which subcategories carry the highest discount burden?
SELECT
    p.subcategory,
    ROUND(SUM(s.discount_amount), 2)                                                AS total_discount,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2)     AS discount_pct
FROM silver.fact_sales   AS s
JOIN silver.dim_products AS p ON s.product_id = p.product_id
GROUP BY p.subcategory
ORDER BY discount_pct DESC;
-- ► Accessories (8.26%), Audio (8.25%), and Phones (8.16%) are the top three —
--   all Electronics subcategories. Every other subcategory sits below 2.70%.
--   The blended Electronics rate of ~8% across the full period is within a range the
--   cross-category profit can support. The H2 spike to ~17% per subcategory
--   (confirmed in Section 8 Q6) is what created the margin collapse.


-- Q3: How did discounting trend over time — including the Q4 2024 anomaly?
SELECT
    d.year,
    d.quarter,
    ROUND(SUM(s.discount_amount), 2)                                                    AS total_discount,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2)         AS blended_discount_pct,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)                    AS margin_pct
FROM silver.fact_sales AS s
JOIN silver.dim_date   AS d ON s.order_date = d.date
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;
-- ► Baseline discount rate: ~3.1% for Q1–Q3 2024 and Q1–Q2 2025.
--   Q4 2024 first anomaly: rate jumped to 7.7%, margin fell to 21.0%.
--   This episode recovered cleanly in Q1 2025 (rate back to 3.2%).
--   Q3 2025: rate rose to 9.6%, margin fell to 18.8%.
--   Q4 2025: rate escalated further to 14.2%, margin collapsed to 14.6%.
--   The pattern is consistent: a seasonal or policy tendency toward Q4 discounting
--   that was manageable in 2024 but became structurally damaging in 2025.
--   The H1/H2 framing (3.17% vs 12.02%) remains accurate as a summary, but the
--   quarterly view reveals the escalation was progressive, not a single switch.


-- Q4: Which customer segments and store types rely most on discounting?
SELECT
    'Segment'    AS dimension,
    c.segment    AS LABEL,
    ROUND(SUM(s.discount_amount) * 100.0
        / NULLIF(SUM(s.gross_revenue), 0), 2)   AS discount_pct
FROM silver.fact_sales    AS s
JOIN silver.dim_customers AS c ON s.customer_id = c.customer_id
GROUP BY c.segment

UNION ALL

SELECT
    'Store Type'   AS dimension,
    st.store_type  AS LABEL,
    ROUND(SUM(s.discount_amount) * 100.0
        / NULLIF(SUM(s.gross_revenue), 0), 2)   AS discount_pct
FROM silver.fact_sales AS s
JOIN silver.dim_stores AS st ON s.store_id = st.store_id
GROUP BY st.store_type

ORDER BY dimension, discount_pct DESC;
-- ► Budget customers receive a 9.65% discount rate vs 4.70% for Premium — the inverse
--   of sound commercial logic. This is largely a consequence of mix: Budget customers
--   index higher on Electronics purchases, where the elevated discount rate applies.
--   It is not necessarily a deliberate segment-level policy, but the effect is the same:
--   the segment with the lowest average order value receives the deepest discounts.
--   Recommended: tie Premium discounts to cross-category basket value as a loyalty lever,
--   and restrict Budget discounts to specific clearance events.
--   Online Fulfillment (STORE_012) carries the highest store-type discount rate (7.94%)
--   with no margin advantage over physical stores — the discounts are not converting
--   into better channel economics, only into lower revenue per transaction.


-- =========================================================
-- SECTION 4 — PRODUCT PERFORMANCE
-- =========================================================

-- Q1: Which categories generate the most revenue, profit, and volume?
SELECT
    p.category,
    ROUND(SUM(s.net_revenue), 2)                                              AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                   AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)          AS margin_pct,
    SUM(s.quantity)                                                           AS total_units_sold
FROM silver.dim_products AS p
JOIN silver.fact_sales   AS s ON p.product_id = s.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;
-- ► Electronics leads on revenue ($12.7M) and profit ($1.5M) in absolute terms but has
--   the lowest margin (11.78%). Its commercial role is as a traffic and basket driver,
--   validated in Section 8.
--   Grocery dominates volume (520,490 units) with a 31% margin — workmanlike but not
--   the margin engine.
--   Personal Care is the most margin-efficient category at 44.13% on $2.48M revenue —
--   the highest margin in the portfolio, the lowest discount rate (2.63%), and consistent
--   performance across both years. It is the benchmark for what disciplined pricing
--   looks like and a strong candidate for premium placement and expanded SKU depth.
--   These are structurally different business models — pricing, promotions, and inventory
--   decisions must be managed separately for each category.


-- Q2: What are the top 10 products by revenue, and where do margins fall?
SELECT
    p.product_name,
    ROUND(SUM(s.net_revenue), 2)                                                  AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                       AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)              AS profit_margin_pct
FROM silver.dim_products AS p
JOIN silver.fact_sales   AS s ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;
-- ► The top 10 by revenue are entirely Electronics — Voltix, SoundArc, HomeWave, NovaTech.
--   Revenue rank does not equal value rank here. NovaTech products carry meaningfully
--   higher margins than Voltix equivalents, making NovaTech the brand to protect from
--   discount pressure. Voltix's position should be evaluated product by product using the
--   basket attachment rate from Section 8 Q5 — products with high attachment have a
--   loss-leader justification; products with low attachment and low margin do not.


-- Q3: Which products have high volume but dangerously low margin?
SELECT
    p.product_name,
    SUM(s.quantity)                                                                AS total_units_sold,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)              AS profit_margin_pct
FROM silver.dim_products AS p
JOIN silver.fact_sales   AS s ON p.product_id = s.product_id
GROUP BY p.product_name
HAVING SUM(s.quantity) > 100
   AND SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0) < 10
ORDER BY profit_margin_pct ASC
LIMIT 5;
-- ► Voltix Phones Item 628: −0.45% margin (the only product with a negative total profit).
--   Voltix Accessories Item 642: 0.22%. Voltix Audio Item 697: 0.30%.
--   All three are Voltix — a brand-level pricing problem within Electronics.
--   Cross-reference with Section 8 Q5 basket attachment rates: if these products show
--   high attachment they pull cross-category purchases and a pricing floor review is
--   sufficient. If attachment is low, there is no commercial justification for the
--   current pricing and discontinuation should be evaluated.


-- Q4: Which brands perform best by revenue and profit margin?
SELECT
    p.brand,
    ROUND(SUM(s.net_revenue), 2)                                                  AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                       AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)              AS profit_margin_pct
FROM silver.dim_products AS p
JOIN silver.fact_sales   AS s ON p.product_id = s.product_id
GROUP BY p.brand
ORDER BY total_revenue DESC;
-- ► NovaTech leads on revenue ($3.89M) with meaningfully better margins than Voltix.
--   Non-Electronics brands (UrbanFarm, CleanNest, CarePlus, etc.) run at 29–43% margin.
--   NovaTech is the priority brand to protect from discount escalation — it generates
--   both scale and profitability, a combination no other Electronics brand achieves.


-- =========================================================
-- SECTION 5 — CUSTOMER ANALYSIS
-- =========================================================

-- Q1: Which customer segments generate the most revenue — are Premium customers
--     actually more profitable?
WITH segment_metrics AS (
    SELECT
        c.segment,
        SUM(s.net_revenue)            AS total_revenue,
        SUM(s.profit)                 AS total_profit,
        AVG(s.net_revenue)            AS avg_order_value,
        COUNT(DISTINCT c.customer_id) AS total_customers
    FROM silver.dim_customers AS c
    JOIN silver.fact_sales    AS s ON c.customer_id = s.customer_id
    GROUP BY c.segment
)
SELECT
    segment,
    ROUND(total_revenue, 2)                                      AS total_revenue,
    ROUND(total_profit, 2)                                       AS total_profit,
    ROUND(avg_order_value, 2)                                    AS avg_order_value,
    ROUND(total_profit / NULLIF(total_customers, 0), 2)          AS avg_profit_per_customer
FROM segment_metrics
ORDER BY total_revenue DESC;
-- ► Regular customers generate the most total revenue and profit by volume.
--   Premium customers have the highest avg order value ($62) but lower avg profit per
--   customer ($117.61) than Budget customers ($149.05). Excessive discounting on
--   Electronics transactions is eroding the Premium segment's financial advantage.
--   Recommended: restrict Electronics discount stacking for Premium customers —
--   retain Premium benefits on Personal Care and Household where margins support it.


-- Q2: Which acquisition channels bring the most customers and highest value per customer?
SELECT
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id)                                                    AS total_customers,
    ROUND(SUM(s.net_revenue), 2)                                                     AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                          AS total_profit,
    ROUND(SUM(s.net_revenue) / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2)        AS revenue_per_customer,
    ROUND(SUM(s.profit)      / NULLIF(COUNT(DISTINCT c.customer_id), 0), 2)        AS profit_per_customer
FROM silver.dim_customers AS c
JOIN silver.fact_sales    AS s ON c.customer_id = s.customer_id
GROUP BY c.acquisition_channel
ORDER BY total_revenue DESC;
-- ► Store (in-store sign-up) dominates through volume (10,465 customers), not buyer
--   quality. Per-customer revenue and profit is nearly identical across all channels.
--   Referral stands out: only 2,015 customers, comparable per-customer profit,
--   and near-zero acquisition cost. It is almost certainly the lowest-CAC channel
--   in the business and currently the smallest by volume — a significant untapped lever.


-- Q3: Which age groups generate the most revenue and profit?
SELECT
    CASE
        WHEN c.age BETWEEN 18 AND 24 THEN '18–24 Youth'
        WHEN c.age BETWEEN 25 AND 34 THEN '25–34 Early Adult'
        WHEN c.age BETWEEN 35 AND 44 THEN '35–44 Mid Adult'
        WHEN c.age BETWEEN 45 AND 54 THEN '45–54 Mature Adult'
        WHEN c.age BETWEEN 55 AND 64 THEN '55–64 Pre-Senior'
        WHEN c.age BETWEEN 65 AND 69 THEN '65–69 Senior'
        ELSE 'Other'
    END                               AS age_group,
    ROUND(SUM(s.net_revenue), 2)      AS total_revenue,
    ROUND(SUM(s.profit), 2)           AS total_profit
FROM silver.dim_customers AS c
JOIN silver.fact_sales    AS s ON c.customer_id = s.customer_id
GROUP BY age_group
ORDER BY total_revenue DESC;
-- ► The 25–64 band drives the overwhelming majority of revenue and profit.
--   The Senior segment (65–69) is small despite likely higher disposable income —
--   the portfolio is Electronics-heavy and increasingly online-oriented, both of which
--   skew toward younger buyers. Growing the Senior segment would require a different
--   product emphasis (Personal Care, Household) and stronger in-store experience.


-- Q4: Which customer segments have the highest return rate?
WITH segment_returns AS (
    SELECT c.segment, SUM(r.returned_qty) AS returned_qty
    FROM silver.fact_returns  AS r
    JOIN silver.dim_customers AS c ON r.customer_id = c.customer_id
    GROUP BY c.segment
),
segment_sales AS (
    SELECT c.segment, SUM(s.quantity) AS sold_qty
    FROM silver.fact_sales    AS s
    JOIN silver.dim_customers AS c ON s.customer_id = c.customer_id
    GROUP BY c.segment
)
SELECT
    ss.segment,
    ROUND(sr.returned_qty * 100.0 / NULLIF(ss.sold_qty, 0), 2) AS return_rate_pct
FROM segment_sales     AS ss
JOIN segment_returns   AS sr ON ss.segment = sr.segment
ORDER BY return_rate_pct DESC;
-- ► Return rates are virtually uniform across all segments: 2.51%–2.61%.
--   The problem is not who is returning but what and why. Electronics' 4.3% return
--   rate (Section 6 Q1) and $228K in discretionary "Not Needed" refunds (Section 6 Q2)
--   identify the specific product and reason combination to address first.


-- =========================================================
-- SECTION 6 — STORE AND REGIONAL ANALYSIS
-- =========================================================

-- Q1: Which stores are the top and bottom performers by revenue and profit?
WITH store_perf AS (
    SELECT
        st.store_code,
        ROUND(SUM(s.net_revenue), 2)                           AS total_revenue,
        ROUND(SUM(s.profit), 2)                                AS total_profit,
        RANK() OVER (ORDER BY SUM(s.net_revenue) DESC)         AS rev_rank,
        RANK() OVER (ORDER BY SUM(s.net_revenue) ASC)          AS rev_rank_asc,
        RANK() OVER (ORDER BY SUM(s.profit) DESC)              AS profit_rank,
        RANK() OVER (ORDER BY SUM(s.profit) ASC)               AS profit_rank_asc
    FROM silver.dim_stores AS st
    JOIN silver.fact_sales AS s ON st.store_id = s.store_id
    GROUP BY st.store_code
)
SELECT
    store_code,
    total_revenue,
    total_profit,
    CASE
        WHEN rev_rank = 1        THEN 'Top Revenue'
        WHEN rev_rank_asc = 1    THEN 'Bottom Revenue'
        WHEN profit_rank = 1     THEN 'Top Profit'
        WHEN profit_rank_asc = 1 THEN 'Bottom Profit'
    END AS LABEL
FROM store_perf
WHERE rev_rank = 1 OR rev_rank_asc = 1
   OR profit_rank = 1 OR profit_rank_asc = 1
ORDER BY total_revenue DESC;
-- ► STORE_029 (Cairo Hypermarket) leads on revenue ($932K, 22.6% margin).
--   STORE_012 is the weakest at $373K. It is the only Online Fulfillment store —
--   the low revenue is partly structural for the format. The real concern is its
--   discount rate (7.94%, highest of any store) producing no margin advantage:
--   20.64% margin vs 22.4% company average. The discounts are not converting into
--   better economics; they are simply eroding revenue per transaction.
--   Recommended action: reduce STORE_012 discount authority to match the physical
--   store average and monitor whether order volume holds.


-- Q2: How do regions compare on revenue and margin year over year?
SELECT
    st.region,
    d.year,
    ROUND(SUM(s.net_revenue), 2)                                             AS total_revenue,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)         AS profit_margin_pct
FROM silver.fact_sales  AS s
JOIN silver.dim_stores  AS st ON s.store_id  = st.store_id
JOIN silver.dim_date    AS d  ON s.order_date = d.date
GROUP BY st.region, d.year
ORDER BY st.region, d.year;
-- ► All regions operate at nearly identical margins (~22%). The H2 2025 decline was
--   uniform across all geographies — every region lost roughly 2pp of margin.
--   A uniform cross-regional decline rules out a local execution failure and confirms
--   this was a centrally applied pricing policy change. Central leads on revenue;
--   East is the weakest region.


-- Q3: How do store types compare in revenue, margin, and discount reliance?
SELECT
    st.store_type,
    CASE
        WHEN st.size_sqm = 0    THEN 'Online'
        WHEN st.size_sqm < 1000 THEN 'Small'
        WHEN st.size_sqm < 3000 THEN 'Medium'
        ELSE 'Large'
    END                                                                     AS store_size_group,
    ROUND(SUM(s.net_revenue), 2)                                             AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                  AS total_profit,
    ROUND(SUM(s.profit)          * 100.0 / NULLIF(SUM(s.net_revenue),   0), 2) AS profit_margin_pct,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2) AS discount_pct
FROM silver.dim_stores AS st
JOIN silver.fact_sales AS s ON st.store_id = s.store_id
GROUP BY st.store_type, store_size_group
ORDER BY total_revenue DESC;
-- ► Online Fulfillment (STORE_012) carries the highest discount rate (7.94%) with a
--   margin below the company average — the discounts are not creating an economic
--   advantage, only eroding revenue per transaction.
--   Hypermarkets dominate revenue and profit in absolute terms, confirming format
--   matters: the top 8 stores by revenue are all Hypermarkets.


-- Q4: Which cities generate the most revenue and profit?
SELECT
    st.city,
    ROUND(SUM(s.net_revenue), 2) AS total_revenue,
    ROUND(SUM(s.profit), 2)      AS total_profit
FROM silver.dim_stores AS st
JOIN silver.fact_sales AS s ON st.store_id = s.store_id
GROUP BY st.city
ORDER BY total_revenue DESC;
-- ► Dubai ($2.72M, $610K profit) and Cairo ($2.5M+) are the two highest-efficiency
--   markets — strong revenue combined with above-average margin quality.
--   Priority markets for new store investment, category expansion trials, and
--   premium product placement.


-- Q5: How do the four countries compare on revenue, margin, and order volume?  [NEW]
SELECT
    st.country,
    COUNT(*)                                                                   AS total_orders,
    ROUND(SUM(s.net_revenue), 2)                                               AS total_revenue,
    ROUND(SUM(s.profit), 2)                                                    AS total_profit,
    ROUND(SUM(s.profit) * 100.0 / NULLIF(SUM(s.net_revenue), 0), 2)           AS profit_margin_pct,
    ROUND(SUM(s.discount_amount) * 100.0 / NULLIF(SUM(s.gross_revenue), 0), 2) AS discount_pct
FROM silver.fact_sales  AS s
JOIN silver.dim_stores  AS st ON s.store_id = st.store_id
GROUP BY st.country
ORDER BY total_revenue DESC;
-- ► All four countries operate at nearly identical margins (22.3–22.5%),
--   confirming the discount policy is applied centrally rather than country-by-country.
--   Jordan leads on order volume (102,623 orders) driven by the largest number of stores
--   in the dataset (10 stores). Egypt leads on revenue per store given its Hypermarket
--   concentration (4 of 8 Hypermarkets are in Egypt).
--   The margin uniformity across markets means no country is underperforming — any
--   margin improvement from a discount ceiling will lift all four countries equally.
