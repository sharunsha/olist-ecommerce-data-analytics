CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date DATETIME,
    price DECIMAL(12,2) NOT NULL,
    freight_value DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

DESCRIBE order_items;

SELECT COUNT(*) AS total_rows
FROM olist_analytics.order_items;


SELECT COUNT(*) AS duplicate_order_items
FROM (
    SELECT order_id, order_item_id
    FROM olist_analytics.order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS duplicates;