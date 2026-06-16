-- ============================================================================
-- SALES PERFORMANCE ANALYSIS
-- File: 02_sales_performance.sql
-- Description: 7 queries analyzing sales trends, performance by region, etc.
-- Database: E-Commerce (99,441 orders, Sep 2016 - Oct 2018)
-- ============================================================================

-- Query 1.1: Overall Business Health
SELECT
 COUNT(DISTINCT o.order_id) as total_orders,
 COUNT(DISTINCT o.customer_id) as total_customers,
 ROUND(SUM(oi.price + oi.freight_value), 2) as total_revenue,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value,
 COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) as delivered_orders,
 ROUND(100.0 * COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) / 
COUNT(DISTINCT o.order_id), 2) as delivery_success_rate
FROM olist_orders o
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id;

-- Query 1.2: Monthly Sales Trend
SELECT
 strftime('%Y-%m', order_purchase_timestamp) as month,
 COUNT(*) as orders,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value,
 COUNT(DISTINCT o.customer_id) as customers
FROM olist_orders o
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y-%m', order_purchase_timestamp)
ORDER BY month;

-- Query 1.3: Order Status Breakdown
SELECT
 order_status,
 COUNT(*) as orders,
 ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM olist_orders), 2) as percentage
FROM olist_orders
GROUP BY order_status
ORDER BY orders DESC;

-- Query 1.4: Sales by State
SELECT
 c.customer_state,
 COUNT(DISTINCT o.order_id) as orders,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue,
 COUNT(DISTINCT o.customer_id) as customers,
 ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.customer_id), 2) as revenue_per_customer
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;

-- Query 1.5: Daily Sales Pattern
SELECT
 CASE strftime('%w', order_purchase_timestamp)
 WHEN '0' THEN 'Sunday'
 WHEN '1' THEN 'Monday'
 WHEN '2' THEN 'Tuesday'
 WHEN '3' THEN 'Wednesday'
 WHEN '4' THEN 'Thursday'
 WHEN '5' THEN 'Friday'
 WHEN '6' THEN 'Saturday'
 END as day_of_week,
 COUNT(*) as orders,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order_value
FROM olist_orders o
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%w', order_purchase_timestamp)
ORDER BY strftime('%w', order_purchase_timestamp);

-- Query 1.6: Seasonality by Month
SELECT
 strftime('%m', order_purchase_timestamp) as month_num,
 COUNT(*) as orders,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue,
 ROUND(AVG(oi.price + oi.freight_value), 2) as avg_order
FROM olist_orders o
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%m', order_purchase_timestamp)
ORDER BY month_num;

-- Query 1.7: Year over Year Growth
SELECT
 strftime('%Y', order_purchase_timestamp) as year,
 strftime('%m', order_purchase_timestamp) as month,
 COUNT(*) as orders,
 ROUND(SUM(oi.price + oi.freight_value), 2) as revenue
FROM olist_orders o
LEFT JOIN olist_order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y', order_purchase_timestamp), strftime('%m', order_purchase_timestamp)
ORDER BY year, month;