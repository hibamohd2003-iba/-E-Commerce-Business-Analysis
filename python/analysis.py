"""
E-Commerce Business Analysis
Reproduces SQL queries using Pandas for Brazilian e-commerce dataset
"""

import pandas as pd
import numpy as np
from utils import load_data_from_csv, clean_data, calculate_metrics, print_metrics
import warnings
warnings.filterwarnings('ignore')


class ECommerceAnalysis:
    """
    Main analysis class for e-commerce dataset
    """
    
    def __init__(self, data_path=None):
        """
        Initialize with data
        
        Parameters:
        data_path (str): Path to CSV folder from Kaggle
        """
        if data_path:
            self.data = load_data_from_csv(data_path)
            self.data = clean_data(self.data)
        else:
            self.data = None
            print("⚠️ No data path provided. Load data manually using load_data()")
    
    def load_data(self, data_path):
        """Load data from CSV folder"""
        self.data = load_data_from_csv(data_path)
        self.data = clean_data(self.data)
        print(f"✅ Data loaded successfully!")
    
    # ==================== SALES ANALYSIS ====================
    
    def query_1_1_business_health(self):
        """
        Q1.1: Business Health Overview
        Total orders, customers, revenue, delivery success rate
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        
        total_orders = len(orders)
        total_customers = orders['customer_id'].nunique()
        total_revenue = order_items['price'].sum() + order_items['freight_value'].sum()
        avg_order_value = total_revenue / total_orders
        delivered = len(orders[orders['order_status'] == 'delivered'])
        delivery_success = (delivered / total_orders) * 100
        
        result = {
            'Total Orders': total_orders,
            'Total Customers': total_customers,
            'Total Revenue (R$)': f"{total_revenue:,.2f}",
            'Average Order Value (R$)': f"{avg_order_value:,.2f}",
            'Delivery Success Rate (%)': f"{delivery_success:.2f}%"
        }
        return result
    
    def query_1_2_monthly_trend(self):
        """
        Q1.2: Monthly revenue and order trend
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        
        # Merge to get revenue by order
        merged = orders.merge(order_items, on='order_id')
        merged['order_month'] = pd.to_datetime(merged['order_purchase_timestamp']).dt.to_period('M')
        
        monthly = merged.groupby('order_month').agg({
            'order_id': 'nunique',
            'price': 'sum',
            'freight_value': 'sum'
        }).reset_index()
        
        monthly.columns = ['Month', 'Orders', 'Product Revenue', 'Freight Revenue']
        monthly['Total Revenue'] = monthly['Product Revenue'] + monthly['Freight Revenue']
        
        return monthly
    
    def query_2_1_repeat_rate(self):
        """
        Q2.1: Customer repeat purchase rate
        """
        orders = self.data['orders']
        customer_purchases = orders.groupby('customer_id').size()
        
        repeat_customers = len(customer_purchases[customer_purchases > 1])
        total_customers = len(customer_purchases)
        repeat_rate = (repeat_customers / total_customers) * 100
        
        result = {
            'Total Customers': total_customers,
            'Repeat Customers': repeat_customers,
            'Repeat Rate (%)': f"{repeat_rate:.2f}%",
            'Single Purchase Rate (%)': f"{100-repeat_rate:.2f}%"
        }
        return result
    
    def query_2_2_churn_analysis(self):
        """
        Q2.2: Customer churn/retention status
        Categorize customers as: Active, Dormant, At Risk, Churned
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        
        # Get last purchase date for each customer
        orders['order_date'] = pd.to_datetime(orders['order_purchase_timestamp'])
        last_purchase = orders.groupby('customer_id')['order_date'].max().reset_index()
        last_purchase.columns = ['customer_id', 'last_purchase_date']
        
        # Current date (use latest date in dataset)
        current_date = orders['order_date'].max()
        
        # Calculate days since last purchase
        last_purchase['days_since_purchase'] = (current_date - last_purchase['last_purchase_date']).dt.days
        
        # Get customer value
        customer_value = order_items.merge(orders[['order_id', 'customer_id']], on='order_id')
        customer_value = customer_value.groupby('customer_id').agg({
            'price': 'sum',
            'freight_value': 'sum'
        }).reset_index()
        customer_value['total_value'] = customer_value['price'] + customer_value['freight_value']
        
        # Merge
        churn = last_purchase.merge(customer_value[['customer_id', 'total_value']], on='customer_id')
        
        # Categorize (based on days inactive and time in business)
        max_days = churn['days_since_purchase'].max()
        churn['status'] = pd.cut(churn['days_since_purchase'], 
                                 bins=[0, 30, 90, max_days],
                                 labels=['Active', 'Dormant', 'Churned'])
        
        summary = churn.groupby('status').agg({
            'customer_id': 'count',
            'total_value': 'sum'
        }).reset_index()
        summary.columns = ['Status', 'Customers', 'Revenue (R$)']
        
        return summary
    
    def query_3_3_product_ratings(self):
        """
        Q3.3: Product category ratings
        """
        reviews = self.data['reviews']
        order_items = self.data['order_items']
        products = self.data['products']
        categories = self.data['categories']
        
        # Merge to get category names
        df = reviews.merge(order_items[['order_id', 'product_id']], on='order_id')
        df = df.merge(products[['product_id', 'product_category_name']], on='product_id')
        df = df.merge(categories, on='product_category_name', how='left')
        
        # Calculate ratings by category
        ratings = df.groupby('product_category_name_english').agg({
            'review_id': 'count',
            'review_score': 'mean'
        }).reset_index()
        ratings.columns = ['Category', 'Reviews', 'Avg Rating']
        ratings = ratings.sort_values('Avg Rating')
        
        return ratings
    
    def print_summary(self):
        """Print summary of all analyses"""
        print("\n" + "="*60)
        print("E-COMMERCE ANALYSIS SUMMARY")
        print("="*60)
        
        print("\n📊 BUSINESS HEALTH:")
        health = self.query_1_1_business_health()
        for key, value in health.items():
            print(f"  {key}: {value}")
        
        print("\n👥 CUSTOMER RETENTION:")
        repeat = self.query_2_1_repeat_rate()
        for key, value in repeat.items():
            print(f"  {key}: {value}")
        
        print("\n⭐ PRODUCT RATINGS (Worst Rated):")
        ratings = self.query_3_3_product_ratings()
        for idx, row in ratings.head(5).iterrows():
            print(f"  {row['Category']}: {row['Avg Rating']:.2f}★ ({int(row['Reviews'])} reviews)")
        
        print("\n" + "="*60 + "\n")


# Main execution
if __name__ == "__main__":
    print("🚀 E-Commerce Analysis Script")
    print("="*60)
    
    # Example usage:
    # analysis = ECommerceAnalysis("path/to/csv/folder")
    # health = analysis.query_1_1_business_health()
    # print(health)
    
    print("\n📝 Usage Instructions:")
    print("  1. Download dataset from Kaggle")
    print("  2. Extract CSV files to a folder")
    print("  3. Create analysis object: analysis = ECommerceAnalysis('path/to/csv/folder')")
    print("  4. Run queries: health = analysis.query_1_1_business_health()")