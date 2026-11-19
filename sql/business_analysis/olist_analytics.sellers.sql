CREATE TABLE olist_analytics.sellers (
    seller_id VARCHAR(50) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_seller_ids,
    SUM(seller_id IS NULL OR seller_id = '') AS missing_seller_ids
FROM olist_analytics.sellers;