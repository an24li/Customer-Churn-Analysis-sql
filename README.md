# Customer Churn Analysis - Cognizant Portfolio Project

## 🎯 Business Problem
Reduce customer churn by 25% through data-driven retention strategies.

## 📊 Key Results
- **26.5%** overall churn rate identified
- **$2.4M** annual revenue at risk
- **Monthly contract customers** have 8x higher churn than 2-year contracts
- **First 3 months** critical period (40% of churn happens here)

## 🛠️ Technical Stack
- PostgreSQL 14+
- Advanced SQL: Window Functions, CTEs, Materialized Views
- Query optimization (EXPLAIN ANALYZE, indexes)
- 50,000+ rows mock data

## 📁 Files
| File | Description |
|------|-------------|
| 01_schema_tables.sql | Database design |
| 02_fake_data.sql | Mock data generation |
| 03_data_cleaning.sql | NULLs, duplicates, standardization |
| 04_churn_metrics.sql | Business KPIs |
| 05_churn_risk_scoring.sql | ML-like risk scoring (1-10) |
| 06_window_functions.sql | Time-series & cohort analysis |
| 07_optimization_indexes.sql | Performance tuning |
| 08_final_insights.sql | Executive dashboard |

## 🚀 How to Run
```bash
psql -U postgres -f 01_schema_tables.sql
psql -U postgres -f 02_fake_data.sql
psql -U postgres -f 03_data_cleaning.sql
# ... rest in order
