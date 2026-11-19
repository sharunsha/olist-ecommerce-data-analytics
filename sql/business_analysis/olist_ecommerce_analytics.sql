
-- SECTION 1: DATABASE SETUP

SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM olist_analytics.customers

UNION ALL
SELECT 'geolocation', COUNT(*)
FROM olist_analytics.geolocation

UNION ALL
SELECT 'order_items', COUNT(*)
FROM olist_analytics.order_items

UNION ALL
SELECT 'payments', COUNT(*)
FROM olist_analytics.payments

UNION ALL
SELECT 'reviews', COUNT(*)
FROM olist_analytics.reviews

UNION ALL
SELECT 'orders', COUNT(*)
FROM olist_analytics.orders

UNION ALL
SELECT 'products', COUNT(*)
FROM olist_analytics.products

UNION ALL
SELECT 'sellers', COUNT(*)
FROM olist_analytics.sellers

UNION ALL
SELECT 'category_translation', COUNT(*)
FROM olist_analytics.category_translation;


-- SECTION 2: DATA QUALITY & RELATIONSHIP VALIDATION

SELECT
    (SELECT COUNT(*)
     FROM olist_analytics.orders o
     LEFT JOIN olist_analytics.customers c
       ON o.customer_id = c.customer_id
     WHERE c.customer_id IS NULL) AS orders_without_customer,

    (SELECT COUNT(*)
     FROM olist_analytics.order_items oi
     LEFT JOIN olist_analytics.orders o
       ON oi.order_id = o.order_id
     WHERE o.order_id IS NULL) AS items_without_order,

    (SELECT COUNT(*)
     FROM olist_analytics.order_items oi
     LEFT JOIN olist_analytics.products p
       ON oi.product_id = p.product_id
     WHERE p.product_id IS NULL) AS items_without_product,

    (SELECT COUNT(*)
     FROM olist_analytics.order_items oi
     LEFT JOIN olist_analytics.sellers s
       ON oi.seller_id = s.seller_id
     WHERE s.seller_id IS NULL) AS items_without_seller,

    (SELECT COUNT(*)
     FROM olist_analytics.payments p
     LEFT JOIN olist_analytics.orders o
       ON p.order_id = o.order_id
     WHERE o.order_id IS NULL) AS payments_without_order,

    (SELECT COUNT(*)
     FROM olist_analytics.reviews r
     LEFT JOIN olist_analytics.orders o
       ON r.order_id = o.order_id
     WHERE o.order_id IS NULL) AS reviews_without_order;
     

-- SECTION 3: BUSINESS PROBLEM 1 - REVENUE & PRODUCT PERFORMANCE
     
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
        THEN o.order_id
    END) AS delivered_orders,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(SUM(oi.price), 2) AS gross_item_revenue,
    ROUND(SUM(oi.freight_value), 2) AS total_freight_value,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS item_revenue_per_order,
    ROUND(
        SUM(oi.price) / NULLIF(COUNT(DISTINCT o.customer_id), 0),
        2
    ) AS item_revenue_per_customer
FROM olist_analytics.orders o
JOIN olist_analytics.order_items oi
    ON o.order_id = oi.order_id;
    

-- =====================================================
-- SECTION 3.2: ITEM VALUE BY ORDER STATUS
-- =====================================================

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(
        100.0 * COUNT(DISTINCT o.order_id) /
        SUM(COUNT(DISTINCT o.order_id)) OVER (),
        2
    ) AS percentage_of_orders
FROM olist_analytics.orders o
JOIN olist_analytics.order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.order_status
ORDER BY gross_item_value DESC;


-- =====================================================
-- SECTION 3.3: CORRECT CUSTOMER AND REVENUE KPIs
-- =====================================================

SELECT
    COUNT(DISTINCT o.order_id) AS orders_with_items,
    COUNT(DISTINCT c.customer_unique_id) AS actual_unique_customers,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(
        SUM(oi.price) /
        NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS item_value_per_order,
    ROUND(
        SUM(oi.price) /
        NULLIF(COUNT(DISTINCT c.customer_unique_id), 0),
        2
    ) AS item_value_per_unique_customer
FROM olist_analytics.orders o
JOIN olist_analytics.order_items oi
    ON o.order_id = oi.order_id
JOIN olist_analytics.customers c
    ON o.customer_id = c.customer_id;
    
-- =====================================================
-- SECTION 3.4: REPEAT CUSTOMER ANALYSIS
-- =====================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN olist_analytics.order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS unique_customers,
    SUM(CASE
        WHEN order_count = 1 THEN 1
        ELSE 0
    END) AS one_order_customers,
    SUM(CASE
        WHEN order_count > 1 THEN 1
        ELSE 0
    END) AS repeat_customers,
    ROUND(
        100.0 * SUM(CASE
            WHEN order_count > 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;


-- =====================================================
-- SECTION 3.5: REVENUE BY PRODUCT CATEGORY
-- =====================================================

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM olist_analytics.order_items oi
JOIN olist_analytics.orders o
    ON oi.order_id = o.order_id
JOIN olist_analytics.products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_analytics.category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY gross_item_value DESC
LIMIT 15;

-- =====================================================
-- SECTION 3.6: CATEGORY AVERAGE ORDER VALUE
-- =====================================================

WITH category_order_value AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ) AS product_category,
        oi.order_id,
        SUM(oi.price) AS order_item_value
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.products p
        ON oi.product_id = p.product_id
    LEFT JOIN olist_analytics.category_translation ct
        ON p.product_category_name = ct.product_category_name
    GROUP BY
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'Unknown'
        ),
        oi.order_id
)
SELECT
    product_category,
    COUNT(*) AS category_orders,
    ROUND(SUM(order_item_value), 2) AS gross_item_value,
    ROUND(AVG(order_item_value), 2) AS average_category_order_value
