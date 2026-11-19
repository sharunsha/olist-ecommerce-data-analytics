CREATE TABLE olist_analytics.orders (
    order_id VARCHAR(50) NOT NULL PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(order_id IS NULL OR order_id = '') AS missing_order_ids,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamps
FROM olist_analytics.orders;