LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/customers_clean.csv'
INTO TABLE olist_analytics.customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
);