USE olist_analytics;

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);





TRUNCATE TABLE olist_analytics.geolocation;
SHOW VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

SELECT COUNT(*) AS geolocation_rows
FROM olist_analytics.geolocation;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes,
    SUM(geolocation_lat IS NULL) AS missing_latitudes,
    SUM(geolocation_lng IS NULL) AS missing_longitudes
FROM olist_analytics.geolocation;

SELECT *
FROM olist_analytics.geolocation
LIMIT 5;

SELECT COUNT(*) AS total_geolocation
FROM geolocation;