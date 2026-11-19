LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/order_items_clean.csv'
INTO TABLE olist_analytics.order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
);