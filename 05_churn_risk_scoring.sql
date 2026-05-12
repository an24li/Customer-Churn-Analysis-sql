-- ============================================
-- Advanced Churn Risk Score (1-10)
- Uses multiple behavioral indicators
- Production-ready scoring algorithm
-- ============================================

-- Create risk scoring table
CREATE TABLE customer_risk_scores AS
WITH customer_behavior AS (
    SELECT 
        c.customer_id,
        c.tenure_months,
        c.contract_type,
        c.monthly_charges,
        c.churned,
        c.churn_reason,
        
        -- Usage metrics (last 90 days)
        COALESCE(COUNT(u.activity_id), 0) as total_activities,
        COALESCE(AVG(u.calls_made), 0) as avg_calls,
        COALESCE(AVG(u.data_used_gb), 0) as avg_data_usage,
        COALESCE(AVG(u.sms_sent), 0) as avg_sms,
        COALESCE(SUM(u.support_tickets), 0) as total_support_tickets,
        COALESCE(AVG(u.payment_delay_days), 0) as avg_payment_delay,
        COALESCE(SUM(u.complaints_filed), 0) as total_complaints,
        
        -- Last activity recency
        MAX(u.activity_date) as last_activity_date
        
    FROM customers c
    LEFT JOIN usage_activity u ON c.customer_id = u.customer_id
        AND u.activity_date >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY c.customer_id, c.tenure_months, c.contract_type, 
             c.monthly_charges, c.churned, c.churn_reason
)

SELECT 
    customer_id,
    tenure_months,
    contract_type,
    monthly_charges,
    
    -- Calculate individual risk factors (1-10 scale)
    CASE 
        WHEN contract_type = 'Monthly' THEN 9
        WHEN contract_type = '1 Year' THEN 4
        ELSE 1
    END as risk_contract_factor,
    
    CASE 
        WHEN tenure_months < 3 THEN 10
        WHEN tenure_months < 6 THEN 8
        WHEN tenure_months < 12 THEN 5
        WHEN tenure_months < 24 THEN 3
        ELSE 1
    END as risk_tenure_factor,
    
    CASE 
        WHEN avg_calls < 10 THEN 8
        WHEN avg_calls < 30 THEN 4
        ELSE 1
    END as risk_low_usage_factor,
    
    CASE 
        WHEN total_support_tickets > 5 THEN 10
        WHEN total_support_tickets > 2 THEN 6
        WHEN total_support_tickets > 0 THEN 3
        ELSE 0
    END as risk_support_factor,
    
    CASE 
        WHEN avg_payment_delay > 15 THEN 10
        WHEN avg_payment_delay > 7 THEN 6
        WHEN avg_payment_delay > 0 THEN 3
        ELSE 0
    END as risk_payment_factor,
    
    CASE 
        WHEN total_complaints > 2 THEN 10
        WHEN total_complaints > 0 THEN 5
        ELSE 0
    END as risk_complaint_factor,
    
    -- Days since last activity
    CASE 
        WHEN last_activity_date IS NULL THEN 10
        WHEN CURRENT_DATE - last_activity_date > 30 THEN 9
        WHEN CURRENT_DATE - last_activity_date > 14 THEN 5
        ELSE 0
    END as risk_inactivity_factor,

    -- Previously churned? Flag for sentiment
    FALSE as previously_churned  -- Would need historical data
    
FROM customer_behavior;

-- Calculate final risk score (1-10, higher = higher churn risk)
ALTER TABLE customer_risk_scores ADD COLUMN final_risk_score INTEGER;

UPDATE customer_risk_scores 
SET final_risk_score = LEAST(10, ROUND(
    (risk_contract_factor * 0.25 +
     risk_tenure_factor * 0.20 +
     risk_low_usage_factor * 0.15 +
     risk_support_factor * 0.15 +
     risk_payment_factor * 0.15 +
     risk_complaint_factor * 0.05 +
     risk_inactivity_factor * 0.05)::NUMERIC, 0
));

-- Create risk categories
ALTER TABLE customer_risk_scores 
ADD COLUMN risk_category VARCHAR(20);

UPDATE customer_risk_scores 
SET risk_category = CASE
    WHEN final_risk_score >= 8 THEN 'Critical'
    WHEN final_risk_score >= 6 THEN 'High'
    WHEN final_risk_score >= 4 THEN 'Medium'
    ELSE 'Low'
END;

-- View high-risk customers (for retention team)
CREATE VIEW high_risk_customers AS
SELECT 
    crs.customer_id,
    crs.final_risk_score,
    crs.risk_category,
    crs.contract_type,
    crs.tenure_months,
    crs.monthly_charges,
    cm.churned,
    cm.churn_reason
FROM customer_risk_scores crs
JOIN customers cm ON crs.customer_id = cm.customer_id
WHERE crs.final_risk_score >= 6 
    AND cm.churned = FALSE
ORDER BY crs.final_risk_score DESC;
