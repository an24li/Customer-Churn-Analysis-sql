-- ============================================
-- Advanced Analytics with Window Functions
-- Month-over-month trends, rankings, cohorts
-- ============================================

-- 1. Customer Lifetime Value (LTV) with running total
SELECT 
    customer_id,
    signup_date,
    monthly_charges,
    SUM(monthly_charges) OVER (PARTITION BY customer_id ORDER BY signup_date) as running_ltv,
    RANK() OVER (ORDER BY monthly_charges DESC) as spend_rank,
    NTILE(10) OVER (ORDER BY monthly_charges) as spending_decile
FROM customers
WHERE churned = FALSE
LIMIT 20;

-- 2. Month-over-Month Churn Rate Change
WITH monthly_data AS (
    SELECT 
        DATE_TRUNC('month', signup_date) as cohort_month,
        COUNT(*) as total_signups,
        SUM(CASE WHEN churned THEN 1 ELSE 0 END) as churned_count
    FROM customers
    GROUP BY DATE_TRUNC('month', signup_date)
)
SELECT 
    cohort_month::DATE,
    total_signups,
    churned_count,
    ROUND(100.0 * churned_count / total_signups, 2) as churn_rate,
    LAG(ROUND(100.0 * churned_count / total_signups, 2)) OVER (ORDER BY cohort_month) as prev_month_churn,
    ROUND(100.0 * churned_count / total_signups - 
          LAG(ROUND(100.0 * churned_count / total_signups, 2)) OVER (ORDER BY cohort_month), 2) as mom_change
FROM monthly_data
ORDER BY cohort_month DESC;

-- 3. Customer Cohort Retention Analysis (Critical for Cognizant)
WITH cohorts AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', signup_date) as cohort_month,
        tenure_months
    FROM customers
),
cohort_retention AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) as total_customers,
        COUNT(DISTINCT CASE WHEN tenure_months >= 1 THEN customer_id END) as retained_1month,
        COUNT(DISTINCT CASE WHEN tenure_months >= 3 THEN customer_id END) as retained_3month,
        COUNT(DISTINCT CASE WHEN tenure_months >= 6 THEN customer_id END) as retained_6month,
        COUNT(DISTINCT CASE WHEN tenure_months >= 12 THEN customer_id END) as retained_12month
    FROM cohorts
    GROUP BY cohort_month
)
SELECT 
    cohort_month::DATE,
    total_customers,
    ROUND(100.0 * retained_1month / total_customers, 2) as retention_rate_1m,
    ROUND(100.0 * retained_3month / total_customers, 2) as retention_rate_3m,
    ROUND(100.0 * retained_6month / total_customers, 2) as retention_rate_6m,
    ROUND(100.0 * retained_12month / total_customers, 2) as retention_rate_12m
FROM cohort_retention
ORDER BY cohort_month DESC
LIMIT 10;

-- 4. Find customers with declining usage (leading churn indicator)
WITH monthly_usage AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', activity_date) as usage_month,
        AVG(data_used_gb) as avg_data_usage
    FROM usage_activity
    WHERE activity_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY customer_id, DATE_TRUNC('month', activity_date)
),
usage_trend AS (
    SELECT 
        customer_id,
        usage_month,
        avg_data_usage,
        LAG(avg_data_usage) OVER (PARTITION BY customer_id ORDER BY usage_month) as prev_month_usage,
        (avg_data_usage - LAG(avg_data_usage) OVER (PARTITION BY customer_id ORDER BY usage_month)) as usage_change
    FROM monthly_usage
)
SELECT 
    customer_id,
    MAX(usage_month) as latest_month,
    ROUND(AVG(usage_change) FILTER (WHERE usage_change IS NOT NULL), 2) as avg_monthly_decline
FROM usage_trend
GROUP BY customer_id
HAVING AVG(usage_change) < -10  -- Dropping more than 10GB/month
ORDER BY avg_monthly_decline ASC
LIMIT 50;
