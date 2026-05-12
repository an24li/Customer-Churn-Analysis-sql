-- ============================================
-- Data Cleaning Operations
-- Handle NULLs, inconsistencies, duplicates
-- ============================================

-- 1. Check for NULLs in critical columns
SELECT 
    'customers' as table_name,
    COUNT(*) FILTER (WHERE customer_id IS NULL) as null_customer_id,
    COUNT(*) FILTER (WHERE tenure_months IS NULL) as null_tenure,
    COUNT(*) FILTER (WHERE monthly_charges IS NULL) as null_charges
FROM customers
UNION ALL
SELECT 
    'usage_activity',
    COUNT(*) FILTER (WHERE customer_id IS NULL),
    COUNT(*) FILTER (WHERE calls_made IS NULL),
    COUNT(*) FILTER (WHERE data_used_gb IS NULL)
FROM usage_activity;

-- 2. Fix NULL values (replace with defaults)
UPDATE customers 
SET 
    dependents = COALESCE(dependents, 0),
    churn_reason = COALESCE(churn_reason, 'Not applicable'),
    tenure_months = COALESCE(tenure_months, 0),
    monthly_charges = COALESCE(monthly_charges, 0),
    total_charges = COALESCE(total_charges, monthly_charges * tenure_months);

-- 3. Fix negative or unrealistic values
UPDATE customers 
SET 
    age = CASE WHEN age < 18 OR age > 100 THEN 35 ELSE age END,
    monthly_charges = ABS(monthly_charges),
    tenure_months = ABS(tenure_months);

-- 4. Standardize churn_reason text (remove typos, uppercase)
UPDATE customers 
SET churn_reason = INITCAP(TRIM(churn_reason));

-- Combine similar reasons
UPDATE customers 
SET churn_reason = 'High Price'
WHERE churn_reason IN ('Price Too High', 'Price High', 'Expensive');

-- 5. Find and mark duplicate customers (if any)
WITH duplicates AS (
    SELECT customer_id, COUNT(*) 
    FROM customers 
    GROUP BY customer_id 
    HAVING COUNT(*) > 1
)
DELETE FROM customers 
WHERE customer_id IN (SELECT customer_id FROM duplicates);

-- 6. Create clean view for reporting
CREATE OR REPLACE VIEW clean_customers AS
SELECT 
    customer_id,
    gender,
    age,
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age < 35 THEN '25-34'
        WHEN age < 50 THEN '35-49'
        ELSE '50+'
    END as age_group,
    married,
    dependents,
    education_level,
    tenure_months,
    CASE 
        WHEN tenure_months < 6 THEN 'New (<6 months)'
        WHEN tenure_months < 12 THEN 'Recent (6-12 months)'
        WHEN tenure_months < 24 THEN 'Established (1-2 years)'
        ELSE 'Loyal (2+ years)'
    END as tenure_segment,
    contract_type,
    monthly_charges,
    total_charges,
    churned,
    churn_reason,
    signup_date,
    CURRENT_DATE - signup_date as days_as_customer
FROM customers;
