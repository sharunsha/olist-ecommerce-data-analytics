# SQL Analysis – Olist E-commerce Analytics

## Overview

This folder contains the SQL scripts developed for the Olist E-commerce Data Analytics project using MySQL.

The SQL workflow covers database creation, data importing, data validation, analytical queries, and reusable SQL views to extract meaningful business insights.

## Database

- **Database Name:** `olist_analytics`
- **Database Management System:** MySQL
- **Tool:** MySQL Workbench

## Project Structure

```text
sql/
│
├── table_creation/
│   └── Scripts for creating database tables
│
├── data_import/
│   └── Scripts for importing dataset tables
│
├── data_validation/
│   └── Scripts for checking data quality and consistency
│
├── business_analysis/
│   └── SQL queries for business performance analysis
│
├── views/
│   └── SQL scripts for creating analytical views
│
└── README.md
```

## Database Tables

The database includes the following tables:

- customers
- orders
- order_items
- products
- sellers
- payments
- reviews
- geolocation
- category_translation

## SQL Operations Performed

### 1. Database and Table Creation
- Created the `olist_analytics` database.
- Created tables based on the Olist dataset structure.
- Defined appropriate columns and data types.

### 2. Data Import
- Imported the Olist dataset into MySQL.
- Loaded customer, order, product, seller, payment, review, and supporting data.

### 3. Data Validation
- Checked record counts and data consistency.
- Validated missing and invalid values.
- Reviewed order and delivery date information.
- Checked relationships between datasets.

### 4. Business Analysis
Performed SQL-based analysis covering:

- Revenue and business performance
- Product and category performance
- Delivery and logistics performance
- Customer satisfaction
- Customer segmentation
- Seller performance

### 5. SQL Views
Created reusable analytical views, including:

- `vw_customer_rfm`
- `vw_delivery_performance`
- `vw_order_summary`
- `vw_product_performance`
- `vw_state_delivery_performance`

## SQL Concepts Used

- SELECT, WHERE, ORDER BY
- GROUP BY and HAVING
- Aggregate functions
- INNER JOIN and LEFT JOIN
- Subqueries
- Common Table Expressions (CTEs)
- CASE statements
- Date and time functions
- Window functions
- Views
- Data validation queries

## Key Outcomes

- Developed a structured MySQL database for e-commerce analytics.
- Performed multi-table analysis using SQL joins and aggregations.
- Created reusable views for downstream reporting.
- Generated business insights to support data-driven decision-making.

## Tools Used

- MySQL
- MySQL Workbench
- SQL
