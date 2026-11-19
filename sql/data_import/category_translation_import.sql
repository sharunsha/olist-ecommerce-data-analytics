LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/category_translation_clean.csv'
INTO TABLE olist_analytics.category_translation
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    product_category_name,
    product_category_name_english
);