FROM category_order_value
GROUP BY product_category
ORDER BY average_category_order_value DESC
LIMIT 15;


-- =====================================================
-- SECTION 3.7: MONTHLY GROSS ITEM VALUE TREND
-- =====================================================

SELECT
    DATE_FORMAT(
        o.order_purchase_timestamp,
        '%Y-%m'
    ) AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM olist_analytics.orders o
JOIN olist_analytics.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(
    o.order_purchase_timestamp,
    '%Y-%m'
)
ORDER BY order_month;


-- =====================================================
-- SECTION 3.8: TOP PRODUCTS BY GROSS ITEM VALUE
-- =====================================================

SELECT
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM olist_analytics.order_items oi
JOIN olist_analytics.products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_analytics.category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'Unknown'
    )
ORDER BY gross_item_value DESC
LIMIT 20;

-- =====================================================
-- SECTION 3.9: MISSING PRODUCT CATEGORY AUDIT
-- =====================================================

SELECT
    CASE
        WHEN p.product_category_name IS NULL
             OR TRIM(p.product_category_name) = ''
            THEN 'Missing category'
        WHEN ct.product_category_name_english IS NULL
            THEN 'Untranslated category'
        ELSE 'Translated category'
    END AS category_status,
    COUNT(DISTINCT p.product_id) AS products,
    COUNT(*) AS order_items,
    ROUND(SUM(oi.price), 2) AS gross_item_value
FROM olist_analytics.order_items oi
JOIN olist_analytics.products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_analytics.category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY category_status
ORDER BY gross_item_value DESC;


USE olist_analytics;
-- =====================================================
-- SECTION 3.10: PRODUCT PERFORMANCE VIEW
-- =====================================================

CREATE OR REPLACE VIEW vw_product_performance AS
SELECT
    oi.product_id,
    COALESCE(
        NULLIF(TRIM(ct.product_category_name_english), ''),
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    ) AS product_category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS gross_item_value,
    ROUND(SUM(oi.freight_value), 2) AS freight_value,
    ROUND(AVG(oi.price), 2) AS average_item_price
FROM olist_analytics.order_items oi
JOIN olist_analytics.products p
    ON oi.product_id = p.product_id
LEFT JOIN olist_analytics.category_translation ct
    ON p.product_category_name = ct.product_category_name
GROUP BY
    oi.product_id,
    COALESCE(
        NULLIF(TRIM(ct.product_category_name_english), ''),
        NULLIF(TRIM(p.product_category_name), ''),
        'Unknown'
    );
    
SELECT *
FROM olist_analytics.vw_product_performance
ORDER BY gross_item_value DESC
LIMIT 10;

-- =====================================================
-- SECTION 3.11: VALIDATE PRODUCT PERFORMANCE VIEW
-- =====================================================

SELECT
    (SELECT COUNT(*)
     FROM olist_analytics.order_items) AS source_order_items,

    (SELECT SUM(items_sold)
     FROM olist_analytics.vw_product_performance) AS view_order_items,

    (SELECT ROUND(SUM(price), 2)
     FROM olist_analytics.order_items) AS source_item_value,

    (SELECT ROUND(SUM(gross_item_value), 2)
     FROM olist_analytics.vw_product_performance) AS view_item_value,

    (SELECT ROUND(SUM(freight_value), 2)
     FROM olist_analytics.order_items) AS source_freight,

    (SELECT ROUND(SUM(freight_value), 2)
     FROM olist_analytics.vw_product_performance) AS view_freight;
     
-- =====================================================
-- SECTION 4.1: DELIVERY PERFORMANCE BASELINE
-- =====================================================

SELECT
    o.order_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS orders_with_delivery_dates,
    ROUND(
        AVG(
            CASE
                WHEN o.order_delivered_customer_date IS NOT NULL
                 AND o.order_estimated_delivery_date IS NOT NULL
                THEN DATEDIFF(
                    o.order_delivered_customer_date,
                    o.order_estimated_delivery_date
                )
            END
        ), 2
    ) AS avg_days_vs_estimate
FROM olist_analytics.orders o
GROUP BY o.order_status
ORDER BY total_orders DESC;


-- =====================================================
-- SECTION 4.2: DELIVERY TIMING VS REVIEW SCORES
-- =====================================================

SELECT
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) > 0
            THEN 'Late'
        ELSE 'On time or early'
    END AS delivery_group,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(r.review_id) AS review_rows,
    ROUND(AVG(r.review_score), 2) AS average_review_score,
    SUM(
        CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END
    ) AS low_score_review_rows
FROM olist_analytics.orders o
JOIN olist_analytics.reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) > 0
            THEN 'Late'
        ELSE 'On time or early'
    END
ORDER BY delivery_group;

-- =====================================================
-- SECTION 4.3: LOW REVIEW SCORE RATE BY DELIVERY GROUP
-- =====================================================

