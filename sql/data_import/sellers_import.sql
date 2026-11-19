LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/sellers_clean.csv'
INTO TABLE olist_analytics.sellers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
);