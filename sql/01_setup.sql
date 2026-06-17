-- ============================================================================
-- DATABASE SETUP
-- File: 01_setup.sql
-- Description: Database creation, table schemas, and data import instructions
-- Database: E-Commerce (Brazilian Olist dataset — Kaggle)
-- Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE ALL 9 TABLES
-- Run each CREATE TABLE block in SQLite Studio's SQL Editor
-- ============================================================================

-- Table 1: Orders (99,441 rows)
CREATE TABLE olist_orders (
    order_id                        TEXT,
    customer_id                     TEXT,
    order_status                    TEXT,
    order_purchase_timestamp        TEXT,
    order_approved_at               TEXT,
    order_delivered_carrier_date    TEXT,
    order_delivered_customer_date   TEXT,
    order_estimated_delivery_date   TEXT
);

-- Table 2: Customers (99,441 rows)
CREATE TABLE olist_customers (
    customer_id             TEXT,
    customer_unique_id      TEXT,
    customer_zip_code_prefix TEXT,
    customer_city           TEXT,
    customer_state          TEXT
);

-- Table 3: Order Items (112,650 rows)
CREATE TABLE olist_order_items (
    order_id            TEXT,
    order_item_id       INTEGER,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TEXT,
    price               REAL,
    freight_value       REAL
);

-- Table 4: Order Payments (103,886 rows)
CREATE TABLE olist_order_payments (
    order_id                TEXT,
    payment_sequential      INTEGER,
    payment_type            TEXT,
    payment_installments    INTEGER,
    payment_value           REAL
);

-- Table 5: Order Reviews (99,224 rows)
CREATE TABLE olist_order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            INTEGER,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT
);

-- Table 6: Products (32,951 rows)
CREATE TABLE olist_products (
    product_id                  TEXT,
    product_category_name       TEXT,
    product_name_lenght         INTEGER,
    product_description_lenght  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            REAL,
    product_length_cm           REAL,
    product_height_cm           REAL,
    product_width_cm            REAL
);

-- Table 7: Sellers (3,095 rows)
CREATE TABLE olist_sellers (
    seller_id               TEXT,
    seller_zip_code_prefix  TEXT,
    seller_city             TEXT,
    seller_state            TEXT
);

-- Table 8: Product Category Name Translation (71 rows)
CREATE TABLE olist_product_category_name_translation (
    product_category_name           TEXT,
    product_category_name_english   TEXT
);

-- Table 9: Geolocation (1,000,163 rows)
CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             REAL,
    geolocation_lng             REAL,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);

-- ============================================================================
-- STEP 2: IMPORT CSV DATA
-- For each table in SQLite Studio:
--   1. Right-click the table → Import data
--   2. Choose CSV format
--   3. Select the matching CSV file from your Kaggle download
--   4. Tick "First row as column names"
--   5. Click OK
--
-- File → Table mapping:
--   olist_orders_dataset.csv               → olist_orders
--   olist_customers_dataset.csv            → olist_customers
--   olist_order_items_dataset.csv          → olist_order_items
--   olist_order_payments_dataset.csv       → olist_order_payments
--   olist_order_reviews_dataset.csv        → olist_order_reviews
--   olist_products_dataset.csv             → olist_products
--   olist_sellers_dataset.csv              → olist_sellers
--   product_category_name_translation.csv → olist_product_category_name_translation
--   olist_geolocation_dataset.csv          → olist_geolocation
-- ============================================================================

-- ============================================================================
-- STEP 3: VERIFY DATA LOADED CORRECTLY
-- Run this query to confirm all 9 tables have the expected row counts
-- ============================================================================

SELECT 'olist_orders'                              as table_name, COUNT(*) as row_count FROM olist_orders
UNION ALL
SELECT 'olist_customers',                                         COUNT(*) FROM olist_customers
UNION ALL
SELECT 'olist_order_items',                                       COUNT(*) FROM olist_order_items
UNION ALL
SELECT 'olist_order_payments',                                    COUNT(*) FROM olist_order_payments
UNION ALL
SELECT 'olist_order_reviews',                                     COUNT(*) FROM olist_order_reviews
UNION ALL
SELECT 'olist_products',                                          COUNT(*) FROM olist_products
UNION ALL
SELECT 'olist_sellers',                                           COUNT(*) FROM olist_sellers
UNION ALL
SELECT 'olist_product_category_name_translation',                 COUNT(*) FROM olist_product_category_name_translation
UNION ALL
SELECT 'olist_geolocation',                                       COUNT(*) FROM olist_geolocation;

-- Expected results:
-- olist_orders                              → 99,441
-- olist_customers                           → 99,441
-- olist_order_items                         → 112,650
-- olist_order_payments                      → 103,886
-- olist_order_reviews                       → 99,224
-- olist_products                            → 32,951
-- olist_sellers                             → 3,095
-- olist_product_category_name_translation   → 71
-- olist_geolocation                         → 1,000,163

-- ============================================================================
-- STEP 4: VERIFY DATE RANGE
-- ============================================================================

SELECT
    MIN(order_purchase_timestamp) as earliest,
    MAX(order_purchase_timestamp) as latest
FROM olist_orders;

-- Expected: September 2016 → October 2018

-- ============================================================================
-- DATABASE DETAILS
-- ============================================================================
-- Dataset Source : Kaggle — Brazilian E-Commerce by Olist
-- URL           : https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- Time Period   : Sep 2016 – Oct 2018 (~2 years)
-- Total Orders  : 99,441
-- Total Tables  : 9
-- DB Engine     : SQLite (via SQLite Studio)
-- ============================================================================