SELECT
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) > 0 THEN 'Late'
        ELSE 'On time or early'
    END AS delivery_group,
    COUNT(*) AS review_rows,
    COUNT(DISTINCT o.order_id) AS distinct_orders,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END)
        AS low_score_review_rows,
    ROUND(
        100.0 * SUM(
            CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS low_score_percentage
FROM olist_analytics.orders o
JOIN olist_analytics.reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY delivery_group
ORDER BY delivery_group;

-- =====================================================
-- SECTION 4.4: REVIEW SCORE BY DELIVERY DELAY
-- =====================================================

SELECT
    CASE
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) < -14 THEN '15+ days early'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN -14 AND -8 THEN '8-14 days early'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN -7 AND 0 THEN '0-7 days early/on time'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 1 AND 7 THEN '1-7 days late'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) BETWEEN 8 AND 14 THEN '8-14 days late'
        ELSE '15+ days late'
    END AS delivery_delay_group,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(*) AS review_rows,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM olist_analytics.orders o
JOIN olist_analytics.reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY delivery_delay_group
ORDER BY
    CASE delivery_delay_group
        WHEN '15+ days early' THEN 1
        WHEN '8-14 days early' THEN 2
        WHEN '0-7 days early/on time' THEN 3
        WHEN '1-7 days late' THEN 4
        WHEN '8-14 days late' THEN 5
        WHEN '15+ days late' THEN 6
    END;
    
-- =====================================================
-- SECTION 4.5: DELIVERY PERFORMANCE VIEW
-- =====================================================

CREATE OR REPLACE VIEW olist_analytics.vw_delivery_performance AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) AS days_vs_estimated_delivery,
    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
            THEN 'Unknown'
        WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) > 0
            THEN 'Late'
        ELSE 'On time or early'
    END AS delivery_group
FROM olist_analytics.orders o;


SELECT
    delivery_group,
    COUNT(*) AS total_orders,
    ROUND(AVG(days_vs_estimated_delivery), 2)
        AS avg_days_vs_estimate
FROM olist_analytics.vw_delivery_performance
GROUP BY delivery_group
ORDER BY total_orders DESC;

-- =====================================================
-- SECTION 4.6: DELIVERY GROUP AND CUSTOMER SATISFACTION
-- =====================================================

SELECT
    dp.delivery_group,
    COUNT(DISTINCT dp.order_id) AS total_orders,
    COUNT(r.review_id) AS review_rows,
    ROUND(AVG(r.review_score), 2) AS average_review_score,
    SUM(
        CASE
            WHEN r.review_score <= 2 THEN 1
            ELSE 0
        END
    ) AS low_score_review_rows,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN r.review_score <= 2 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(r.review_id), 0),
        2
    ) AS low_score_percentage
FROM olist_analytics.vw_delivery_performance dp
JOIN olist_analytics.reviews r
    ON dp.order_id = r.order_id
WHERE dp.order_status = 'delivered'
  AND dp.order_delivered_customer_date IS NOT NULL
  AND dp.order_estimated_delivery_date IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY dp.delivery_group
ORDER BY dp.delivery_group;


-- =====================================================
-- SECTION 4.7: DELIVERY DELAY RISK SUMMARY
-- =====================================================

SELECT
    CASE
        WHEN dp.days_vs_estimated_delivery < -14
            THEN '15+ days early'
        WHEN dp.days_vs_estimated_delivery BETWEEN -14 AND -8
            THEN '8-14 days early'
        WHEN dp.days_vs_estimated_delivery BETWEEN -7 AND 0
            THEN '0-7 days early/on time'
        WHEN dp.days_vs_estimated_delivery BETWEEN 1 AND 7
            THEN '1-7 days late'
        WHEN dp.days_vs_estimated_delivery BETWEEN 8 AND 14
            THEN '8-14 days late'
        ELSE '15+ days late'
    END AS delivery_delay_group,

    COUNT(DISTINCT dp.order_id) AS total_orders,

    ROUND(
        AVG(dp.days_vs_estimated_delivery),
        2
    ) AS avg_days_vs_estimate,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score,

    SUM(
        CASE
            WHEN r.review_score <= 2 THEN 1
            ELSE 0
        END
    ) AS low_score_review_rows

FROM olist_analytics.vw_delivery_performance dp

LEFT JOIN olist_analytics.reviews r
    ON dp.order_id = r.order_id

WHERE dp.order_status = 'delivered'
  AND dp.order_delivered_customer_date IS NOT NULL
  AND dp.order_estimated_delivery_date IS NOT NULL

GROUP BY delivery_delay_group

ORDER BY
    CASE delivery_delay_group
        WHEN '15+ days early' THEN 1
        WHEN '8-14 days early' THEN 2
        WHEN '0-7 days early/on time' THEN 3
        WHEN '1-7 days late' THEN 4
        WHEN '8-14 days late' THEN 5
        WHEN '15+ days late' THEN 6
    END;
    
    
-- =====================================================
-- SECTION 4.8: DELIVERY PERFORMANCE BY CUSTOMER STATE
-- =====================================================

SELECT
    c.customer_state,
    COUNT(DISTINCT dp.order_id) AS delivered_orders,

    SUM(
        CASE
            WHEN dp.days_vs_estimated_delivery > 0 THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN dp.days_vs_estimated_delivery > 0 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(DISTINCT dp.order_id), 0),
        2
    ) AS late_delivery_percentage,

    ROUND(
        AVG(dp.days_vs_estimated_delivery),
        2
    ) AS avg_days_vs_estimate

FROM olist_analytics.vw_delivery_performance dp

JOIN olist_analytics.customers c
    ON dp.customer_id = c.customer_id

WHERE dp.order_status = 'delivered'
  AND dp.order_delivered_customer_date IS NOT NULL
  AND dp.order_estimated_delivery_date IS NOT NULL

GROUP BY c.customer_state

HAVING COUNT(DISTINCT dp.order_id) >= 500

ORDER BY late_delivery_percentage DESC;



