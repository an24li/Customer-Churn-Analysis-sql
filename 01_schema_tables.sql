
-- ============================================
-- 1. Customers Dimension Tabl-- ============================================
CREATE TABLE customers (
    customer_id          VARCHAR(50) PRIMARY KEY,
    gender              VARCHAR(10),
    age                 INTEGER,
    married             BOOLEAN,
    dependents          INTEGER,
    education_level     VARCHAR(30),
    occupation          VARCHAR(50),
    city                VARCHAR(100),
    state               VARCHAR(50),
    tenure_months       INTEGER,        -- How long they've been customer
    contract_type       VARCHAR(20),    -- Monthly, 1 Year, 2 Year
    payment_method      VARCHAR(30),    -- Credit Card, Bank Transfer, etc.
    monthly_charges     DECIMAL(10,2),
    total_charges       DECIMAL(10,2),
    churned             BOOLEAN,        -- TRUE = left, FALSE = active
    churn_date          DATE,
    churn_reason        TEXT,
    signup_date         DATE,
    last_login_date     DATE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 2. Usage Activity Fact Table
-- ============================================
CREATE TABLE usage_activity (
    activity_id         SERIAL PRIMARY KEY,
    customer_id         VARCHAR(50) REFERENCES customers(customer_id),
    activity_date       DATE,
    calls_made          INTEGER DEFAULT 0,
    data_used_gb        DECIMAL(5,2) DEFAULT 0,
    sms_sent            INTEGER DEFAULT 0,
    support_tickets     INTEGER DEFAULT 0,
    payment_delay_days  INTEGER DEFAULT 0,
    complaints_filed    INTEGER DEFAULT 0
);

-- ============================================
-- 3. Monthly Billing History
-- ============================================
CREATE TABLE billing_history (
    billing_id          SERIAL PRIMARY KEY,
    customer_id         VARCHAR(50) REFERENCES customers(customer_id),
    billing_month       DATE,
    amount_due          DECIMAL(10,2),
    amount_paid         DECIMAL(10,2),
    payment_status      VARCHAR(20),    -- Paid, Partial, Late, Default
    payment_date        DATE
);

-- ============================================
-- Indexes for performance (will add indexes in step 7)
-- ============================================
CREATE INDEX idx_customers_churned ON customers(churned);
CREATE INDEX idx_customers_tenure ON customers(tenure_months);
CREATE INDEX idx_usage_customer_date ON usage_activity(customer_id, activity_date);
CREATE INDEX idx_billing_customer_month ON billing_history(customer_id, billing_month);
