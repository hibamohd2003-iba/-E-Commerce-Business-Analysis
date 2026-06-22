"""
Utility functions for E-Commerce Analysis
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta


def load_data_from_csv(csv_folder_path):
    """
    Load all CSV files from Kaggle dataset
    
    Parameters:
    csv_folder_path (str): Path to folder containing CSV files
    
    Returns:
    dict: Dictionary containing all dataframes
    """
    try:
        data = {
            'orders': pd.read_csv(f'{csv_folder_path}/olist_orders_dataset.csv'),
            'customers': pd.read_csv(f'{csv_folder_path}/olist_customers_dataset.csv'),
            'order_items': pd.read_csv(f'{csv_folder_path}/olist_order_items_dataset.csv'),
            'payments': pd.read_csv(f'{csv_folder_path}/olist_order_payments_dataset.csv'),
            'reviews': pd.read_csv(f'{csv_folder_path}/olist_order_reviews_dataset.csv'),
            'products': pd.read_csv(f'{csv_folder_path}/olist_products_dataset.csv'),
            'sellers': pd.read_csv(f'{csv_folder_path}/olist_sellers_dataset.csv'),
            'categories': pd.read_csv(f'{csv_folder_path}/product_category_name_translation.csv'),
            'geolocation': pd.read_csv(f'{csv_folder_path}/olist_geolocation_dataset.csv')
        }
        return data
    except Exception as e:
        print(f"Error loading data: {e}")
        return None


def convert_dates(df, date_columns):
    """
    Convert string columns to datetime
    """
    for col in date_columns:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col])
    return df


def clean_data(data):
    """
    Clean and prepare all dataframes
    """
    # Convert date columns
    data['orders'] = convert_dates(data['orders'], 
        ['order_purchase_timestamp', 'order_approved_at', 'order_delivered_carrier_date', 'order_delivered_customer_date', 'order_estimated_delivery_date'])
    
    data['reviews'] = convert_dates(data['reviews'], ['review_creation_date', 'review_answer_timestamp'])
    
    return data


def get_order_status_summary(orders_df):
    """
    Summary of order statuses
    """
    return orders_df['order_status'].value_counts().to_dict()


def calculate_metrics(orders_df, order_items_df):
    """
    Calculate key business metrics
    """
    metrics = {
        'total_orders': len(orders_df),
        'total_revenue': order_items_df['price'].sum() + order_items_df['freight_value'].sum(),
        'avg_order_value': (order_items_df['price'].sum() + order_items_df['freight_value'].sum()) / len(orders_df),
        'delivered_orders': len(orders_df[orders_df['order_status'] == 'delivered']),
    }
    return metrics


def print_metrics(metrics):
    """
    Pretty print metrics
    """
    print("\n" + "="*50)
    print("BUSINESS METRICS SUMMARY")
    print("="*50)
    for key, value in metrics.items():
        if 'revenue' in key or 'value' in key:
            print(f"{key}: R${value:,.2f}")
        else:
            print(f"{key}: {value:,.0f}")
    print("="*50 + "\n")