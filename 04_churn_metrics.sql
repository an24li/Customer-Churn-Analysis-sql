-- ============================================
-- Business KPIs & Churn Metrics
-- ============================================

-- 1. Overall Churn Rate
SELECT 
    COUNT(*) as total_customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) as churned_customers,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) as churn_rate_percent
FROM customers;

-- 2. Churn Rate by Contract Type (Critical insight)
SELECT 
    contract_type,
    COUNT(*) as customers,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) as churned,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) as churn_rate,
    ROUND(AVG(monthly_charges), 2) as avg_monthly_charges
FROM customers
GROUP BY contract_type
ORDER BY churn_rate DESC;

-- 3. Churn by Tenure Period
SELECT 
    CASE 
        WHEN tenure_months <= 3 THEN '0-3 months'
        WHEN tenure_months <= 6 THEN '4-6 months'
        WHEN tenure_months <= 12 THEN '7-12 months'
        WHEN tenure_months <= 24 THEN '13-24 months'
        ELSE '25+ months'
    END as tenure_group,
    COUNT(*) as total,
    SUM(CASE WHEN churned THEN 1 ELSE 0 END) as churned,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) as churn_rate
FROM customers
GROUP BY tenure_group
ORDER BY MIN(tenure_months);

-- 4. Top Churn Reasons
SELECT 
    churn_reason,
    COUNT(*) as churned_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage_of_churn
FROM customers
WHERE churned = TRUE
GROUP BY churn_reason
ORDER BY churned_customers DESC
LIMIT 5;

-- 5. Churn Rate by Payment Method
SELECT 
    payment_method,
    COUNT(*) as total_customers,
    ROUND(AVG(monthly_charges), 2) as avg_charge,
    ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2) as churn_rate
FROM customers
GROUP BY payment_method
ORDER BY churn_rate DESC;

-- 6. Monthly Churn Trend (last 12 months)
WITH monthly_churn AS (
    SELECT 
        DATE_TRUNC('month', churn_date) as churn_month,
        COUNT(*) as churned_count
    FROM customers
    WHERE churned = TRUE 
        AND churn_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY DATE_TRUNC('month', churn_date)
)
SELECT 
    churn_month::DATE,
    churned_count,
    SUM(churned_count) OVER (ORDER BY churn_month) as cumulative_churn
FROM monthly_churn
ORDER BY churn_month DESC;
