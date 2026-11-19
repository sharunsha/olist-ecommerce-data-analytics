LOAD DATA LOCAL INFILE
'C:/Users/sharu/Desktop/project/for sql/reviews_mysql_ready.csv'
INTO TABLE olist_analytics.reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    source_row_number,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
);