-- =====================================================
-- SECTION 4.9: STATE-LEVEL DELIVERY PERFORMANCE VIEW
-- =====================================================

CREATE OR REPLACE VIEW olist_analytics.vw_state_delivery_performance AS
SELECT
    c.customer_state,
    COUNT(DISTINCT dp.order_id) AS delivered_orders,

    SUM(
        CASE
            WHEN dp.days_vs_estimated_delivery > 0 THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN dp.days_vs_estimated_delivery > 0 THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(DISTINCT dp.order_id), 0),
        2
    ) AS late_delivery_percentage,

    ROUND(
        AVG(dp.days_vs_estimated_delivery),
        2
    ) AS avg_days_vs_estimate

FROM olist_analytics.vw_delivery_performance dp

JOIN olist_analytics.customers c
    ON dp.customer_id = c.customer_id

WHERE dp.order_status = 'delivered'
  AND dp.order_delivered_customer_date IS NOT NULL
  AND dp.order_estimated_delivery_date IS NOT NULL

GROUP BY c.customer_state;


-- Test the state-level view
SELECT *
FROM olist_analytics.vw_state_delivery_performance
WHERE delivered_orders >= 500
ORDER BY late_delivery_percentage DESC;



-- =====================================================
-- SECTION 4.10: STATES WITH THE MOST LATE ORDERS
-- =====================================================

SELECT
    customer_state,
    delivered_orders,
    late_orders,
    late_delivery_percentage,
    avg_days_vs_estimate
FROM olist_analytics.vw_state_delivery_performance
WHERE delivered_orders >= 500
ORDER BY late_orders DESC
LIMIT 10;



-- =====================================================
-- SECTION 5.1: CUSTOMER PURCHASE FREQUENCY
-- BUSINESS PROBLEM 3: CUSTOMER SEGMENTATION & RETENTION
-- =====================================================

WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer

FROM customer_order_counts
GROUP BY customer_segment
ORDER BY total_customers DESC;




-- =====================================================
-- SECTION 5.2: CUSTOMER SEGMENT VALUE ANALYSIS
-- MYSQL-COMPATIBLE VERSION
-- =====================================================

WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_order_count
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        coc.delivered_order_count
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN customer_order_counts coc
        ON c.customer_unique_id = coc.customer_unique_id
    WHERE o.order_status = 'delivered'
),

customer_value AS (
    SELECT
        co.customer_unique_id,
        co.delivered_order_count,
        SUM(oi.price) AS gross_item_value
    FROM customer_orders co
    JOIN olist_analytics.order_items oi
        ON co.order_id = oi.order_id
    GROUP BY
        co.customer_unique_id,
        co.delivered_order_count
)

SELECT
    CASE
        WHEN delivered_order_count = 1
            THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(SUM(gross_item_value), 2)
        AS total_gross_item_value,

    ROUND(AVG(gross_item_value), 2)
        AS avg_item_value_per_customer,

    ROUND(
        SUM(gross_item_value) /
        SUM(delivered_order_count),
        2
    ) AS avg_item_value_per_delivered_order

FROM customer_value
GROUP BY customer_segment
ORDER BY total_gross_item_value DESC;



-- =====================================================
-- SECTION 5.3: CUSTOMER ORDER-FREQUENCY DISTRIBUTION
-- =====================================================

WITH customer_order_counts AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS delivered_order_count
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    CASE
        WHEN delivered_order_count = 1 THEN '1 order'
        WHEN delivered_order_count = 2 THEN '2 orders'
        WHEN delivered_order_count = 3 THEN '3 orders'
        WHEN delivered_order_count = 4 THEN '4 orders'
        ELSE '5+ orders'
    END AS purchase_frequency,

    COUNT(*) AS total_customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM customer_order_counts
GROUP BY purchase_frequency
ORDER BY
    CASE purchase_frequency
        WHEN '1 order' THEN 1
        WHEN '2 orders' THEN 2
        WHEN '3 orders' THEN 3
        WHEN '4 orders' THEN 4
        WHEN '5+ orders' THEN 5
    END;



-- =====================================================
-- SECTION 5.4: CUSTOMER VALUE AND REPEAT RATE BY STATE
-- =====================================================

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.customer_state,
        o.order_id
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),

customer_summary AS (
    SELECT
        customer_unique_id,
        customer_state,
        COUNT(DISTINCT order_id) AS delivered_order_count
    FROM customer_orders
    GROUP BY customer_unique_id, customer_state
),

customer_value AS (
    SELECT
        co.customer_unique_id,
        co.customer_state,
        cs.delivered_order_count,
        SUM(oi.price) AS gross_item_value
    FROM customer_orders co
    JOIN customer_summary cs
        ON co.customer_unique_id = cs.customer_unique_id
       AND co.customer_state = cs.customer_state
    JOIN olist_analytics.order_items oi
        ON co.order_id = oi.order_id
    GROUP BY
        co.customer_unique_id,
        co.customer_state,
        cs.delivered_order_count
)

