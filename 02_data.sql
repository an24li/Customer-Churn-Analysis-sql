-- ============================================
-- Generate 50,000 mock customers
-- Run this using \i 02_fake_data.sql in psql
-- Or use any database GUI
-- ============================================

INSERT INTO customers (customer_id, gender, age, married, dependents, 
                      education_level, occupation, city, state, 
                      tenure_months, contract_type, payment_method,
                      monthly_charges, total_charges, churned, 
                      churn_date, churn_reason, signup_date, last_login_date)
SELECT 
    'CUST' || LPAD(generate_series::TEXT, 6, '0'),
    CASE WHEN random() < 0.5 THEN 'Male' ELSE 'Female' END,
    (random() * 50 + 18)::INT,  -- Age 18-68
    random() < 0.6,
    (random() * 3)::INT,
    CASE floor(random() * 5)::INT
        WHEN 0 THEN 'High School'
        WHEN 1 THEN 'Bachelor'
        WHEN 2 THEN 'Master'
        WHEN 3 THEN 'PhD'
        ELSE 'Associate'
    END,
    CASE floor(random() * 6)::INT
        WHEN 0 THEN 'Engineer'
        WHEN 1 THEN 'Teacher'
        WHEN 2 THEN 'Doctor'
        WHEN 3 THEN 'Business Owner'
        WHEN 4 THEN 'Retired'
        ELSE 'Student'
    END,
    (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 
           'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'Austin'])[floor(random() * 10) + 1],
    (ARRAY['CA', 'TX', 'NY', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'MI'])[floor(random() * 10) + 1],
    (random() * 72)::INT,  -- Tenure up to 72 months
    CASE floor(random() * 3)::INT
        WHEN 0 THEN 'Monthly'
        WHEN 1 THEN '1 Year'
        ELSE '2 Year'
    END,
    CASE floor(random() * 4)::INT
        WHEN 0 THEN 'Credit Card'
        WHEN 1 THEN 'Bank Transfer'
        WHEN 2 THEN 'PayPal'
        ELSE 'Cash'
    END,
    (20 + random() * 100)::DECIMAL(10,2),
    (20 + random() * 100)::DECIMAL(10,2) * (random() * 50)::DECIMAL(10,2),
    random() < 0.265,  -- 26.5% churn rate (typical for telecom)
    NULL,  -- Will set for churned customers
    NULL,  -- Will set for churned customers
    CURRENT_DATE - ((random() * 72)::INT || ' months')::INTERVAL,
    CURRENT_DATE - ((random() * 30)::INT || ' days')::INTERVAL
FROM generate_series(1, 50000);

-- Update churn_date and churn_reason for churned customers
UPDATE customers 
SET 
    churn_date = signup_date + (tenure_months || ' months')::INTERVAL,
    churn_reason = CASE floor(random() * 7)::INT
        WHEN 0 THEN 'Price too high'
        WHEN 1 THEN 'Poor customer service'
        WHEN 2 THEN 'Competitor offer'
        WHEN 3 THEN 'Network issues'
        WHEN 4 THEN 'Moving to new area'
        WHEN 5 THEN 'No longer need service'
        ELSE 'Unknown'
    END
WHERE churned = TRUE;

-- Insert usage activity (3 rows per customer - last 3 months)
INSERT INTO usage_activity (customer_id, activity_date, calls_made, 
                           data_used_gb, sms_sent, support_tickets, 
                           payment_delay_days, complaints_filed)
SELECT 
    customer_id,
    CURRENT_DATE - (floor(random() * 90)::INT || ' days')::INTERVAL,
    (random() * 200)::INT,
    (random() * 50)::DECIMAL(5,2),
    (random() * 500)::INT,
    CASE WHEN random() < 0.1 THEN (random() * 5)::INT ELSE 0 END,
    CASE WHEN random() < 0.15 THEN (random() * 30)::INT ELSE 0 END,
    CASE WHEN random() < 0.05 THEN (random() * 3)::INT ELSE 0 END
FROM customers
CROSS JOIN generate_series(1, 3);
