-- ============================================================================
-- OPERATIONAL ANALYSIS
-- File: 05_operational_analysis.sql
-- Description: 12 queries analyzing delivery, payments, and operations
-- Database: E-Commerce (99,441 orders, Sep 2016 - Oct 2018)
-- ============================================================================

-- Query 4.1: Order Fulfillment Performance
SELECT 
 order_status,
 COUNT(*) as orders,
 ROUND(AVG(CAST(julianday(order_delivered_customer_date) -
 julianday(order_purchase_timestamp) AS INTEGER)), 1) as avg_fulfillment_days,
 ROUND(AVG(CAST(julianday(order_delivered_customer_date) -
 julianday(order_estimated_delivery_date) AS INTEGER)), 1) as avg_delay_days,
 COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) as late_deliveries
FROM olist_orders
GROUP BY order_status;

-- Query 4.2: Delivery Performance by Region
SELECT
 c.customer_state,
 COUNT(*) as deliveries,
 ROUND(AVG(CAST(julianday(o.order_delivered_customer_date) -
 julianday(o.order_purchase_timestamp) AS INTEGER)), 1) as avg_days,
 COUNT(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 END) as late_count,
 ROUND(100.0 * COUNT(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 END) / COUNT(*), 2) as on_time_rate
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY on_time_rate ASC;

-- Query 4.3: Payment Method Analysis
SELECT
 op.payment_type,
 COUNT(*) as orders,
 ROUND(SUM(op.payment_value), 2) as total_value,
 ROUND(AVG(op.payment_value), 2) as avg_value,
 COUNT(CASE WHEN op.payment_installments > 1 THEN 1 END) as installment_orders,
 ROUND(AVG(op.payment_installments), 1) as avg_installments,
 COUNT(DISTINCT o.customer_id) as customers
FROM olist_order_payments op
JOIN olist_orders o ON op.order_id = o.order_id
GROUP BY op.payment_type
ORDER BY total_value DESC;

-- Query 4.4: Payment Failure Rate
SELECT
 strftime('%Y-%m', o.order_purchase_timestamp) as month,
 COUNT(*) as total_orders,
 COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) as failed_orders,
 ROUND(100.0 * COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) / COUNT(*), 2) as failure_rate
FROM olist_orders o
GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)
ORDER BY month;

-- Query 4.5: Freight Value Impact
SELECT
 CASE
 WHEN oi.freight_value / oi.price < 0.1 THEN 'Low (< 10%)'
 WHEN oi.freight_value / oi.price < 0.2 THEN 'Medium (10-20%)'
 ELSE 'High (> 20%)'
 END as freight_cost_level,
 COUNT(*) as orders,
 ROUND(SUM(oi.price), 2) as product_value,
 ROUND(SUM(oi.freight_value), 2) as total_freight,
 ROUND(100.0 * SUM(oi.freight_value) / (SUM(oi.price) + SUM(oi.freight_value)), 2) as freight_percentage
FROM olist_order_items oi
GROUP BY freight_cost_level
ORDER BY freight_percentage DESC;

-- Query 4.6: Order Size Distribution
SELECT
 CASE
 WHEN order_items_count = 1 THEN 'Single Item'
 WHEN order_items_count BETWEEN 2 AND 5 THEN '2-5 Items'
 ELSE '5+ Items'
 END as order_size,
 COUNT(*) as orders,
 ROUND(AVG(order_total), 2) as avg_order_value,
 ROUND(SUM(order_total), 2) as total_revenue
FROM (
 SELECT
 oi.order_id,
 COUNT(*) as order_items_count,
 SUM(oi.price + oi.freight_value) as order_total
 FROM olist_order_items oi
 GROUP BY oi.order_id
) as order_metrics
JOIN olist_orders o ON order_metrics.order_id = o.order_id
GROUP BY order_size
ORDER BY orders DESC;

-- Query 4.7: Review Comment Analysis
SELECT 
 CASE 
 WHEN review_comment_message IS NOT NULL 
 AND review_comment_message != '' THEN 'With Comment'
 ELSE 'No Comment'
 END as review_type,
 ROUND(AVG(review_score), 2) as avg_rating,
 COUNT(*) as reviews,
 COUNT(CASE WHEN review_score >= 4 THEN 1 END) as positive,
 COUNT(CASE WHEN review_score <= 2 THEN 1 END) as negative
FROM olist_order_reviews
GROUP BY review_type;

-- Query 4.8: Order Cancellation by Month
SELECT
 strftime('%Y-%m', order_purchase_timestamp) as month,
 COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) as cancellations,
 COUNT(*) as total_orders,
 ROUND(100.0 * COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) / COUNT(*), 2) as cancellation_rate
FROM olist_orders
GROUP BY strftime('%Y-%m', order_purchase_timestamp)
ORDER BY month;

-- Query 4.9: Overall Logistics Performance
SELECT
 'Overall Logistics' as metric,
 COUNT(*) as deliveries,
 ROUND(AVG(CAST(julianday(order_delivered_customer_date) -
 julianday(order_purchase_timestamp) AS INTEGER)), 1) as avg_days,
 COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) as on_time,
 ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) / COUNT(*), 2) as on_time_rate
FROM olist_orders
WHERE order_status = 'delivered';

-- Query 4.10: Seller Performance
SELECT
 oi.seller_id,
 COUNT(DISTINCT oi.order_id) as orders,
 ROUND(SUM(oi.price), 2) as total_revenue,
 ROUND(AVG(oi.price), 2) as avg_price,
 ROUND(AVG(rv.review_score), 2) as avg_rating,
 COUNT(CASE WHEN rv.review_score <= 2 THEN 1 END) as negative_reviews
FROM olist_order_items oi
LEFT JOIN olist_order_reviews rv ON oi.order_id = rv.order_id
GROUP BY oi.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 4.11: Return/Refund Analysis
SELECT
 order_status,
 COUNT(*) as orders,
 ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM olist_orders), 2) as percentage
FROM olist_orders
WHERE order_status NOT IN ('delivered', 'shipped', 'processing')
GROUP BY order_status
ORDER BY orders DESC;

-- Query 4.12: Overall Operational Efficiency
SELECT
 'Overall Efficiency' as metric,
 ROUND(100.0 * COUNT(CASE WHEN order_status = 'delivered' THEN 1 END) / COUNT(*), 2) as delivery_success_rate,
 ROUND(100.0 * COUNT(CASE WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 1 END) / 
 COUNT(CASE WHEN order_status = 'delivered' THEN 1 END), 2) as on_time_rate,
 ROUND(AVG(CASE WHEN order_status = 'delivered'
 THEN CAST(julianday(order_delivered_customer_date) -
 julianday(order_purchase_timestamp) AS INTEGER) END), 1) as avg_fulfillment_days,
 ROUND(AVG(CASE WHEN rv.review_score IS NOT NULL
 THEN rv.review_score END), 2) as customer_satisfaction
FROM olist_orders o
LEFT JOIN olist_order_reviews rv ON o.order_id = rv.order_id;