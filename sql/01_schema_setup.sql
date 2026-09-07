-- ============================================================================
-- OLIST E-COMMERCE: DATABASE SCHEMA SETUP & DATA DEFINITION (DDL)
-- ============================================================================

-- Clean teardown (Reverse dependency order to avoid FK lock errors)
DROP VIEW IF EXISTS vw_products;

ALTER TABLE IF EXISTS order_reviews DROP CONSTRAINT IF EXISTS fk_order_reviews_orders;
ALTER TABLE IF EXISTS order_payments DROP CONSTRAINT IF EXISTS fk_order_payments_orders;
ALTER TABLE IF EXISTS order_items DROP CONSTRAINT IF EXISTS fk_order_items_orders;
ALTER TABLE IF EXISTS order_items DROP CONSTRAINT IF EXISTS fk_order_items_products;
ALTER TABLE IF EXISTS order_items DROP CONSTRAINT IF EXISTS fk_order_items_sellers;
ALTER TABLE IF EXISTS orders DROP CONSTRAINT IF EXISTS fk_orders_customers;

DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_category_name_translation;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS geolocation;
DROP TABLE IF EXISTS customers;

-- ============================================================================
-- 1. DIMENSION TABLES
-- ============================================================================

-- 1.1 Customer Dimension
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(50),
    customer_state VARCHAR(10)
);

-- 1.2 Geolocation Dimension
CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat NUMERIC(11, 8),
    geolocation_lng NUMERIC(11, 8),
    geolocation_city VARCHAR(50),
    geolocation_state VARCHAR(10)
);

-- 1.3 Seller Dimension
CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(50),
    seller_state VARCHAR(10)
);

-- 1.4 Product Dimension 
CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(75),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 1.5 Category Translation Dimension
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(75) PRIMARY KEY,
    product_category_name_english VARCHAR(75)
);

-- ============================================================================
-- 2. FACT TABLES
-- ============================================================================

-- 2.1 Orders Table
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date DATE
);

-- 2.2 Order Items Table (Composite PK)
CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price NUMERIC(10, 2),
    freight_value NUMERIC(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 2.3 Order Payments Table
CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value NUMERIC(10, 2)
);

-- 2.4 Order Reviews Table
CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATE,
    review_answer_timestamp TIMESTAMP
);

-- ============================================================================
-- 3. FOREIGN KEY CONSTRAINTS
-- ============================================================================

ALTER TABLE orders
    ADD CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_products
    FOREIGN KEY (product_id) REFERENCES products(product_id);

ALTER TABLE order_items
    ADD CONSTRAINT fk_order_items_sellers
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);

ALTER TABLE order_payments
    ADD CONSTRAINT fk_order_payments_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

ALTER TABLE order_reviews
    ADD CONSTRAINT fk_order_reviews_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id);

-- ============================================================================
-- 4. ANALYTICAL VIEWS (SILVER LAYER)
-- ============================================================================

CREATE VIEW vw_products AS
SELECT 
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category,
    p.product_weight_g
FROM products p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name;