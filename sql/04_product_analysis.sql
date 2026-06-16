-- ============================================================================
-- PRODUCT ANALYSIS
-- File: 04_product_analysis.sql
-- Description: 10 queries analyzing product performance, ratings, and bundles
-- Database: E-Commerce (99,441 orders, Sep 2016 - Oct 2018)
-- ============================================================================

-- Query 3.1: Top Products by Revenue
SELECT 
 p.product_category_name,
 COUNT(DISTINCT oi.order_id) as orders,
 ROUND(SUM(oi.price), 2) as total_revenue,
 COUNT(DISTINCT oi.product_id) as product_count,
 ROUND(AVG(oi.price), 2) as avg_price
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Query 3.2: Top Rated Product Categories
SELECT
 p.product_category_name,
 COUNT(rv.review_score) as reviews,
 ROUND(AVG(rv.review_score), 2) as avg_rating,
 ROUND(100.0 * COUNT(CASE WHEN rv.review_score >= 4 THEN 1 END) / COUNT(*), 2) as satisfaction_pct
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN olist_order_reviews rv ON oi.order_id = rv.order_id
GROUP BY p.product_category_name
HAVING COUNT(rv.review_score) >= 5
ORDER BY avg_rating DESC
LIMIT 10;

-- Query 3.3: Worst Rated Categories
SELECT
 p.product_category_name,
 COUNT(rv.review_score) as reviews,
 ROUND(AVG(rv.review_score), 2) as avg_rating,
 ROUND(100.0 * COUNT(CASE WHEN rv.review_score <= 2 THEN 1 END) / COUNT(*), 2) as dissatisfaction_pct
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN olist_order_reviews rv ON oi.order_id = rv.order_id
GROUP BY p.product_category_name
HAVING COUNT(rv.review_score) >= 5
ORDER BY avg_rating ASC
LIMIT 10;

-- Query 3.4: Product Profitability
SELECT
 p.product_category_name,
 COUNT(DISTINCT oi.order_id) as orders,
 ROUND(SUM(oi.price), 2) as gross_revenue,
 ROUND(SUM(oi.freight_value), 2) as shipping_costs,
 ROUND(SUM(oi.price - oi.freight_value), 2) as net_revenue,
 ROUND(100.0 * SUM(oi.freight_value) / SUM(oi.price), 2) as shipping_cost_percent
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY net_revenue DESC
LIMIT 10;

-- Query 3.5: Cross Selling Opportunities
SELECT
 p1.product_category_name as primary_product,
 p2.product_category_name as frequently_bought_with,
 COUNT(*) as co_purchase_frequency
FROM olist_order_items oi1
JOIN olist_order_items oi2 ON oi1.order_id = oi2.order_id 
 AND oi1.product_id < oi2.product_id
JOIN olist_products p1 ON oi1.product_id = p1.product_id
JOIN olist_products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_category_name, p2.product_category_name
ORDER BY co_purchase_frequency DESC
LIMIT 10;

-- Query 3.6: Seasonal Product Demand
SELECT
 p.product_category_name,
 strftime('%m', o.order_purchase_timestamp) as month,
 COUNT(DISTINCT oi.order_id) as orders,
 ROUND(SUM(oi.price), 2) as revenue
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
JOIN olist_orders o ON oi.order_id = o.order_id
WHERE p.product_category_name IN (
 'beleza_saude',
 'relogios_presentes',
 'cama_mesa_banho',
 'esporte_lazer',
 'informatica_acessorios'
)
GROUP BY p.product_category_name, strftime('%m', o.order_purchase_timestamp)
ORDER BY p.product_category_name, month;

-- Query 3.7: Bundle Opportunities
SELECT
 p1.product_category_name as category_1,
 p2.product_category_name as category_2,
 COUNT(*) as bundle_frequency
FROM olist_order_items oi1
JOIN olist_order_items oi2 ON oi1.order_id = oi2.order_id
JOIN olist_products p1 ON oi1.product_id = p1.product_id
JOIN olist_products p2 ON oi2.product_id = p2.product_id
WHERE p1.product_category_name < p2.product_category_name
GROUP BY p1.product_category_name, p2.product_category_name
HAVING COUNT(*) > 10
ORDER BY bundle_frequency DESC
LIMIT 10;

-- Query 3.8: Product Size vs Shipping Cost
SELECT
 p.product_category_name,
 ROUND(AVG(p.product_weight_g), 2) as avg_weight_g,
 ROUND(AVG(oi.freight_value), 2) as avg_freight,
 ROUND(AVG(oi.price), 2) as avg_price,
 ROUND(100.0 * AVG(oi.freight_value) / AVG(oi.price), 2) as freight_pct
FROM olist_order_items oi
JOIN olist_products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_freight DESC
LIMIT 10;

-- Query 3.9: Seller Quality by Category
SELECT
 p.product_category_name,
 COUNT(DISTINCT oi.seller_id) as sellers,
 ROUND(AVG(rv.review_score), 2) as avg_rating,
 COUNT(CASE WHEN rv.review_score <= 2 THEN 1 END) as negative_reviews,