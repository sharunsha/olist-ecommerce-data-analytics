LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/payments_clean.csv'
INTO TABLE olist_analytics.payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
);