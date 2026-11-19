CREATE DATABASE olist_analytics;
USE olist_analytics;

SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

DESCRIBE customers;

SELECT COUNT(*) AS total_customers
FROM customers;
