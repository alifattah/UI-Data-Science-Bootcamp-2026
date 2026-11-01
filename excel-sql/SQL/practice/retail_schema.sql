-- ============================================================
-- Data Analytics Bootcamp | Retail Practice Database
-- MySQL 8.4 | InnoDB | utf8mb4
--
-- This script creates a small retail schema and inserts sample data.
-- It does not drop an existing database or existing tables.
-- Run it once in your MySQL client, then use the tables in SQL lessons.
-- ============================================================

CREATE DATABASE IF NOT EXISTS bootcamp_retail
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE bootcamp_retail;

CREATE TABLE IF NOT EXISTS customers (
    customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL,
    city VARCHAR(80) NOT NULL,
    signup_date DATE NOT NULL,
    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_email (email)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS products (
    product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(60) NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (product_id),
    CONSTRAINT chk_products_price CHECK (unit_price >= 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    customer_id BIGINT UNSIGNED NOT NULL,
    order_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL,
    PRIMARY KEY (order_id),
    KEY ix_orders_customer_id (customer_id),
    KEY ix_orders_order_date (order_date),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (order_item_id),
    KEY ix_order_items_order_id (order_id),
    KEY ix_order_items_product_id (product_id),
    CONSTRAINT chk_order_items_quantity CHECK (quantity > 0),
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price >= 0),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Sample customers
INSERT INTO customers
    (customer_id, full_name, email, city, signup_date)
VALUES
    (1, 'Niloofar Ahmadi', 'niloofar@example.com', 'Isfahan', '2024-11-12'),
    (2, 'Arman Rezaei', 'arman@example.com', 'Shiraz', '2024-12-03'),
    (3, 'Sara Mohammadi', 'sara@example.com', 'Tehran', '2025-01-18'),
    (4, 'Pouya Karimi', 'pouya@example.com', 'Isfahan', '2025-02-02'),
    (5, 'Mina Hosseini', 'mina@example.com', 'Tabriz', '2025-02-20')
ON DUPLICATE KEY UPDATE
    full_name = VALUES(full_name),
    city = VALUES(city);

-- Sample products
INSERT INTO products
    (product_id, product_name, category, unit_price, active)
VALUES
    (101, 'Wireless Mouse', 'Accessories', 850000.00, TRUE),
    (102, 'Mechanical Keyboard', 'Accessories', 2450000.00, TRUE),
    (103, 'USB-C Hub', 'Accessories', 1750000.00, TRUE),
    (104, 'Laptop Stand', 'Office', 990000.00, TRUE),
    (105, 'Notebook Set', 'Stationery', 280000.00, TRUE)
ON DUPLICATE KEY UPDATE
    product_name = VALUES(product_name),
    category = VALUES(category),
    unit_price = VALUES(unit_price),
    active = VALUES(active);

-- Sample orders
INSERT INTO orders
    (order_id, customer_id, order_date, status)
VALUES
    (1001, 1, '2025-03-02 10:15:00', 'completed'),
    (1002, 2, '2025-03-04 14:20:00', 'completed'),
    (1003, 1, '2025-03-17 09:05:00', 'shipped'),
    (1004, 3, '2025-04-01 18:40:00', 'completed'),
    (1005, 4, '2025-04-09 12:10:00', 'cancelled'),
    (1006, 5, '2025-04-15 16:30:00', 'completed')
ON DUPLICATE KEY UPDATE
    customer_id = VALUES(customer_id),
    order_date = VALUES(order_date),
    status = VALUES(status);

-- Unit prices are stored on order_items as transaction-time prices.
-- This is intentional: a product's current price may change later.
INSERT INTO order_items
    (order_item_id, order_id, product_id, quantity, unit_price)
VALUES
    (1, 1001, 101, 2, 850000.00),
    (2, 1001, 105, 3, 280000.00),
    (3, 1002, 102, 1, 2450000.00),
    (4, 1002, 103, 1, 1750000.00),
    (5, 1003, 104, 2, 990000.00),
    (6, 1003, 101, 1, 850000.00),
    (7, 1004, 103, 2, 1750000.00),
    (8, 1004, 105, 4, 280000.00),
    (9, 1005, 102, 1, 2450000.00),
    (10, 1006, 101, 3, 850000.00),
    (11, 1006, 104, 1, 990000.00)
ON DUPLICATE KEY UPDATE
    order_id = VALUES(order_id),
    product_id = VALUES(product_id),
    quantity = VALUES(quantity),
    unit_price = VALUES(unit_price);

-- Quick verification
SELECT COUNT(*) AS customers_count FROM customers;
SELECT COUNT(*) AS products_count FROM products;
SELECT COUNT(*) AS orders_count FROM orders;
SELECT COUNT(*) AS order_items_count FROM order_items;

-- Example analytical query: revenue by city
SELECT
    c.city,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.customer_id
JOIN order_items AS oi
    ON oi.order_id = o.order_id
WHERE o.status IN ('completed', 'shipped')
GROUP BY c.city
ORDER BY revenue DESC;
