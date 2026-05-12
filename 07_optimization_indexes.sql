-- ============================================
-- Query Optimization & Indexing Strategy
-- For 1M+ row scale
-- ============================================

-- 1. Indexes for most common WHERE clauses
CREATE INDEX CONCURRENTLY idx_customers_churned_tenure 
ON customers(churned, tenure_months) 
INCLUDE (monthly_charges, contract_type);

CREATE INDEX CONCURRENTLY idx_customers_signup_date 
ON customers(signup_date DESC);

CREATE INDEX CONCURRENTLY idx_usage_customer_activity 
ON usage_activity(customer_id, activity_date DESC);

-- 2. Partial index for active customers only (saves space)
CREATE INDEX idx_active_customers 
ON customers(customer_id, tenure_months) 
WHERE churned = FALSE;

-- 3. Composite index for risk scoring queries
CREATE INDEX idx_risk_scoring 
ON customers(contract_type, tenure_months, monthly_charges) 
WHERE churned = FALSE;

-- 4. Analyze query performance (show this in your README)
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT * FROM customers WHERE churned = TRUE AND tenure_months < 6;

-- 5. Create materialized view for daily dashboards (faster than queries)
CREATE MATERIALIZED VIEW mv_daily_churn_metrics AS
SELECT 
    CURRENT_DATE as snapshot_date,
    COUNT(*) as total_customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) as total_churned,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_charges), 2) as avg_revenue_per_customer
FROM customers;

-- Refresh daily (run via cron or pg_cron)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_churn_metrics;

-- 6. Partitioning strategy for large tables (future-proofing)
-- For 10M+ rows, partition by date
CREATE TABLE usage_activity_partitioned (
    LIKE usage_activity INCLUDING DEFAULTS
) PARTITION BY RANGE (activity_date);

-- Create monthly partitions (example)
CREATE TABLE usage_activity_2024_01 PARTITION OF usage_activity_partitioned
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
