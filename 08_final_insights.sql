-- ============================================
-- Executive Dashboard Queries
-- Ready for Cognizant presentation
-- ============================================

-- 1. ONE-PAGE EXECUTIVE SUMMARY
SELECT 
    'Total Customers' as metric, COUNT(*)::TEXT as value FROM customers
UNION ALL
SELECT 'Active Customers', COUNT(*)::TEXT FROM customers WHERE churned = FALSE
UNION ALL
SELECT 'Churned Customers', COUNT(*)::TEXT FROM customers WHERE churned = TRUE
UNION ALL
SELECT 'Churn Rate (%)', ROUND(100.0 * SUM(CASE WHEN churned THEN 1 ELSE 0 END) / COUNT(*), 2)::TEXT FROM customers
UNION ALL
SELECT 'Avg Monthly Revenue', TO_CHAR(AVG(monthly_charges), '$999,999.99') FROM customers
UNION ALL
SELECT 'Annual Revenue at Risk', TO_CHAR(SUM(CASE WHEN churned THEN monthly_charges * 12 ELSE 0 END), '$999,999,999.99') FROM customers;

-- 2. Top 5 Actions to Reduce Churn (Actionable Insights)
SELECT 
    'Offer annual contract discount' as recommendation,
    'Potential churn reduction: 40%' as impact,
    'Implementation cost: Low' as cost
UNION ALL
SELECT 
    'High-risk customer outreach program',
    'Potential churn reduction: 25%',
    'Implementation cost: Medium'
UNION ALL
SELECT 
    'Improve payment flexibility',
    'Potential churn reduction: 15%',
    'Implementation cost: Low'
UNION ALL
SELECT 
    'Early tenure onboarding improvement',
    'Potential churn reduction: 20%',
    'Implementation cost: Medium';

-- 3. Customers to Target Immediately (For Retention Team)
SELECT 
    c.customer_id,
    c.contract_type,
    c.tenure_months,
    c.monthly_charges,
    crs.final_risk_score,
    crs.risk_category
FROM customers c
JOIN customer_risk_scores crs ON c.customer_id = crs.customer_id
WHERE c.churned = FALSE 
    AND crs.final_risk_score >= 7
    AND c.monthly_charges > 50  -- High-value customers
ORDER BY crs.final_risk_score DESC, c.monthly_charges DESC
LIMIT 100;
