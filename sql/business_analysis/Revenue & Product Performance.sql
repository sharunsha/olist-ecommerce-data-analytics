USE olist_analytics;

SELECT
    product_category,
    SUM(items_sold) AS total_items_sold,
    ROUND(SUM(gross_item_value), 2) AS gross_item_value
FROM vw_product_performance
GROUP BY product_category
ORDER BY gross_item_value DESC
LIMIT 10;

SELECT
    product_category,
    SUM(items_sold) AS total_items_sold,
    ROUND(SUM(gross_item_value), 2) AS gross_item_value,
    ROUND(
        SUM(gross_item_value) / NULLIF(SUM(items_sold), 0),
        2
    ) AS avg_item_price
FROM vw_product_performance
GROUP BY product_category
ORDER BY gross_item_value DESC
LIMIT 10;

SELECT
    product_category,
    SUM(items_sold) AS total_items_sold,
    SUM(total_orders) AS category_order_count,
    ROUND(SUM(gross_item_value), 2) AS gross_item_value
FROM vw_product_performance
GROUP BY product_category
ORDER BY category_order_count DESC
LIMIT 10;

SELECT
    product_category,
    SUM(items_sold) AS total_items_sold,
    SUM(total_orders) AS category_order_count,
    ROUND(SUM(gross_item_value), 2) AS gross_item_value,
    ROUND(
        SUM(gross_item_value) / NULLIF(SUM(total_orders), 0),
        2
    ) AS gross_value_per_category_order
FROM vw_product_performance
GROUP BY product_category
ORDER BY gross_value_per_category_order DESC
LIMIT 10;

SHOW CREATE VIEW vw_product_performance;

SELECT
    COALESCE(
        NULLIF(TRIM(ct.product_category_name_english), ''),
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    ) AS product_category,
    COUNT(*) AS total_items_sold,
    COUNT(DISTINCT oi.order_id) AS distinct_category_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT oi.order_id), 0),
        2
    ) AS gross_value_per_category_order
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
LEFT JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    COALESCE(
        NULLIF(TRIM(ct.product_category_name_english), ''),
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    )
ORDER BY gross_value_per_category_order DESC
LIMIT 10;

