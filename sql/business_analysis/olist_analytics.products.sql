CREATE TABLE olist_analytics.products (
    product_id VARCHAR(50) NOT NULL PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);


SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    SUM(product_id IS NULL OR product_id = '') AS missing_product_ids
FROM olist_analytics.products;

