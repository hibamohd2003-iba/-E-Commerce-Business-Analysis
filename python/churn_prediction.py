"""
Customer Churn Prediction Model
Uses logistic regression to predict which customers will churn
"""

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score, roc_curve
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')


class ChurnPredictionModel:
    """
    Predict customer churn using logistic regression
    """
    
    def __init__(self, data=None):
        """Initialize with data"""
        self.data = data
        self.model = None
        self.scaler = StandardScaler()
        self.X_train = None
        self.X_test = None
        self.y_train = None
        self.y_test = None
    
    def prepare_features(self):
        """
        Prepare features for modeling
        """
        orders = self.data['orders']
        order_items = self.data['order_items']
        reviews = self.data['reviews']
        
        # Get customer-level features
        orders['order_date'] = pd.to_datetime(orders['order_purchase_timestamp'])
        
        # 1. Recency (days since last purchase)
        last_purchase = orders.groupby('customer_id')['order_date'].max().reset_index()
        last_purchase.columns = ['customer_id', 'last_purchase_date']
        current_date = orders['order_date'].max()
        last_purchase['recency'] = (current_date - last_purchase['last_purchase_date']).dt.days
        
        # 2. Frequency (number of purchases)
        frequency = orders.groupby('customer_id').size().reset_index(name='frequency')
        
        # 3. Monetary (total spending)
        customer_value = order_items.merge(orders[['order_id', 'customer_id']], on='order_id')
        monetary = customer_value.groupby('customer_id').agg({
            'price': 'sum',
            'freight_value': 'sum'
        }).reset_index()
        monetary['monetary'] = monetary['price'] + monetary['freight_value']
        monetary = monetary[['customer_id', 'monetary']]
        
        # 4. Rating (average review score)
        customer_reviews = reviews.merge(
            order_items[['order_id', 'product_id']], on='order_id'
        ).merge(
            orders[['order_id', 'customer_id']], on='order_id'
        )
        rating = customer_reviews.groupby('customer_id')['review_score'].mean().reset_index()
        rating.columns = ['customer_id', 'avg_rating']
        
        # 5. On-time delivery rate
        order_items_with_dates = order_items.merge(
            orders[['order_id', 'customer_id', 'order_delivered_customer_date', 'order_estimated_delivery_date']], 
            on='order_id'
        )
        order_items_with_dates['on_time'] = (
            pd.to_datetime(order_items_with_dates['order_delivered_customer_date']) <= 
            pd.to_datetime(order_items_with_dates['order_estimated_delivery_date'])
        ).astype(int)
        
        on_time_rate = order_items_with_dates.groupby('customer_id').agg({
            'on_time': 'mean'
        }).reset_index()
        on_time_rate.columns = ['customer_id', 'on_time_delivery_rate']
        
        # Merge all features
        features = last_purchase.merge(frequency, on='customer_id')
        features = features.merge(monetary, on='customer_id')
        features = features.merge(rating, on='customer_id', how='left')
        features = features.merge(on_time_rate, on='customer_id', how='left')
        
        # Fill missing values
        features['avg_rating'].fillna(features['avg_rating'].mean(), inplace=True)
        features['on_time_delivery_rate'].fillna(features['on_time_delivery_rate'].mean(), inplace=True)
        
        # Create target variable (churn = inactive for 90+ days)
        features['churned'] = (features['recency'] >= 90).astype(int)
        
        # Drop unnecessary columns
        features = features.drop(['customer_id', 'last_purchase_date'], axis=1)
        
        return features
    
    def train_model(self, test_size=0.2, random_state=42):
        """
        Train logistic regression model
        """
        print("🚀 Preparing features...")
        features = self.prepare_features()
        
        X = features.drop('churned', axis=1)
        y = features['churned']
        
        print(f"📊 Dataset size: {len(X)} customers")
        print(f"   Churned: {y.sum()} ({y.sum()/len(y)*100:.1f}%)")
        print(f"   Active: {len(y)-y.sum()} ({(len(y)-y.sum())/len(y)*100:.1f}%)")
        
        # Split data
        self.X_train, self.X_test, self.y_train, self.y_test = train_test_split(
            X, y, test_size=test_size, random_state=random_state, stratify=y
        )
        
        # Scale features
        self.X_train_scaled = self.scaler.fit_transform(self.X_train)
        self.X_test_scaled = self.scaler.transform(self.X_test)
        
        # Train model
        print("\n🔄 Training logistic regression model...")
        self.model = LogisticRegression(random_state=random_state, max_iter=1000)
        self.model.fit(self.X_train_scaled, self.y_train)
        
        print("✅ Model trained successfully!")
        
        return self
    
    def evaluate_model(self):
        """
        Evaluate model performance
        """
        if self.model is None:
            print("❌ Model not trained. Call train_model() first.")
            return
        
        # Predictions
        y_pred = self.model.predict(self.X_test_scaled)
        y_pred_proba = self.model.predict_proba(self.X_test_scaled)[:, 1]
        
        # Metrics
        print("\n" + "="*60)
        print("MODEL EVALUATION RESULTS")
        print("="*60)
        
        print("\n📊 Classification Report:")
        print(classification_report(self.y_test, y_pred, target_names=['Active', 'Churned']))
        
        roc_auc = roc_auc_score(self.y_test, y_pred_proba)
        print(f"ROC-AUC Score: {roc_auc:.4f}")
        print("="*60 + "\n")
        
        return {
            'y_pred': y_pred,
            'y_pred_proba': y_pred_proba,
            'roc_auc': roc_auc
        }
    
    def get_feature_importance(self):
        """
        Get feature importance from model coefficients
        """
        if self.model is None:
            print("❌ Model not trained. Call train_model() first.")
            return
        
        feature_names = self.X_train.columns
        coefficients = self.model.coef_[0]
        
        importance_df = pd.DataFrame({
            'Feature': feature_names,
            'Coefficient': coefficients,
            'Abs_Coefficient': np.abs(coefficients)
        }).sort_values('Abs_Coefficient', ascending=False)
        
        print("\n" + "="*60)
        print("FEATURE IMPORTANCE (Impact on Churn)")
        print("="*60)
        for idx, row in importance_df.iterrows():
            direction = "⬆️ Increases churn" if row['Coefficient'] > 0 else "⬇️ Decreases churn"
            print(f"{row['Feature']:.<30} {direction:.<25} ({row['Coefficient']:>7.4f})")
        print("="*60 + "\n")
        
        return importance_df
    
    def predict_for_customer(self, recency, frequency, monetary, avg_rating, on_time_rate):
        """
        Predict churn probability for a single customer
        """
        if self.model is None:
            print("❌ Model not trained. Call train_model() first.")
            return
        
        customer_data = np.array([[recency, frequency, monetary, avg_rating, on_time_rate]])
        customer_data_scaled = self.scaler.transform(customer_data)
        
        churn_prob = self.model.predict_proba(customer_data_scaled)[0][1]
        
        print(f"\n🔮 Churn Prediction for Customer:")
        print(f"   Recency: {recency} days")
        print(f"   Frequency: {frequency} purchases")
        print(f"   Monetary: R${monetary:,.2f}")
        print(f"   Avg Rating: {avg_rating:.2f}★")
        print(f"   On-time Delivery Rate: {on_time_rate:.1%}")
        print(f"\n   ⚠️  Churn Probability: {churn_prob:.1%}")
        
        return churn_prob
    
    def plot_roc_curve(self, save_path=None):
        """
        Plot ROC curve
        """
        y_pred_proba = self.model.predict_proba(self.X_test_scaled)[:, 1]
        fpr, tpr, thresholds = roc_curve(self.y_test, y_pred_proba)
        roc_auc = roc_auc_score(self.y_test, y_pred_proba)
        
        plt.figure(figsize=(10, 6))
        plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {roc_auc:.3f})')
        plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random Classifier')
        plt.xlim([0.0, 1.0])
        plt.ylim([0.0, 1.05])
        plt.xlabel('False Positive Rate', fontsize=12, fontweight='bold')
        plt.ylabel('True Positive Rate', fontsize=12, fontweight='bold')
        plt.title('ROC Curve - Churn Prediction Model', fontsize=14, fontweight='bold')
        plt.legend(loc="lower right")
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()


# Main execution
if __name__ == "__main__":
    print("🤖 Customer Churn Prediction Model")
    print("="*60)
    print("\n📝 Usage Instructions:")
    print("  1. Load data: analysis = ECommerceAnalysis('path/to/csv')")
    print("  2. Create model: churn = ChurnPredictionModel(analysis.data)")
    print("  3. Train: churn.train_model()")
    print("  4. Evaluate: churn.evaluate_model()")
    print("  5. Feature importance: churn.get_feature_importance()")
    print("  6. Predict: churn.predict_for_customer(recency=30, frequency=1, monetary=100, avg_rating=4.0, on_time_rate=0.9)")
    print("  7. Plot ROC: churn.plot_roc_curve()")