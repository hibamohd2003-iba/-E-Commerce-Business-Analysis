"""
Data Visualization for E-Commerce Analysis
Creates charts for sales, customer, and operational metrics
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime


class ECommerceVisualizations:
    """
    Create visualizations from e-commerce data
    """
    
    def __init__(self, data=None):
        """Initialize with data"""
        self.data = data
        sns.set_style("whitegrid")
        plt.rcParams['figure.figsize'] = (14, 6)
    
    def plot_monthly_revenue(self, save_path=None):
        """
        Plot monthly revenue trend
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        
        # Merge and aggregate
        merged = orders.merge(order_items, on='order_id')
        merged['order_month'] = pd.to_datetime(merged['order_purchase_timestamp']).dt.to_period('M')
        
        monthly = merged.groupby('order_month').agg({
            'price': 'sum',
            'freight_value': 'sum'
        }).reset_index()
        
        monthly['total_revenue'] = monthly['price'] + monthly['freight_value']
        monthly['order_month'] = monthly['order_month'].astype(str)
        
        # Plot
        fig, ax = plt.subplots(figsize=(14, 6))
        ax.bar(range(len(monthly)), monthly['total_revenue'], color='steelblue', alpha=0.8)
        ax.set_xlabel('Month', fontsize=12, fontweight='bold')
        ax.set_ylabel('Revenue (R$)', fontsize=12, fontweight='bold')
        ax.set_title('Monthly Revenue Trend', fontsize=14, fontweight='bold')
        ax.set_xticks(range(0, len(monthly), 3))
        ax.set_xticklabels(monthly['order_month'][::3], rotation=45)
        
        # Format y-axis as currency
        ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'R${x/1e6:.1f}M'))
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_order_status_distribution(self, save_path=None):
        """
        Plot distribution of order statuses
        """
        orders = self.data['orders']
        status_counts = orders['order_status'].value_counts()
        
        fig, ax = plt.subplots(figsize=(10, 6))
        colors = ['#2ecc71' if x == 'delivered' else '#e74c3c' if x == 'canceled' else '#3498db' 
                  for x in status_counts.index]
        
        bars = ax.barh(status_counts.index, status_counts.values, color=colors, alpha=0.8)
        ax.set_xlabel('Number of Orders', fontsize=12, fontweight='bold')
        ax.set_title('Order Status Distribution', fontsize=14, fontweight='bold')
        
        # Add value labels
        for i, bar in enumerate(bars):
            width = bar.get_width()
            ax.text(width, bar.get_y() + bar.get_height()/2, 
                   f'{int(width):,}', ha='left', va='center', fontweight='bold')
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_customer_churn(self, save_path=None):
        """
        Plot customer churn status breakdown
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        
        # Get last purchase date
        orders['order_date'] = pd.to_datetime(orders['order_purchase_timestamp'])
        last_purchase = orders.groupby('customer_id')['order_date'].max().reset_index()
        
        current_date = orders['order_date'].max()
        last_purchase['days_since'] = (current_date - last_purchase['order_date']).dt.days
        
        # Categorize
        def categorize_customer(days):
            if days <= 30:
                return 'Active'
            elif days <= 90:
                return 'Dormant'
            else:
                return 'Churned'
        
        last_purchase['status'] = last_purchase['days_since'].apply(categorize_customer)
        
        # Get customer value
        customer_value = order_items.merge(orders[['order_id', 'customer_id']], on='order_id')
        customer_value = customer_value.groupby('customer_id')['price'].sum().reset_index()
        
        churn_data = last_purchase.merge(customer_value, on='customer_id')
        summary = churn_data.groupby('status').size()
        
        # Plot
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6))
        
        # Count pie chart
        colors = ['#2ecc71', '#f39c12', '#e74c3c']
        ax1.pie(summary.values, labels=summary.index, autopct='%1.1f%%', 
               colors=colors, startangle=90)
        ax1.set_title('Customer Distribution by Status', fontsize=12, fontweight='bold')
        
        # Revenue by status
        revenue_by_status = churn_data.groupby('status')['price'].sum()
        ax2.bar(revenue_by_status.index, revenue_by_status.values, color=colors, alpha=0.8)
        ax2.set_ylabel('Revenue (R$)', fontsize=11, fontweight='bold')
        ax2.set_title('Revenue by Customer Status', fontsize=12, fontweight='bold')
        ax2.yaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'R${x/1e6:.1f}M'))
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_top_states(self, save_path=None):
        """
        Plot revenue by state
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        customers = self.data['customers']
        
        # Merge to get state info
        merged = orders.merge(customers[['customer_id', 'customer_state']], on='customer_id')
        merged = merged.merge(order_items, on='order_id')
        
        # Revenue by state
        state_revenue = merged.groupby('customer_state').agg({
            'price': 'sum',
            'freight_value': 'sum'
        }).reset_index()
        state_revenue['total'] = state_revenue['price'] + state_revenue['freight_value']
        state_revenue = state_revenue.sort_values('total', ascending=False).head(10)
        
        # Plot
        fig, ax = plt.subplots(figsize=(12, 6))
        bars = ax.barh(state_revenue['customer_state'], state_revenue['total'], color='coral', alpha=0.8)
        ax.set_xlabel('Revenue (R$)', fontsize=12, fontweight='bold')
        ax.set_title('Top 10 States by Revenue', fontsize=14, fontweight='bold')
        ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda x, p: f'R${x/1e6:.1f}M'))
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_rating_distribution(self, save_path=None):
        """
        Plot distribution of review ratings
        """
        reviews = self.data['reviews']
        
        rating_counts = reviews['review_score'].value_counts().sort_index()
        
        fig, ax = plt.subplots(figsize=(10, 6))
        colors = ['#e74c3c' if x <= 2 else '#f39c12' if x == 3 else '#2ecc71' 
                  for x in rating_counts.index]
        
        bars = ax.bar(rating_counts.index, rating_counts.values, color=colors, alpha=0.8, width=0.6)
        ax.set_xlabel('Rating (Stars)', fontsize=12, fontweight='bold')
        ax.set_ylabel('Number of Reviews', fontsize=12, fontweight='bold')
        ax.set_title('Customer Review Rating Distribution', fontsize=14, fontweight='bold')
        ax.set_xticks([1, 2, 3, 4, 5])
        
        # Add value labels
        for bar in bars:
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2, height,
                   f'{int(height):,}', ha='center', va='bottom', fontweight='bold')
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()


# Main execution
if __name__ == "__main__":
    print("📊 E-Commerce Visualization Script")
    print("="*60)
    print("\n📝 Usage Instructions:")
    print("  1. Load data: analysis = ECommerceAnalysis('path/to/csv')")
    print("  2. Create visualizations: viz = ECommerceVisualizations(analysis.data)")
    print("  3. Plot: viz.plot_monthly_revenue()")
    print("           viz.plot_order_status_distribution()")
    print("           viz.plot_customer_churn()")
    print("           viz.plot_top_states()")
    print("           viz.plot_rating_distribution()")