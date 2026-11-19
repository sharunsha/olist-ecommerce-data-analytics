USE olist_analytics;

CREATE TABLE payments (
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

SELECT COUNT(*) AS total_rows
FROM olist_analytics.payments;

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM olist_analytics.payments;


SELECT COUNT(*) AS duplicate_payment_keys
FROM (
    SELECT order_id, payment_sequential
    FROM olist_analytics.payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS duplicates;