SELECT
    customer_state,
    COUNT(*) AS total_customers,

    SUM(
        CASE WHEN delivered_order_count > 1 THEN 1 ELSE 0 END
    ) AS repeat_customers,

    ROUND(
        100.0 * SUM(
            CASE WHEN delivered_order_count > 1 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS repeat_customer_percentage,

    ROUND(AVG(gross_item_value), 2)
        AS avg_item_value_per_customer,

    ROUND(SUM(gross_item_value), 2)
        AS total_gross_item_value

FROM customer_value
GROUP BY customer_state
HAVING COUNT(*) >= 500
ORDER BY repeat_customer_percentage DESC;



-- =====================================================
-- SECTION 5.5: CUSTOMER VALUE RECONCILIATION
-- =====================================================

SELECT
    COUNT(*) AS state_customer_rows,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(gross_item_value), 2) AS total_gross_item_value
FROM (
    SELECT
        c.customer_unique_id,
        SUM(oi.price) AS gross_item_value
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN olist_analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) AS customer_totals;



-- =====================================================
-- SECTION 5.6: CUSTOMER RECENCY ANALYSIS
-- =====================================================

WITH customer_last_order AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS delivered_order_count
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

dataset_reference AS (
    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date
    FROM olist_analytics.orders
)

SELECT
    CASE
        WHEN DATEDIFF(
            dr.dataset_end_date,
            clo.last_order_date
        ) <= 90 THEN '0-90 days'
        WHEN DATEDIFF(
            dr.dataset_end_date,
            clo.last_order_date
        ) <= 180 THEN '91-180 days'
        WHEN DATEDIFF(
            dr.dataset_end_date,
            clo.last_order_date
        ) <= 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS recency_group,

    COUNT(*) AS total_customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(AVG(clo.delivered_order_count), 2)
        AS avg_delivered_orders

FROM customer_last_order clo
CROSS JOIN dataset_reference dr
GROUP BY recency_group
ORDER BY
    CASE recency_group
        WHEN '0-90 days' THEN 1
        WHEN '91-180 days' THEN 2
        WHEN '181-365 days' THEN 3
        WHEN '365+ days' THEN 4
    END;



-- =====================================================
-- SECTION 5.7: CUSTOMER RECENCY DATE RANGE VALIDATION
-- =====================================================

SELECT
    MIN(order_purchase_timestamp) AS earliest_order_date,
    MAX(order_purchase_timestamp) AS latest_order_date,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders
FROM olist_analytics.orders;



-- =====================================================
-- SECTION 5.8: CUSTOMER-LEVEL RFM BASE TABLE
-- =====================================================

WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS delivered_order_count,
        SUM(oi.price) AS total_gross_item_value
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN olist_analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

reference_date AS (
    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date
    FROM olist_analytics.orders
)

SELECT
    cm.customer_unique_id,
    cm.last_purchase_date,

    DATEDIFF(
        rd.dataset_end_date,
        cm.last_purchase_date
    ) AS recency_days,

    cm.delivered_order_count AS frequency,

    ROUND(
        cm.total_gross_item_value,
        2
    ) AS monetary_value

FROM customer_metrics cm
CROSS JOIN reference_date rd
ORDER BY monetary_value DESC
LIMIT 20;



-- =====================================================
-- SECTION 5.9: CREATE CUSTOMER RFM VIEW
-- =====================================================

CREATE OR REPLACE VIEW olist_analytics.vw_customer_rfm AS

WITH customer_metrics AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary_value
    FROM olist_analytics.customers c
    JOIN olist_analytics.orders o
        ON c.customer_id = o.customer_id
    JOIN olist_analytics.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),

reference_date AS (
    SELECT
        MAX(order_purchase_timestamp) AS dataset_end_date
    FROM olist_analytics.orders
)

SELECT
    cm.customer_unique_id,
    cm.last_purchase_date,

    DATEDIFF(
        rd.dataset_end_date,
        cm.last_purchase_date
    ) AS recency_days,

    cm.frequency,

    ROUND(cm.monetary_value, 2) AS monetary_value

FROM customer_metrics cm
CROSS JOIN reference_date rd;



-- =====================================================
-- SECTION 5.10: VALIDATE CUSTOMER RFM VIEW
-- =====================================================

SELECT
    COUNT(*) AS unique_customers,
    ROUND(AVG(recency_days), 2) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_delivered_orders,
    ROUND(AVG(monetary_value), 2) AS avg_customer_item_value,
    SUM(frequency) AS total_delivered_orders,
    ROUND(SUM(monetary_value), 2) AS total_gross_item_value
FROM olist_analytics.vw_customer_rfm;



-- =====================================================
-- SECTION 5.11: CUSTOMER RFM SCORING
-- =====================================================

WITH scored_customers AS (
    SELECT
        customer_unique_id,
        last_purchase_date,
        recency_days,
        frequency,
        monetary_value,

        6 - NTILE(5) OVER (
            ORDER BY recency_days ASC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score

    FROM olist_analytics.vw_customer_rfm
)

SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,

    CONCAT(
        recency_score,
        frequency_score,
        monetary_score
    ) AS rfm_score

FROM scored_customers
ORDER BY
    recency_score DESC,
    frequency_score DESC,
    monetary_score DESC
LIMIT 20;



-- =====================================================
-- SECTION 5.12: RFM SCORE DISTRIBUTION VALIDATION
-- =====================================================

WITH scored_customers AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,

        6 - NTILE(5) OVER (
            ORDER BY recency_days ASC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value ASC
        ) AS monetary_score

    FROM olist_analytics.vw_customer_rfm
)

SELECT
    recency_score,
    frequency_score,
    monetary_score,
    COUNT(*) AS customer_count
FROM scored_customers
GROUP BY
    recency_score,
    frequency_score,
    monetary_score
ORDER BY
    recency_score DESC,
    frequency_score DESC,
    monetary_score DESC;



-- =====================================================
-- SECTION 5.13: FREQUENCY SCORE VALIDATION
-- =====================================================

SELECT
    frequency_score,
    frequency,
    COUNT(*) AS customer_count
