-- =========================================================================
-- Week 2: SQL for Data Analysis
-- Topics: SELECT, WHERE, GROUP BY, ORDER BY, aggregations (SUM, AVG, COUNT),
--         JOINs, subqueries, CASE statements
-- Assignment: Query a sample database to find top customers and average
--             order values.
--
-- The "Click here" sample-database link in the course slides pointed to a
-- Google Sheet that isn't reachable from this environment, so a small
-- customers/orders schema with sample data is created below (matching a
-- typical e-commerce sample DB) so every query runs end-to-end. Replace the
-- CREATE TABLE / INSERT sections with your real tables to use this on the
-- actual assignment data.
-- =========================================================================

-- -------------------------------------------------------------------------
-- Schema
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    region        TEXT
);

CREATE TABLE orders (
    order_id      INTEGER PRIMARY KEY,
    customer_id   INTEGER NOT NULL,
    order_date    DATE NOT NULL,
    order_total   NUMERIC NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    item_id     INTEGER PRIMARY KEY,
    order_id    INTEGER NOT NULL,
    category    TEXT NOT NULL,
    quantity    INTEGER NOT NULL,
    unit_price  NUMERIC NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- -------------------------------------------------------------------------
-- Sample data
-- -------------------------------------------------------------------------
INSERT INTO customers VALUES
 (1, 'Alice Johnson', 'North'),
 (2, 'Brian Lee',     'South'),
 (3, 'Carla Gomez',   'East'),
 (4, 'David Kim',     'West'),
 (5, 'Ella Brown',    'North');

INSERT INTO orders VALUES
 (100, 1, '2025-01-12', 250.00),
 (101, 1, '2025-03-05', 120.50),
 (102, 2, '2025-02-20',  75.00),
 (103, 3, '2025-04-01', 430.25),
 (104, 3, '2025-04-18',  60.00),
 (105, 4, '2025-05-09', 310.00),
 (106, 5, '2025-05-22',  95.75),
 (107, 1, '2025-06-14', 180.00),
 (108, 2, '2025-06-30', 500.00),
 (109, 4, '2025-07-11',  45.00);

INSERT INTO order_items VALUES
 (1, 100, 'Electronics', 1, 250.00),
 (2, 101, 'Books',       2,  60.25),
 (3, 102, 'Clothing',    3,  25.00),
 (4, 103, 'Electronics', 1, 430.25),
 (5, 104, 'Books',       1,  60.00),
 (6, 105, 'Home & Kitchen', 2, 155.00),
 (7, 106, 'Sports',      1,  95.75),
 (8, 107, 'Clothing',    4,  45.00),
 (9, 108, 'Electronics', 2, 250.00),
 (10, 109, 'Books',      1,  45.00);

-- =========================================================================
-- 1. Basic queries: SELECT, WHERE, GROUP BY, ORDER BY
-- =========================================================================

-- All orders over $100, most recent first
SELECT order_id, customer_id, order_date, order_total
FROM orders
WHERE order_total > 100
ORDER BY order_date DESC;

-- Number of orders and total spend per customer
SELECT customer_id,
       COUNT(*)         AS num_orders,
       SUM(order_total)  AS total_spend,
       AVG(order_total)  AS avg_order_value
FROM orders
GROUP BY customer_id
ORDER BY total_spend DESC;

-- =========================================================================
-- 2. Aggregations: SUM, AVG, COUNT
-- =========================================================================

-- Overall order stats
SELECT COUNT(*)        AS total_orders,
       SUM(order_total) AS total_revenue,
       AVG(order_total) AS avg_order_value
FROM orders;

-- Revenue per product category (from order_items)
SELECT category,
       COUNT(*)                       AS items_sold,
       SUM(quantity * unit_price)     AS category_revenue,
       AVG(unit_price)                AS avg_unit_price
FROM order_items
GROUP BY category
ORDER BY category_revenue DESC;

-- =========================================================================
-- 3. Joins, subqueries, CASE statements
-- =========================================================================

-- JOIN: customer name alongside each of their orders
SELECT c.customer_name, o.order_id, o.order_date, o.order_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY c.customer_name, o.order_date;

-- JOIN + GROUP BY: total spend per customer, with customer name
SELECT c.customer_name,
       COUNT(o.order_id)   AS num_orders,
       SUM(o.order_total)  AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_spend DESC;

-- SUBQUERY: customers whose total spend is above the overall average
-- order total (find high-value customers)
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
    HAVING SUM(order_total) > (SELECT AVG(order_total) FROM orders)
);

-- SUBQUERY: each order's total vs. the customer's own average order value
SELECT o.order_id, o.customer_id, o.order_total,
       (SELECT AVG(o2.order_total)
        FROM orders o2
        WHERE o2.customer_id = o.customer_id) AS customer_avg_order
FROM orders o
ORDER BY o.customer_id, o.order_date;

-- CASE: label each order as Small / Medium / Large
SELECT order_id, order_total,
       CASE
           WHEN order_total < 100 THEN 'Small'
           WHEN order_total BETWEEN 100 AND 300 THEN 'Medium'
           ELSE 'Large'
       END AS order_size
FROM orders
ORDER BY order_total;

-- =========================================================================
-- 4. Assignment: top customers, average order values
-- =========================================================================

-- Top 3 customers by total spend
SELECT c.customer_name,
       SUM(o.order_total) AS total_spend
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_spend DESC
LIMIT 3;

-- Average order value per customer, sorted highest first
SELECT c.customer_name,
       ROUND(AVG(o.order_total), 2) AS avg_order_value,
       COUNT(o.order_id)            AS num_orders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY avg_order_value DESC;

-- Overall average order value across all customers (single benchmark number)
SELECT ROUND(AVG(order_total), 2) AS overall_avg_order_value
FROM orders;
