-- =========================================================
-- RETAIL MARKET PERFORMANCE ANALYSIS
-- PART 2: SILVER LAYER — CLEANED, TYPED & CONSTRAINT SCHEMAS
-- =========================================================

-- ---------------------------------------------------------
-- 1) SCHEMA ENFORCEMENT & CONSTRAINTS
-- ---------------------------------------------------------

CREATE TABLE silver.dim_customers (
    customer_id          INT PRIMARY KEY,
    customer_code        TEXT NOT NULL,
    gender               TEXT,
    age                  INT CHECK (age >= 0),
    country              TEXT,
    city                 TEXT,
    segment              TEXT,
    signup_date          DATE,
    acquisition_channel  TEXT,
    loyalty_contact_pref TEXT
);

CREATE TABLE silver.dim_products (
    product_id       INT PRIMARY KEY,
    product_name     TEXT NOT NULL,
    category         TEXT NOT NULL,
    subcategory      TEXT,
    brand            TEXT,
    base_price       NUMERIC(12,2) CHECK (base_price >= 0),
    unit_cost        NUMERIC(12,2) CHECK (unit_cost >= 0),
    launch_date      DATE,
    reorder_priority TEXT
);

CREATE TABLE silver.dim_stores (
    store_id   INT PRIMARY KEY,
    store_code TEXT NOT NULL,
    country    TEXT NOT NULL,
    city       TEXT NOT NULL,
    region     TEXT,
    store_type TEXT,
    size_sqm   INT CHECK (size_sqm >= 0),
    open_date  DATE
);

CREATE TABLE silver.dim_date (
    date       DATE PRIMARY KEY,
    date_key   INT UNIQUE NOT NULL,
    YEAR       INT NOT NULL,
    quarter    TEXT NOT NULL,
    MONTH      INT NOT NULL CHECK (MONTH BETWEEN 1 AND 12),
    month_name TEXT NOT NULL,
    week       INT NOT NULL CHECK (week BETWEEN 1 AND 53),
    DAY        INT NOT NULL CHECK (DAY BETWEEN 1 AND 31),
    day_name   TEXT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE silver.fact_sales (
    order_id        BIGINT PRIMARY KEY,
    order_date      DATE NOT NULL,
    customer_id     INT NOT NULL,
    product_id      INT NOT NULL,
    store_id        INT NOT NULL,
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    gross_revenue   NUMERIC(14,2) NOT NULL CHECK (gross_revenue >= 0),
    discount_amount NUMERIC(14,2) NOT NULL CHECK (discount_amount >= 0),
    net_revenue     NUMERIC(14,2) NOT NULL,
    total_cost      NUMERIC(14,2) NOT NULL CHECK (total_cost >= 0),
    profit          NUMERIC(14,2) NOT NULL,
    payment_method  TEXT,
    order_status    TEXT,
    sales_channel   TEXT,
    CONSTRAINT fk_sales_customer FOREIGN KEY (customer_id) REFERENCES silver.dim_customers(customer_id),
    CONSTRAINT fk_sales_product  FOREIGN KEY (product_id)  REFERENCES silver.dim_products(product_id),
    CONSTRAINT fk_sales_store    FOREIGN KEY (store_id)    REFERENCES silver.dim_stores(store_id),
    CONSTRAINT fk_sales_date     FOREIGN KEY (order_date)  REFERENCES silver.dim_date(date)
);

CREATE TABLE silver.fact_returns (
    return_id     INT PRIMARY KEY,
    order_id      BIGINT NOT NULL,
    return_date   DATE NOT NULL,
    customer_id   INT NOT NULL,
    product_id    INT NOT NULL,
    store_id      INT NOT NULL,
    returned_qty  INT NOT NULL CHECK (returned_qty > 0),
    refund_amount NUMERIC(14,2) NOT NULL CHECK (refund_amount >= 0),
    return_reason TEXT,
    CONSTRAINT fk_returns_order    FOREIGN KEY (order_id)    REFERENCES silver.fact_sales(order_id),
    CONSTRAINT fk_returns_customer FOREIGN KEY (customer_id) REFERENCES silver.dim_customers(customer_id),
    CONSTRAINT fk_returns_product  FOREIGN KEY (product_id)  REFERENCES silver.dim_products(product_id),
    CONSTRAINT fk_returns_store    FOREIGN KEY (store_id)    REFERENCES silver.dim_stores(store_id),
    CONSTRAINT fk_returns_date     FOREIGN KEY (return_date) REFERENCES silver.dim_date(date)
);

CREATE TABLE silver.fact_inventory_monthly (
    snapshot_month DATE NOT NULL,
    store_id       INT NOT NULL,
    product_id     INT NOT NULL,
    stock_on_hand  INT NOT NULL CHECK (stock_on_hand >= 0),
    reorder_point  INT NOT NULL CHECK (reorder_point >= 0),
    ending_stock   INT NOT NULL CHECK (ending_stock >= 0),
    PRIMARY KEY (snapshot_month, store_id, product_id),
    CONSTRAINT fk_inventory_store   FOREIGN KEY (store_id)   REFERENCES silver.dim_stores(store_id),
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES silver.dim_products(product_id)
);

-- ---------------------------------------------------------
-- 2) DATA POPULATION & TYPE TRANSFORMATION
-- ---------------------------------------------------------