FROM (
    SELECT
        frequency,
        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score
    FROM olist_analytics.vw_customer_rfm
) AS frequency_groups
GROUP BY
    frequency_score,
    frequency
ORDER BY
    frequency_score DESC,
    frequency DESC;



-- =====================================================
-- SECTION 5.14: BEHAVIOUR-BASED CUSTOMER SEGMENTATION
-- =====================================================

SELECT
    CASE
        WHEN frequency >= 4
            THEN 'High-frequency customer'

        WHEN recency_days <= 180 AND frequency >= 2
            THEN 'Recent repeat customer'

        WHEN recency_days <= 180 AND frequency = 1
            THEN 'Recent one-time customer'

        WHEN recency_days > 180 AND frequency >= 2
            THEN 'Previously active repeat customer'

        ELSE 'Previously active one-time customer'
    END AS customer_segment,

    COUNT(*) AS total_customers,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,

    ROUND(AVG(frequency), 2)
        AS avg_delivered_orders,

    ROUND(AVG(monetary_value), 2)
        AS avg_customer_item_value

FROM olist_analytics.vw_customer_rfm

GROUP BY customer_segment

ORDER BY total_customers DESC;



-- =====================================================
-- SECTION 5.15: CUSTOMER SEGMENT VALUE CONTRIBUTION
-- =====================================================

WITH customer_segments AS (
    SELECT
        customer_unique_id,
        frequency,
        recency_days,
        monetary_value,

        CASE
            WHEN frequency >= 4
                THEN 'High-frequency customer'

            WHEN recency_days <= 180 AND frequency >= 2
                THEN 'Recent repeat customer'

            WHEN recency_days <= 180 AND frequency = 1
                THEN 'Recent one-time customer'

            WHEN recency_days > 180 AND frequency >= 2
                THEN 'Previously active repeat customer'

            ELSE 'Previously active one-time customer'
        END AS customer_segment

    FROM olist_analytics.vw_customer_rfm
)

SELECT
    customer_segment,
    COUNT(*) AS total_customers,

    ROUND(
        SUM(monetary_value),
        2
    ) AS total_gross_item_value,

    ROUND(
        100.0 * SUM(monetary_value)
        / SUM(SUM(monetary_value)) OVER (),
        2
    ) AS share_of_item_value_pct,

    ROUND(
        AVG(monetary_value),
        2
    ) AS avg_item_value_per_customer

FROM customer_segments

GROUP BY customer_segment

ORDER BY total_gross_item_value DESC;



-- =====================================================
-- SECTION 5.16: CUSTOMER SEGMENT RECONCILIATION
-- =====================================================

WITH customer_segments AS (
    SELECT
        customer_unique_id,
        frequency,
        recency_days,
        monetary_value,

        CASE
            WHEN frequency >= 4
                THEN 'High-frequency customer'
            WHEN recency_days <= 180 AND frequency >= 2
                THEN 'Recent repeat customer'
            WHEN recency_days <= 180 AND frequency = 1
                THEN 'Recent one-time customer'
            WHEN recency_days > 180 AND frequency >= 2
                THEN 'Previously active repeat customer'
            ELSE 'Previously active one-time customer'
        END AS customer_segment

    FROM olist_analytics.vw_customer_rfm
)

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(monetary_value), 2) AS total_gross_item_value,
    SUM(frequency) AS total_delivered_orders
FROM customer_segments;



-- =====================================================
-- SECTION 6.1: SELLER PERFORMANCE BASELINE
-- =====================================================

WITH seller_sales AS (
    SELECT
        oi.seller_id,
        COUNT(*) AS items_sold,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price) AS gross_item_value,
        SUM(oi.freight_value) AS freight_value,
        AVG(oi.price) AS avg_item_price
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
),

seller_reviews AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT r.order_id) AS reviewed_orders,
        AVG(r.review_score) AS avg_review_score,
        SUM(
            CASE
                WHEN r.review_score <= 2 THEN 1
                ELSE 0
            END
        ) AS low_score_review_rows
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    JOIN olist_analytics.reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    ss.items_sold,
    ss.total_orders,
    ROUND(ss.gross_item_value, 2) AS gross_item_value,
    ROUND(ss.freight_value, 2) AS freight_value,
    ROUND(ss.avg_item_price, 2) AS avg_item_price,
    sr.reviewed_orders,
    ROUND(sr.avg_review_score, 2) AS avg_review_score,
    sr.low_score_review_rows
FROM seller_sales ss
JOIN olist_analytics.sellers s
    ON ss.seller_id = s.seller_id
LEFT JOIN seller_reviews sr
    ON ss.seller_id = sr.seller_id
ORDER BY ss.gross_item_value DESC
LIMIT 20;



-- =====================================================
-- SECTION 6.2: SELLER DELIVERY PERFORMANCE & RISK
-- =====================================================

WITH seller_delivery AS (
    SELECT
        oi.seller_id,
        o.order_id,

        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS days_vs_estimate

    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL

    GROUP BY
        oi.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,

    COUNT(*) AS delivered_orders,

    SUM(
        CASE
            WHEN sd.days_vs_estimate > 0 THEN 1
            ELSE 0
        END
    ) AS late_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN sd.days_vs_estimate > 0 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        AVG(sd.days_vs_estimate),
        2
    ) AS avg_days_vs_estimate

FROM seller_delivery sd
JOIN olist_analytics.sellers s
    ON sd.seller_id = s.seller_id

GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state

HAVING COUNT(*) >= 50

ORDER BY
    late_delivery_rate_pct DESC,
    late_orders DESC

LIMIT 20;



