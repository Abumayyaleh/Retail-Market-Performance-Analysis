-- =========================================================
-- RETAIL MARKET PERFORMANCE ANALYSIS
-- PART 1: BRONZE LAYER — ENVIRONMENT SETUP & RAW INGESTION
-- =========================================================

DROP SCHEMA IF EXISTS silver CASCADE;
DROP SCHEMA IF EXISTS bronze CASCADE;

CREATE SCHEMA bronze;
CREATE SCHEMA silver;

-- ---------------------------------------------------------
-- 1) BRONZE LAYER TABLES (Raw Landing Zone)
-- ---------------------------------------------------------

CREATE TABLE bronze.fact_sales_raw (
    order_id        TEXT,
    order_date      TEXT,
    customer_id     TEXT,
    product_id      TEXT,
    store_id        TEXT,
    quantity        TEXT,
    unit_price      TEXT,
    gross_revenue   TEXT,
    discount_amount TEXT,
    net_revenue     TEXT,
    total_cost      TEXT,
    profit          TEXT,
    payment_method  TEXT,
    order_status    TEXT,
    sales_channel   TEXT
);

CREATE TABLE bronze.fact_returns_raw (
    return_id     TEXT,
    order_id      TEXT,
    return_date   TEXT,
    customer_id   TEXT,
    product_id    TEXT,
    store_id      TEXT,
    returned_qty  TEXT,
    refund_amount TEXT,
    return_reason TEXT
);

CREATE TABLE bronze.fact_inventory_monthly_raw (
    snapshot_month TEXT,
    store_id       TEXT,
    product_id     TEXT,
    stock_on_hand  TEXT,
    reorder_point  TEXT,
    ending_stock   TEXT
);

CREATE TABLE bronze.dim_customers_raw (
    customer_id          TEXT,
    customer_code        TEXT,
    gender               TEXT,
    age                  TEXT,
    country              TEXT,
    city                 TEXT,
    segment              TEXT,
    signup_date          TEXT,
    acquisition_channel  TEXT,
    loyalty_contact_pref TEXT
);

CREATE TABLE bronze.dim_products_raw (
    product_id       TEXT,
    product_name     TEXT,
    category         TEXT,
    subcategory      TEXT,
    brand            TEXT,
    base_price       TEXT,
    unit_cost        TEXT,
    launch_date      TEXT,
    reorder_priority TEXT
);

CREATE TABLE bronze.dim_stores_raw (
    store_id   TEXT,
    store_code TEXT,
    country    TEXT,
    city       TEXT,
    region     TEXT,
    store_type TEXT,
    size_sqm   TEXT,
    open_date  TEXT
);

CREATE TABLE bronze.dim_date_raw (
    date       TEXT,
    date_key   TEXT,
    YEAR       TEXT,
    quarter    TEXT,
    MONTH      TEXT,
    month_name TEXT,
    week       TEXT,
    DAY        TEXT,
    day_name   TEXT,
    is_weekend TEXT
);

-- ---------------------------------------------------------
-- 2) CSV BULK LOAD
-- ---------------------------------------------------------
COPY bronze.fact_sales_raw             FROM '/your/path/fact_sales.csv'             DELIMITER ',' CSV HEADER;
COPY bronze.fact_returns_raw           FROM '/your/path/fact_returns.csv'           DELIMITER ',' CSV HEADER;
COPY bronze.fact_inventory_monthly_raw FROM '/your/path/fact_inventory_monthly.csv' DELIMITER ',' CSV HEADER;
COPY bronze.dim_customers_raw          FROM '/your/path/dim_customers.csv'          DELIMITER ',' CSV HEADER;
COPY bronze.dim_products_raw           FROM '/your/path/dim_products.csv'           DELIMITER ',' CSV HEADER;
COPY bronze.dim_stores_raw             FROM '/your/path/dim_stores.csv'             DELIMITER ',' CSV HEADER;
COPY bronze.dim_date_raw               FROM '/your/path/dim_date.csv'               DELIMITER ',' CSV HEADER;
