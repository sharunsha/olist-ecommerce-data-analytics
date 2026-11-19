USE olist_analytics;

SHOW CREATE VIEW vw_order_summary;

USE olist_analytics;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

USE olist_analytics;

SHOW CREATE VIEW vw_customer_rfm;
SHOW CREATE VIEW vw_delivery_performance;
SHOW CREATE VIEW vw_product_performance;
SHOW CREATE VIEW vw_state_delivery_performance;

USE olist_analytics;

SELECT COUNT(*) AS customer_rfm_rows
FROM vw_customer_rfm;

SELECT COUNT(*) AS delivery_rows
FROM vw_delivery_performance;

SELECT COUNT(*) AS product_rows
FROM vw_product_performance;

SELECT COUNT(*) AS state_delivery_rows
FROM vw_state_delivery_performance;


USE olist_analytics;

SHOW CREATE VIEW vw_delivery_performance;

SHOW CREATE VIEW vw_product_performance;
USE olist_analytics;

SELECT
    (SELECT COUNT(*)
     FROM orders
     WHERE order_status = 'delivered') AS delivered_orders,

    (SELECT COUNT(*)
     FROM vw_delivery_performance) AS view_rows,

    (SELECT COUNT(*)
     FROM vw_delivery_performance
     WHERE order_delivered_customer_date IS NOT NULL) AS orders_with_delivery_date,

    (SELECT ROUND(AVG(days_vs_estimated_delivery), 2)
     FROM vw_delivery_performance
     WHERE order_status = 'delivered') AS avg_days_vs_estimated;
     
     USE olist_analytics;

SELECT
    COUNT(*) AS total_orders,
    SUM(order_status = 'delivered') AS delivered_orders,
    SUM(order_delivered_customer_date IS NULL) AS missing_delivery_dates,
    SUM(
        order_status = 'delivered'
        AND order_delivered_customer_date IS NULL
    ) AS delivered_orders_missing_date
FROM orders;


USE olist_analytics;

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(order_delivered_customer_date IS NOT NULL)
        AS orders_with_delivery_date
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


USE olist_analytics;

SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status <> 'delivered'
ORDER BY order_status
LIMIT 20;


USE olist_analytics;

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(
        CAST(order_delivered_customer_date AS CHAR)
        LIKE '0000-00-00%'
    ) AS zero_delivery_dates,
    SUM(
        order_delivered_customer_date IS NULL
    ) AS null_delivery_dates
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


USE olist_analytics;

SELECT
    COUNT(*) AS total_view_rows,
    SUM(order_status = 'delivered') AS delivered_orders,
    SUM(
        order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
    ) AS delivered_with_valid_dates,
    SUM(delivery_group = 'Unknown') AS unknown_delivery_group,
    ROUND(AVG(days_vs_estimated_delivery), 2)
        AS avg_days_vs_estimated
FROM vw_delivery_performance;




USE olist_analytics;

SELECT
    delivery_group,
    COUNT(*) AS order_count,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM vw_delivery_performance
         WHERE order_status = 'delivered'
           AND delivery_group <> 'Unknown'),
        2
    ) AS percentage
FROM vw_delivery_performance
WHERE order_status = 'delivered'
  AND delivery_group <> 'Unknown'
GROUP BY delivery_group
ORDER BY order_count DESC;

USE olist_analytics;

SELECT
    delivery_group,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    SUM(r.review_score <= 2) AS low_score_reviews,
    ROUND(
        100.0 * SUM(r.review_score <= 2) / COUNT(*),
        2
    ) AS low_score_percentage
FROM vw_delivery_performance d
JOIN reviews r
    ON d.order_id = r.order_id
WHERE d.order_status = 'delivered'
  AND d.delivery_group <> 'Unknown'
GROUP BY delivery_group
ORDER BY avg_review_score;


USE olist_analytics;

SELECT
    c.customer_state,
    COUNT(*) AS valid_delivered_orders,
    SUM(d.delivery_group = 'Late') AS late_orders,
    ROUND(
        100.0 * SUM(d.delivery_group = 'Late') / COUNT(*),
        2
    ) AS late_delivery_percentage,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM vw_delivery_performance d
JOIN customers c
    ON d.customer_id = c.customer_id
LEFT JOIN reviews r
    ON d.order_id = r.order_id
WHERE d.order_status = 'delivered'
  AND d.delivery_group <> 'Unknown'
GROUP BY c.customer_state
HAVING COUNT(*) >= 100
ORDER BY late_delivery_percentage DESC;