-- =====================================================
-- SECTION 6.3: SELLER DELIVERY RISK VS CUSTOMER REVIEWS
-- =====================================================

WITH seller_delivery AS (
    SELECT
        oi.seller_id,
        o.order_id,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS days_vs_estimate
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY
        oi.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

seller_delivery_summary AS (
    SELECT
        seller_id,
        COUNT(*) AS delivered_orders,
        SUM(
            CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END
        ) AS late_orders,
        ROUND(
            100.0 * SUM(
                CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END
            ) / COUNT(*),
            2
        ) AS late_delivery_rate_pct
    FROM seller_delivery
    GROUP BY seller_id
),

seller_review_summary AS (
    SELECT
        oi.seller_id,
        COUNT(*) AS review_rows,
        ROUND(AVG(r.review_score), 2) AS avg_review_score,
        SUM(
            CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END
        ) AS low_score_review_rows,
        ROUND(
            100.0 * SUM(
                CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END
            ) / COUNT(*),
            2
        ) AS low_score_review_rate_pct
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    JOIN olist_analytics.reviews r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    d.delivered_orders,
    d.late_orders,
    d.late_delivery_rate_pct,
    r.review_rows,
    r.avg_review_score,
    r.low_score_review_rows,
    r.low_score_review_rate_pct
FROM seller_delivery_summary d
JOIN seller_review_summary r
    ON d.seller_id = r.seller_id
JOIN olist_analytics.sellers s
    ON d.seller_id = s.seller_id
WHERE d.delivered_orders >= 50
ORDER BY
    d.late_delivery_rate_pct DESC,
    d.late_orders DESC
LIMIT 20;




-- =====================================================
-- SECTION 6.4: CORRECTED SELLER REVIEW METRICS
-- One review outcome per order before seller aggregation
-- =====================================================

WITH order_review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_order_review_score
    FROM olist_analytics.reviews
    GROUP BY order_id
),

seller_order_reviews AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        ors.avg_order_review_score
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    JOIN order_review_summary ors
        ON o.order_id = ors.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.seller_id,
        oi.order_id,
        ors.avg_order_review_score
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS reviewed_seller_orders,
    ROUND(AVG(sor.avg_order_review_score), 2)
        AS avg_order_review_score,
    SUM(
        CASE
            WHEN sor.avg_order_review_score <= 2 THEN 1
            ELSE 0
        END
    ) AS low_score_seller_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN sor.avg_order_review_score <= 2 THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS low_score_order_rate_pct
FROM seller_order_reviews sor
JOIN olist_analytics.sellers s
    ON sor.seller_id = s.seller_id
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
HAVING COUNT(*) >= 50
ORDER BY
    low_score_order_rate_pct DESC,
    reviewed_seller_orders DESC
LIMIT 20;



-- =====================================================
-- SECTION 6.5: COMBINED SELLER RISK SCORECARD
-- =====================================================

WITH seller_delivery AS (
    SELECT
        oi.seller_id,
        o.order_id,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS days_vs_estimate
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY
        oi.seller_id,
        o.order_id,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
),

delivery_summary AS (
    SELECT
        seller_id,
        COUNT(*) AS delivered_orders,
        SUM(
            CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END
        ) AS late_orders,
        ROUND(
            100.0 * SUM(
                CASE WHEN days_vs_estimate > 0 THEN 1 ELSE 0 END
            ) / COUNT(*),
            2
        ) AS late_delivery_rate_pct
    FROM seller_delivery
    GROUP BY seller_id
),

order_review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_order_review_score
    FROM olist_analytics.reviews
    GROUP BY order_id
),

seller_order_reviews AS (
    SELECT
        oi.seller_id,
        oi.order_id,
        ors.avg_order_review_score
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    JOIN order_review_summary ors
        ON o.order_id = ors.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.seller_id,
        oi.order_id,
        ors.avg_order_review_score
),

review_summary AS (
    SELECT
        seller_id,
        COUNT(*) AS reviewed_seller_orders,
        ROUND(AVG(avg_order_review_score), 2)
            AS avg_order_review_score,
        SUM(
            CASE WHEN avg_order_review_score <= 2
                 THEN 1 ELSE 0 END
        ) AS low_score_seller_orders,
        ROUND(
            100.0 * SUM(
                CASE WHEN avg_order_review_score <= 2
                     THEN 1 ELSE 0 END
            ) / COUNT(*),
            2
        ) AS low_score_order_rate_pct
    FROM seller_order_reviews
    GROUP BY seller_id
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    d.delivered_orders,
    d.late_orders,
    d.late_delivery_rate_pct,
    r.reviewed_seller_orders,
    r.avg_order_review_score,
    r.low_score_seller_orders,
    r.low_score_order_rate_pct,
    CASE
        WHEN d.late_delivery_rate_pct >= 20
             AND r.low_score_order_rate_pct >= 30
            THEN 'High combined risk'
        WHEN d.late_delivery_rate_pct >= 15
             OR r.low_score_order_rate_pct >= 25
            THEN 'Needs investigation'
        ELSE 'Lower observed risk'
    END AS seller_risk_category
FROM delivery_summary d
JOIN review_summary r
    ON d.seller_id = r.seller_id
JOIN olist_analytics.sellers s
    ON d.seller_id = s.seller_id
WHERE d.delivered_orders >= 50
  AND r.reviewed_seller_orders >= 50
ORDER BY
    CASE
        WHEN d.late_delivery_rate_pct >= 20
             AND r.low_score_order_rate_pct >= 30 THEN 1
        WHEN d.late_delivery_rate_pct >= 15
             OR r.low_score_order_rate_pct >= 25 THEN 2
        ELSE 3
    END,
    d.late_delivery_rate_pct DESC,
    r.low_score_order_rate_pct DESC
LIMIT 30;



-- =====================================================
-- SECTION 6.6: SELLER ANALYTICS RECONCILIATION
-- =====================================================

WITH seller_order_base AS (
    SELECT
        oi.seller_id,
        o.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    FROM olist_analytics.order_items oi
    JOIN olist_analytics.orders o
        ON oi.order_id = o.order_id
    GROUP BY
        oi.seller_id,
        o.order_id,
        o.order_status,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
)

SELECT
    COUNT(*) AS seller_order_combinations,
    COUNT(DISTINCT seller_id) AS sellers_with_orders,

    SUM(
        CASE WHEN order_status = 'delivered'
             THEN 1 ELSE 0 END
    ) AS delivered_seller_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NOT NULL
             AND order_estimated_delivery_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS delivered_seller_orders_with_delivery_dates,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND (
                 order_delivered_customer_date IS NULL
                 OR order_estimated_delivery_date IS NULL
             )
            THEN 1 ELSE 0
        END
    ) AS delivered_seller_orders_missing_delivery_dates

