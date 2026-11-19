Olist E-commerce – Data Dictionary
Overview
This document describes the main database tables used in the Olist E-commerce Data Analytics project.
Database: olist_analytics
Database Management System: MySQL
1. Customers
Purpose: Stores customer information and location identifiers.
Column	Description
customer_id	Unique customer identifier
customer_unique_id	Customer's unique identifier across orders
customer_zip_code_prefix	Customer postal code prefix
customer_city	Customer city
customer_state	Customer state
2. Orders
Purpose: Contains order details, status and timestamps.
Column	Description
order_id	Unique order identifier
customer_id	Customer identifier
order_status	Current order status
order_purchase_timestamp	Order purchase timestamp
order_approved_at	Order approval timestamp
order_delivered_carrier_date	Handover to carrier timestamp
order_delivered_customer_date	Customer delivery timestamp
order_estimated_delivery_date	Estimated delivery date
3. Order Items
Purpose: Stores individual products associated with each order.
Column	Description
order_id	Order identifier
order_item_id	Item sequence within an order
product_id	Product identifier
seller_id	Seller identifier
shipping_limit_date	Seller shipping deadline
price	Product item price
freight_value	Freight charge
4. Products
Purpose: Contains product attributes and category information.
Column	Description
product_id	Unique product identifier
product_category_name	Original product category
product_name_length	Product name character count
product_description_length	Product description character count
product_photos_qty	Number of product photos
product_weight_g	Product weight in grams
product_length_cm	Product length in centimeters
product_height_cm	Product height in centimeters
product_width_cm	Product width in centimeters
5. Sellers
Purpose: Stores seller identification and location details.
Column	Description
seller_id	Unique seller identifier
seller_zip_code_prefix	Seller postal code prefix
seller_city	Seller city
seller_state	Seller state
6. Payments
Purpose: Contains payment transaction information.
Column	Description
order_id	Order identifier
payment_sequential	Payment sequence number
payment_type	Payment method
payment_installments	Number of installments
payment_value	Payment amount
7. Reviews
Purpose: Stores customer feedback and review information.
Column	Description
review_id	Review identifier
order_id	Associated order identifier
review_score	Customer rating
review_comment_title	Review title
review_comment_message	Review message
review_creation_date	Review creation timestamp
review_answer_timestamp	Review response timestamp
8. Geolocation
Purpose: Contains geographical information associated with postal code prefixes.
Column	Description
geolocation_zip_code_prefix	Postal code prefix
geolocation_lat	Latitude
geolocation_lng	Longitude
geolocation_city	City
geolocation_state	State
9. Category Translation
Purpose: Maps original Portuguese product category names to English translations.
Column	Description
product_category_name	Original category name
product_category_name_english	English category name
Analytical Views
The project also uses the following MySQL views:
•	vw_customer_rfm
•	vw_delivery_performance
•	vw_order_summary
•	vw_product_performance
•	vw_state_delivery_performance
These views support reusable business analysis and downstream reporting.
Notes
•	The descriptions above represent the intended meaning of the dataset fields.
•	Actual column definitions should be verified against the database schema.
•	The dataset contains multiple related tables connected through order, customer, product and seller identifiers.

