-- ============================================================================
-- CUSTOMER ANALYSIS
-- File: 03_customer_analysis.sql
-- Description: 10 queries analyzing customer behavior, retention, and CLV
-- Database: E-Commerce (99,441 orders, Sep 2016 - Oct 2018)
-- ============================================================================

-- Query 2.1: Repeat Purchase Rate
SELECT
 purchase_count,
 COUNT(*) as customers,
 ROUND(100.0 * COUNT(*) / (SELECT COUNT(DISTINCT customer_id) FROM olist_orders), 2) as percentage
FROM (
 SELECT customer_id, COUNT(*) as purchase_count 
 FROM olist_orders 
 GROUP BY customer_id
) as purchase_frequency
GROUP BY purchase_count
ORDER BY purchase_count;

-- Query 2.2: Customer Churn Analysis
SELECT
 CASE
 WHEN days_since_last_order > 365 THEN 'Churned'
 WHEN days_since_last_order > 180 THEN 'At Risk'
 WHEN days_since_last_order > 90 THEN 'Dormant'
 ELSE 'Active'
 END as customer_status,
 COUNT(*) as customers,
 ROUND(AVG(lifetime_value), 2) as avg_clv,
 ROUND(SUM(lifetime_value), 2) as total_value
FROM (
 SELECT
 customer_id,
 SUM(oi.price + oi.freight_value) as lifetime_value,
 CAST(julianday((SELECT MAX(order_purchase_timestamp) FROM olist_orders)) -
 julianday(MAX(order_purchase_timestamp)) AS INTEGER) as days_since_last_order
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY customer_id
) as customer_status_data
GROUP BY customer_status;

-- Query 2.3: Customer Satisfaction Trend
SELECT
 strftime('%Y-%m', o.order_purchase_timestamp) as month,
 ROUND(AVG(rv.review_score), 2) as avg_rating,
 COUNT(*) as reviews,
 COUNT(CASE WHEN rv.review_score >= 4 THEN 1 END) as satisfied,
 COUNT(CASE WHEN rv.review_score <= 2 THEN 1 END) as dissatisfied
FROM olist_orders o
LEFT JOIN olist_order_reviews rv ON o.order_id = rv.order_id
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY month;

-- Query 2.4: Geographic Customer Distribution
SELECT 
 c.customer_state,
 COUNT(DISTINCT c.customer_id) as customers,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value,
 ROUND(AVG(rv.review_score), 2) as avg_satisfaction
FROM olist_customers c
LEFT JOIN olist_orders o ON c.customer_id = o.customer_id
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews rv ON o.order_id = rv.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Query 2.5: High Value Customer Analysis
SELECT
 o.customer_id,
 c.customer_state,
 COUNT(DISTINCT o.order_id) as purchases,
 ROUND(SUM(oi.price + oi.freight_value), 2) as lifetime_value,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value,
 MIN(o.order_purchase_timestamp) as first_purchase,
 MAX(o.order_purchase_timestamp) as last_purchase,
 ROUND(AVG(rv.review_score), 2) as avg_review_score
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews rv ON o.order_id = rv.order_id
GROUP BY o.customer_id
ORDER BY lifetime_value DESC
LIMIT 10;

-- Query 2.6: New vs Returning Customers
SELECT 
 CASE WHEN purchase_count = 1 THEN 'New Customers' 
 ELSE 'Returning Customers' END as customer_type,
 COUNT(*) as customer_count,
 ROUND(AVG(lifetime_value), 2) as avg_clv,
 ROUND(SUM(lifetime_value), 2) as total_revenue
FROM (
 SELECT 
 customer_id,
 COUNT(*) as purchase_count,
 SUM(oi.price + oi.freight_value) as lifetime_value
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY customer_id
) as customer_types
GROUP BY customer_type;

-- Query 2.7: RFM Segmentation
SELECT
 CASE
 WHEN recency <= 90 AND monetary >= 200 THEN 'Champions'
 WHEN monetary >= 200 THEN 'Loyal'
 WHEN recency > 365 THEN 'At Risk'
 ELSE 'Potential'
 END as segment,
 COUNT(*) as customers,
 ROUND(AVG(monetary), 2) as avg_lifetime_value,
 ROUND(AVG(frequency), 2) as avg_purchases,
 ROUND(SUM(monetary), 2) as total_revenue
FROM (
 SELECT
 customer_id,
 COUNT(DISTINCT order_id) as frequency,
 CAST(julianday((SELECT MAX(order_purchase_timestamp) FROM olist_orders)) -
 julianday(MAX(order_purchase_timestamp)) AS INTEGER) as recency,
 SUM(price + freight_value) as monetary
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY customer_id
) as customer_metrics
GROUP BY segment;

-- Query 2.8: CLV Distribution
SELECT
 CASE
 WHEN clv >= 400 THEN 'Premium (High Value)'
 WHEN clv >= 200 THEN 'High (Mid-High)'
 WHEN clv >= 100 THEN 'Medium'
 ELSE 'Low'
 END as clv_segment,
 COUNT(*) as customer_count,
 ROUND(AVG(clv), 2) as avg_clv,
 ROUND(SUM(clv), 2) as segment_revenue,
 ROUND(100.0 * SUM(clv) / (SELECT SUM(oi.price + oi.freight_value)
 FROM olist_order_items oi), 2) as revenue_share
FROM (
 SELECT
 o.customer_id,
 SUM(oi.price + oi.freight_value) as clv 
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY o.customer_id
) as customer_clv
GROUP BY clv_segment
ORDER BY avg_clv DESC;

-- Query 2.9: Cohort Analysis
SELECT
 strftime('%Y-%m', first_purchase) as cohort,
 COUNT(*) as customers,
 ROUND(AVG(lifetime_value), 2) as avg_clv,
 ROUND(AVG(CAST(julianday(last_purchase) - julianday(first_purchase) AS INTEGER)), 0) as avg_lifetime_days
FROM (
 SELECT
 o.customer_id,
 SUM(oi.price + oi.freight_value) as lifetime_value,
 MIN(o.order_purchase_timestamp) as first_purchase,
 MAX(o.order_purchase_timestamp) as last_purchase
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY o.customer_id
) as cohort_data
GROUP BY strftime('%Y-%m', first_purchase)
ORDER BY cohort;

-- Query 2.10: CLV Prediction
SELECT
 CASE
 WHEN days_active <= 30 THEN '0-30 days'
 WHEN days_active <= 90 THEN '30-90 days'
 WHEN days_active <= 180 THEN '90-180 days'
 ELSE '180+ days'
 END as customer_age,
 COUNT(*) as customers,
 ROUND(AVG(lifetime_value), 2) as avg_clv,
 ROUND(AVG(purchase_frequency), 2) as avg_purchases,
 ROUND(AVG(lifetime_value * 3), 2) as predicted_3yr_clv
FROM (
 SELECT
 o.customer_id,
 SUM(oi.price + oi.freight_value) as lifetime_value,
 COUNT(*) as purchase_frequency,
 CAST(julianday((SELECT MAX(order_purchase_timestamp) FROM olist_orders)) -
 julianday(MIN(o.order_purchase_timestamp)) AS INTEGER) as days_active
 FROM olist_orders o
 LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
 GROUP BY o.customer_id
) as clv_data
GROUP BY customer_age
ORDER BY avg_clv DESC;