FROM seller_order_base;



-- =====================================================
-- SECTION 7.1: FINAL PROJECT-WIDE DATA VALIDATION
-- =====================================================

SELECT
    'orders' AS dataset,
    COUNT(*) AS row_count
FROM olist_analytics.orders

UNION ALL

SELECT
    'order_items',
    COUNT(*)
FROM olist_analytics.order_items

UNION ALL

SELECT
    'customers',
    COUNT(*)
FROM olist_analytics.customers

UNION ALL

SELECT
    'products',
    COUNT(*)
FROM olist_analytics.products

UNION ALL

SELECT
    'sellers',
    COUNT(*)
FROM olist_analytics.sellers

UNION ALL

SELECT
    'payments',
    COUNT(*)
FROM olist_analytics.payments

UNION ALL

SELECT
    'reviews',
    COUNT(*)
FROM olist_analytics.reviews

UNION ALL

SELECT
    'category_translation',
    COUNT(*)
FROM olist_analytics.category_translation;



-- =====================================================
-- SECTION 7.2: VERIFY ANALYTICAL VIEWS
-- =====================================================

SELECT
    'vw_product_performance' AS view_name,
    COUNT(*) AS row_count
FROM olist_analytics.vw_product_performance

UNION ALL

SELECT
    'vw_delivery_performance',
    COUNT(*)
FROM olist_analytics.vw_delivery_performance

UNION ALL

SELECT
    'vw_state_delivery_performance',
    COUNT(*)
FROM olist_analytics.vw_state_delivery_performance

UNION ALL

SELECT
    'vw_customer_rfm',
    COUNT(*)
FROM olist_analytics.vw_customer_rfm;




-- =====================================================
-- SECTION 7.3: PRODUCT PERFORMANCE RECONCILIATION
-- =====================================================

SELECT
    COUNT(*) AS product_rows,
    SUM(items_sold) AS total_item_rows,
    ROUND(SUM(gross_item_value), 2) AS total_gross_item_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value
FROM olist_analytics.vw_product_performance;



-- =====================================================
-- SECTION 7.4: CUSTOMER RFM RECONCILIATION
-- =====================================================

SELECT
    COUNT(*) AS rfm_customer_count,
    SUM(frequency) AS total_delivered_orders,
    ROUND(SUM(monetary_value), 2) AS total_gross_item_value,
    ROUND(AVG(frequency), 4) AS avg_orders_per_customer,
    ROUND(AVG(monetary_value), 2) AS avg_value_per_customer
FROM olist_analytics.vw_customer_rfm;




-- =====================================================
-- SECTION 7.5: DELIVERY PERFORMANCE RECONCILIATION
-- =====================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS delivered_with_actual_date,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_estimated_delivery_date IS NOT NULL
            THEN 1
            ELSE 0
        END
    ) AS delivered_with_estimated_date

FROM olist_analytics.vw_delivery_performance;


-- SECTION 7.6: INSPECT DELIVERY VIEW LOGIC

SHOW CREATE VIEW olist_analytics.vw_delivery_performance;


-- SECTION 7.6: VIEW DEFINITION DETAILS

SHOW CREATE VIEW olist_analytics.vw_delivery_performance;





-- =====================================================
-- SECTION 7.6: SOURCE DELIVERY DATE QUALITY CHECK
-- =====================================================

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_delivered_customer_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS delivered_missing_actual_date,

    SUM(
        CASE
            WHEN order_status = 'delivered'
             AND order_estimated_delivery_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS delivered_missing_estimated_date

FROM olist_analytics.orders;

USE olist_analytics;

CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(oi.total_items, 0) AS total_items,
    COALESCE(oi.total_item_value, 0) AS total_item_value,
    COALESCE(oi.total_freight_value, 0) AS total_freight_value,
    COALESCE(pay.total_payment_value, 0) AS total_payment_value

FROM orders o

LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS total_items,
        ROUND(SUM(price), 2) AS total_item_value,
        ROUND(SUM(freight_value), 2) AS total_freight_value
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id

LEFT JOIN (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS total_payment_value
    FROM payments
    GROUP BY order_id
) pay
    ON o.order_id = pay.order_id;
    
    
SHOW CREATE VIEW vw_order_summary;

SELECT COUNT(*) AS total_rows
FROM vw_order_summary;

SELECT *
FROM vw_order_summary
LIMIT 10;