INSERT INTO silver.dim_customers (
    customer_id, customer_code, gender, age, country, city,
    segment, signup_date, acquisition_channel, loyalty_contact_pref
)
SELECT
    customer_id::INT, customer_code, gender, age::INT,
    country, city, segment, signup_date::DATE,
    acquisition_channel, loyalty_contact_pref
FROM bronze.dim_customers_raw;

INSERT INTO silver.dim_products (
    product_id, product_name, category, subcategory, brand,
    base_price, unit_cost, launch_date, reorder_priority
)
SELECT
    product_id::INT, product_name, category, subcategory, brand,
    base_price::NUMERIC(12,2), unit_cost::NUMERIC(12,2),
    launch_date::DATE, reorder_priority
FROM bronze.dim_products_raw;

INSERT INTO silver.dim_stores (
    store_id, store_code, country, city, region,
    store_type, size_sqm, open_date
)
SELECT
    store_id::INT, store_code, country, city, region,
    store_type, size_sqm::INT, open_date::DATE
FROM bronze.dim_stores_raw;

INSERT INTO silver.dim_date (
    date, date_key, YEAR, quarter, MONTH, month_name,
    week, DAY, day_name, is_weekend
)
SELECT
    date::DATE, date_key::INT, YEAR::INT, quarter,
    MONTH::INT, month_name, week::INT, DAY::INT,
    day_name, is_weekend::BOOLEAN
FROM bronze.dim_date_raw;

-- Extend calendar tracking for future-dated operations
INSERT INTO silver.dim_date (
    date, date_key, YEAR, quarter, MONTH, month_name,
    week, DAY, day_name, is_weekend
)
SELECT
    gs::DATE,
    TO_CHAR(gs, 'YYYYMMDD')::INT,
    EXTRACT(YEAR    FROM gs)::INT,
    'Q' || EXTRACT(QUARTER FROM gs)::INT,
    EXTRACT(MONTH   FROM gs)::INT,
    TRIM(TO_CHAR(gs, 'Month')),
    EXTRACT(WEEK    FROM gs)::INT,
    EXTRACT(DAY     FROM gs)::INT,
    TRIM(TO_CHAR(gs, 'Day')),
    CASE WHEN EXTRACT(ISODOW FROM gs) IN (6,7) THEN TRUE ELSE FALSE END
FROM generate_series('2026-01-01'::DATE, '2026-12-31'::DATE, INTERVAL '1 day') gs
ON CONFLICT (date) DO NOTHING;

INSERT INTO silver.fact_sales (
    order_id, order_date, customer_id, product_id, store_id,
    quantity, unit_price, gross_revenue, discount_amount,
    net_revenue, total_cost, profit, payment_method,
    order_status, sales_channel
)
SELECT
    order_id::BIGINT, order_date::DATE, customer_id::INT,
    product_id::INT, store_id::INT, quantity::INT,
    unit_price::NUMERIC(12,2), gross_revenue::NUMERIC(14,2),
    discount_amount::NUMERIC(14,2), net_revenue::NUMERIC(14,2),
    total_cost::NUMERIC(14,2), profit::NUMERIC(14,2),
    payment_method, order_status, sales_channel
FROM bronze.fact_sales_raw;

INSERT INTO silver.fact_returns (
    return_id, order_id, return_date, customer_id, product_id,
    store_id, returned_qty, refund_amount, return_reason
)
SELECT
    return_id::INT, order_id::BIGINT, return_date::DATE,
    customer_id::INT, product_id::INT, store_id::INT,
    returned_qty::INT, refund_amount::NUMERIC(14,2), return_reason
FROM bronze.fact_returns_raw;

INSERT INTO silver.fact_inventory_monthly (
    snapshot_month, store_id, product_id,
    stock_on_hand, reorder_point, ending_stock
)
SELECT
    snapshot_month::DATE, store_id::INT, product_id::INT,
    stock_on_hand::INT, reorder_point::INT, ending_stock::INT
FROM bronze.fact_inventory_monthly_raw;

-- ---------------------------------------------------------
-- 3) PERFORMANCE TIMING INDEXES
-- ---------------------------------------------------------
CREATE INDEX idx_sales_order_date    ON silver.fact_sales(order_date);
CREATE INDEX idx_sales_customer_id   ON silver.fact_sales(customer_id);
CREATE INDEX idx_sales_product_id    ON silver.fact_sales(product_id);
CREATE INDEX idx_sales_store_id      ON silver.fact_sales(store_id);
CREATE INDEX idx_sales_status        ON silver.fact_sales(order_status);
CREATE INDEX idx_sales_channel       ON silver.fact_sales(sales_channel);

CREATE INDEX idx_returns_order_id    ON silver.fact_returns(order_id);
CREATE INDEX idx_returns_return_date ON silver.fact_returns(return_date);
CREATE INDEX idx_returns_customer_id ON silver.fact_returns(customer_id);
CREATE INDEX idx_returns_product_id  ON silver.fact_returns(product_id);
CREATE INDEX idx_returns_store_id    ON silver.fact_returns(store_id);

CREATE INDEX idx_inventory_store_id  ON silver.fact_inventory_monthly(store_id);
CREATE INDEX idx_inventory_product_id ON silver.fact_inventory_monthly(product_id);
CREATE INDEX idx_inventory_month      ON silver.fact_inventory_monthly(snapshot_month);
