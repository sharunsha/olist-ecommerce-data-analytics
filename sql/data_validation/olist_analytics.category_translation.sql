CREATE TABLE olist_analytics.category_translation (
    product_category_name VARCHAR(100) NOT NULL PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

SELECT
    COUNT(*) AS total_categories,
    COUNT(DISTINCT product_category_name) AS unique_portuguese_categories,
    SUM(product_category_name IS NULL OR product_category_name = '')
        AS missing_category_names
FROM olist_analytics.category_translation;

USE olist_analytics;
SELECT DATABASE();