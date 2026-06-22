# Dataset Information

## Source
**Brazilian E-Commerce Public Dataset by Olist**
- **Link:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
- **License:** CC BY-NC-SA 4.0

---

## Overview
This dataset contains information on 100,000 orders made at Olist Store in Brazil between 2016 and 2018. Orders are linked across multiple tables covering customers, products, sellers, payments, reviews, and geolocation.

---

## Time Period
- **Start:** September 2016
- **End:** October 2018
- **Duration:** ~2 years

---

## Tables & Row Counts

| Table | Rows | Description |
|-------|------|-------------|
| olist_orders | 99,441 | Order header — status, timestamps |
| olist_customers | 99,441 | Customer location info |
| olist_order_items | 112,650 | Products in each order, price, freight |
| olist_order_payments | 103,886 | Payment type, installments, value |
| olist_order_reviews | 99,224 | Customer review scores and comments |
| olist_products | 32,951 | Product category, dimensions, weight |
| olist_sellers | 3,095 | Seller location info |
| olist_product_category_name_translation | 71 | Portuguese to English category names |
| olist_geolocation | 1,000,163 | ZIP code lat/lng mapping |

---

## Key Facts
- 99,441 unique customers
- 99,441 unique orders
- R$15.84M total revenue
- 97% delivery success rate
- 4.09/5 average review score
- Data spans 27 Brazilian states

---

## How to Download
1. Go to https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
2. Click **Download**
3. Extract the ZIP file
4. Import each CSV into SQLite using `sql/01_setup.sql`