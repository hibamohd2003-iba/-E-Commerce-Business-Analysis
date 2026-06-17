-- ============================================================================
-- FINANCIAL ANALYSIS
-- File: 06_financial_analysis.sql
-- Description: 8 queries analyzing revenue, profitability, margins, and ROI
-- Database: E-Commerce (99,441 orders, Sep 2016 - Oct 2018)
-- ============================================================================

-- Query 5.1: Revenue Breakdown (Product vs Freight)
-- Purpose: Understand revenue composition — product vs shipping
-- Key Insight: 85.79% product revenue, 14.21% freight revenue
SELECT
    'Product Revenue' as category,
    ROUND(SUM(oi.price), 2) as amount,
    ROUND(100.0 * SUM(oi.price) / (SELECT SUM(oi2.price) + SUM(oi2.freight_value)
        FROM olist_order_items oi2), 2) as percentage
FROM olist_order_items oi
UNION ALL
SELECT
    'Freight Revenue',
    ROUND(SUM(oi.freight_value), 2),
    ROUND(100.0 * SUM(oi.freight_value) / (SELECT SUM(oi2.price) + SUM(oi2.freight_value)
        FROM olist_order_items oi2), 2)
FROM olist_order_items oi;

-- Query 5.2: Monthly Profitability
-- Purpose: Track monthly revenue, costs, and net profit margins
-- Key Insight: Margin declining from 85.25% (2016) → 81.77% (Jul 2018)
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) as month,
    COUNT(*) as orders,
    ROUND(SUM(oi.price), 2) as gross_revenue,
    ROUND(SUM(oi.freight_value), 2) as shipping_costs,
    ROUND(SUM(oi.price) - SUM(oi.freight_value), 2) as net_profit,
    ROUND(100.0 * (SUM(oi.price) - SUM(oi.freight_value)) / SUM(oi.price), 2) as profit_margin
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY month;

-- Query 5.3: Customer Value vs Cost
-- Purpose: Overall profit per customer baseline
-- Key Insight: R$114.93 profit per customer — could be 2-3x with retention
SELECT
    'Segment Analysis' as metric,
    COUNT(DISTINCT o.customer_id) as customers,
    ROUND(SUM(oi.price), 2) as total_revenue,
    ROUND(SUM(oi.freight_value), 2) as total_costs,
    ROUND(SUM(oi.price) - SUM(oi.freight_value), 2) as total_profit,
    ROUND(AVG(oi.price), 2) as avg_order_value,
    ROUND((SUM(oi.price) - SUM(oi.freight_value)) / COUNT(DISTINCT o.customer_id), 2) as profit_per_customer
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id;

-- Query 5.4: Break Even Analysis by Region
-- Purpose: Identify profitable vs loss-making states
-- Key Insight: ALL 27 states are profitable; SP = R$4.48M profit (39% of total)
SELECT
    c.customer_state,
    COUNT(*) as orders,
    ROUND(SUM(oi.price), 2) as revenue,
    ROUND(SUM(oi.freight_value), 2) as costs,
    ROUND(SUM(oi.price) - SUM(oi.freight_value), 2) as profit,
    CASE
        WHEN SUM(oi.price) > SUM(oi.freight_value) THEN 'Profitable'
        ELSE 'Loss-Making'
    END as status
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY profit DESC;

-- Query 5.5: Margin Trend Over Time
-- Purpose: Track erosion of profit margins month by month
-- Key Insight: 3.65% margin erosion = ~R$547K lost profit on R$15M revenue
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) as month,
    ROUND(SUM(oi.price), 2) as revenue,
    ROUND(SUM(oi.freight_value), 2) as costs,
    ROUND(100.0 * (SUM(oi.price) - SUM(oi.freight_value)) / SUM(oi.price), 2) as margin_percentage,
    ROUND(AVG(100.0 * (oi.price - oi.freight_value) / oi.price), 2) as avg_order_margin
FROM olist_orders o
JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY month;

-- Query 5.6: High Value Order Concentration
-- Purpose: Identify revenue concentration by order size (Pareto analysis)
-- Key Insight: Top 10% orders (Premium 300+) = 38.85% of total revenue
SELECT
    CASE
        WHEN order_total >= 300 THEN 'Premium (300+)'
        WHEN order_total >= 150 THEN 'High (150-300)'
        WHEN order_total >= 75  THEN 'Medium (75-150)'
        ELSE 'Low (0-75)'
    END as order_segment,
    COUNT(*) as orders,
    ROUND(SUM(order_total), 2) as revenue,
    ROUND(100.0 * SUM(order_total) / (SELECT SUM(oi.price + oi.freight_value)
        FROM olist_order_items oi), 2) as revenue_share
FROM (
    SELECT
        o.order_id,
        SUM(oi.price + oi.freight_value) as order_total
    FROM olist_orders o
    JOIN olist_order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_id
) as order_totals
GROUP BY order_segment
ORDER BY revenue DESC;

-- Query 5.7: Refund / Lost Revenue Impact
-- Purpose: Quantify revenue lost to cancellations, unavailable stock, payment issues
-- Key Insight: R$218,701 total lost revenue — R$85K recoverable via better inventory
SELECT
    order_status,
    COUNT(*) as orders,
    ROUND(COUNT(*) * (SELECT AVG(oi.price + oi.freight_value)
        FROM olist_order_items oi), 2) as est_lost_revenue,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM olist_orders), 2) as percentage
FROM olist_orders
WHERE order_status NOT IN ('delivered', 'shipped', 'processing')
GROUP BY order_status
ORDER BY orders DESC;

-- Query 5.8: Payment Installment Impact on Revenue
-- Purpose: Understand how installment options drive higher order values
-- Key Insight: 9+ installment customers spend 3.5x more (R$390 vs R$112)
SELECT
    CASE
        WHEN op.payment_installments = 1               THEN '1 (No Installment)'
        WHEN op.payment_installments BETWEEN 2 AND 4   THEN '2-4 Installments'
        WHEN op.payment_installments BETWEEN 5 AND 8   THEN '5-8 Installments'
        ELSE '9+ Installments'
    END as installment_group,
    COUNT(*) as orders,
    ROUND(AVG(op.payment_value), 2) as avg_order_value,
    ROUND(SUM(op.payment_value), 2) as total_value,
    ROUND(100.0 * SUM(op.payment_value) / (SELECT SUM(payment_value)
        FROM olist_order_payments), 2) as revenue_share
FROM olist_order_payments op
GROUP BY installment_group
ORDER BY total_value DESC;