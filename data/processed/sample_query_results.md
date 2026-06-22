# Sample Query Results

Sample outputs from key SQL queries to preview findings without running the full database.

---

## Query 1.1 — Overall Business Health

| Metric | Value |
|--------|-------|
| Total Orders | 99,441 |
| Total Customers | 99,441 |
| Total Revenue | R$15,843,553 |
| Avg Order Value | R$140.64 |
| Delivered Orders | 96,478 |
| Delivery Success Rate | 97.01% |

---

## Query 2.1 — Repeat Purchase Rate

| Purchase Count | Customers | Percentage |
|----------------|-----------|------------|
| 1 | 99,441 | 100% |

**Key Finding: 100% of customers bought only once — zero repeat customers.**

---

## Query 2.2 — Customer Churn Analysis

| Status | Customers | Avg CLV | Total Value |
|--------|-----------|---------|-------------|
| Active | 9,789 | R$159.55 | R$1.54M |
| Dormant | 18,636 | R$166.94 | R$3.1M |
| At Risk | 41,118 | R$157.07 | R$6.4M |
| Churned | 29,898 | R$161.76 | R$4.7M |

---

## Query 2.6 — New vs Returning Customers

| Type | Customers | Avg CLV | Total Revenue |
|------|-----------|---------|---------------|
| New Customers | 89,638 | R$150.75 | R$13.39M |
| Returning Customers | 9,803 | R$249.70 | R$2.44M |

**Key Finding: Returning customers spend 65% more — R$249 vs R$150.**

---

## Query 3.1 — Top Products by Revenue

| Category | Orders | Revenue | Avg Price |
|----------|--------|---------|-----------|
| Beauty & Health | 8,836 | R$1.25M | R$130 |
| Watches & Gifts | 5,624 | R$1.20M | R$201 |
| Bed & Bath | 9,417 | R$1.03M | R$93 |
| Sports & Leisure | 7,720 | R$988K | R$114 |
| IT Accessories | 6,689 | R$911K | R$117 |

---

## Query 4.1 — Order Fulfillment Performance

| Status | Orders | Avg Days | Late Deliveries |
|--------|--------|----------|-----------------|
| Delivered | 96,478 | 12.1 days | 7,826 |
| Canceled | 625 | 19.8 days | 1 |

---

## Query 4.3 — Payment Method Analysis

| Payment Type | Orders | Total Value | Avg Installments |
|--------------|--------|-------------|------------------|
| Credit Card | 76,795 | R$12.54M | 3.5 |
| Boleto | 19,784 | R$2.86M | 1 |
| Voucher | 5,775 | R$379K | 1 |
| Debit Card | 1,529 | R$217K | 1 |

---

## Query 5.3 — Customer Value vs Cost

| Metric | Value |
|--------|-------|
| Total Customers | 98,666 |
| Total Revenue | R$13,591,643 |
| Total Shipping Costs | R$2,251,909 |
| Total Profit | R$11,339,734 |
| Profit Per Customer | R$114.93 |

---

## Query 5.7 — Lost Revenue Impact

| Status | Orders | Est. Lost Revenue |
|--------|--------|-------------------|
| Canceled | 625 |