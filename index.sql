SELECT index_name, table_name, uniqueness, visibility
FROM user_indexes
WHERE table_name IN (
    'ORDERS',
    'ORDER_ITEMS',
    'CUSTOMERS',
    'EMPLOYEES',
    'PRODUCTS_INFO',
    'PRODUCTS_STOCK'
)
ORDER BY table_name, index_name;
/*===============================================================================
DROP INDEX idx_products_stock_branch_product;
DROP INDEX idx_orders_date_order_join
--===============================================================================*/
ALTER SYSTEM FLUSH SHARED_POOL;

CREATE INDEX idx_orders_date_order_join
ON orders(order_date, order_id, customer_id, employee_id, branch_id, payment_method);

CREATE INDEX idx_products_stock_branch_product
ON products_stock(branch_id, product_id);


BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDERS', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'ORDER_ITEMS', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PRODUCTS_INFO', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PRODUCTS_STOCK', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'EMPLOYEES', CASCADE => TRUE);
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'CUSTOMERS', CASCADE => TRUE);
END;
/
EXPLAIN PLAN FOR
WITH branch2_detail AS (
    SELECT
        'BRANCH2' AS source_db,
        o.order_id,
        o.order_date,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        EXTRACT(MONTH FROM o.order_date) AS order_month,

        b.branch_id,
        b.branch_name,
        b.city AS branch_city,

        c.customer_id,
        c.customer_name,
        c.gender,
        c.age,
        c.country AS customer_country,
        c.city AS customer_city,

        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.salary,

        o.payment_method,
        o.tax_usd,
        o.total_price_usd AS order_total,

        oi.product_id,
        p.product_name,
        p.category,
        p.brand,

        oi.quantity,
        oi.unit_price_usd,
        oi.discount_percent,
        oi.discount_amount_usd,
        oi.total_price_usd AS item_total,

        ps.stock_quantity,
        ps.unit_price_usd AS stock_unit_price
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN employees e
        ON o.employee_id = e.employee_id
    JOIN branches b
        ON o.branch_id = b.branch_id
    JOIN products_info p
        ON oi.product_id = p.product_id
    JOIN products_stock ps
        ON p.product_id = ps.product_id
       AND o.branch_id = ps.branch_id
    WHERE o.order_date >= TIMESTAMP '2026-01-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2026-02-01 00:00:00'
),

branch1_detail AS (
    SELECT
        'BRANCH1' AS source_db,
        o.order_id,
        o.order_date,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        EXTRACT(MONTH FROM o.order_date) AS order_month,

        b.branch_id,
        b.branch_name,
        b.city AS branch_city,

        c.customer_id,
        c.customer_name,
        c.gender,
        c.age,
        c.country AS customer_country,
        c.city AS customer_city,

        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.salary,

        o.payment_method,
        o.tax_usd,
        o.total_price_usd AS order_total,

        oi.product_id,
        p.product_name,
        p.category,
        p.brand,

        oi.quantity,
        oi.unit_price_usd,
        oi.discount_percent,
        oi.discount_amount_usd,
        oi.total_price_usd AS item_total,

        ps.stock_quantity,
        ps.unit_price_usd AS stock_unit_price
    FROM branch1.orders@branch1_link o
    JOIN branch1.order_items@branch1_link oi
        ON o.order_id = oi.order_id
    JOIN branch1.customers@branch1_link c
        ON o.customer_id = c.customer_id
    JOIN branch1.employees@branch1_link e
        ON o.employee_id = e.employee_id
    JOIN branch1.branches@branch1_link b
        ON o.branch_id = b.branch_id
    JOIN branch1.products_info@branch1_link p
        ON oi.product_id = p.product_id
    JOIN branch1.products_stock@branch1_link ps
        ON p.product_id = ps.product_id
       AND o.branch_id = ps.branch_id
    WHERE o.order_date >= TIMESTAMP '2026-01-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2026-02-01 00:00:00'
),

branch3_detail AS (
    SELECT
        'BRANCH3' AS source_db,
        o.order_id,
        o.order_date,
        EXTRACT(YEAR FROM o.order_date) AS order_year,
        EXTRACT(MONTH FROM o.order_date) AS order_month,

        b.branch_id,
        b.branch_name,
        b.city AS branch_city,

        c.customer_id,
        c.customer_name,
        c.gender,
        c.age,
        c.country AS customer_country,
        c.city AS customer_city,

        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        e.salary,

        o.payment_method,
        o.tax_usd,
        o.total_price_usd AS order_total,

        oi.product_id,
        p.product_name,
        p.category,
        p.brand,

        oi.quantity,
        oi.unit_price_usd,
        oi.discount_percent,
        oi.discount_amount_usd,
        oi.total_price_usd AS item_total,

        ps.stock_quantity,
        ps.unit_price_usd AS stock_unit_price
    FROM branch3.orders@branch3_link o
    JOIN branch3.order_items@branch3_link oi
        ON o.order_id = oi.order_id
    JOIN branch3.customers@branch3_link c
        ON o.customer_id = c.customer_id
    JOIN branch3.employees@branch3_link e
        ON o.employee_id = e.employee_id
    JOIN branch3.branches@branch3_link b
        ON o.branch_id = b.branch_id
    JOIN branch3.products_info@branch3_link p
        ON oi.product_id = p.product_id
    JOIN branch3.products_stock@branch3_link ps
        ON p.product_id = ps.product_id
       AND o.branch_id = ps.branch_id
    WHERE o.order_date >= TIMESTAMP '2026-01-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2026-02-01 00:00:00'
),

all_detail AS (
    SELECT * FROM branch2_detail
    UNION ALL
    SELECT * FROM branch1_detail
    UNION ALL
    SELECT * FROM branch3_detail
),

monthly_category_summary AS (
    SELECT
        source_db,
        branch_id,
        branch_name,
        branch_city,
        order_year,
        order_month,
        category,
        brand,
        payment_method,

        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS total_customers,
        COUNT(DISTINCT employee_id) AS total_employees,
        COUNT(DISTINCT product_id) AS total_products,

        SUM(quantity) AS total_quantity,
        SUM(item_total) AS total_revenue,
        SUM(discount_amount_usd) AS total_discount,
        SUM(tax_usd) AS total_tax,

        ROUND(AVG(item_total), 2) AS avg_item_value,
        ROUND(AVG(order_total), 2) AS avg_order_value,
        ROUND(AVG(age), 2) AS avg_customer_age,
        ROUND(AVG(salary), 2) AS avg_employee_salary,
        ROUND(AVG(stock_quantity), 2) AS avg_stock_quantity
    FROM all_detail
    GROUP BY
        source_db,
        branch_id,
        branch_name,
        branch_city,
        order_year,
        order_month,
        category,
        brand,
        payment_method
    HAVING SUM(item_total) > 1000
),

employee_summary AS (
    SELECT
        source_db,
        branch_id,
        employee_id,
        employee_name,

        COUNT(DISTINCT order_id) AS employee_orders,
        COUNT(DISTINCT customer_id) AS employee_customers,
        SUM(quantity) AS employee_quantity,
        SUM(item_total) AS employee_revenue,
        ROUND(AVG(item_total), 2) AS employee_avg_item_value
    FROM all_detail
    GROUP BY
        source_db,
        branch_id,
        employee_id,
        employee_name
),

customer_summary AS (
    SELECT
        source_db,
        branch_id,
        customer_id,
        customer_name,
        gender,
        customer_country,
        customer_city,

        COUNT(DISTINCT order_id) AS customer_orders,
        COUNT(DISTINCT product_id) AS customer_products,
        SUM(quantity) AS customer_quantity,
        SUM(item_total) AS customer_revenue,
        ROUND(AVG(item_total), 2) AS customer_avg_item_value
    FROM all_detail
    GROUP BY
        source_db,
        branch_id,
        customer_id,
        customer_name,
        gender,
        customer_country,
        customer_city
),

ranked_report AS (
    SELECT
        mcs.*,

        RANK() OVER (
            PARTITION BY mcs.source_db, mcs.branch_id, mcs.order_year, mcs.order_month
            ORDER BY mcs.total_revenue DESC
        ) AS revenue_rank_in_month,

        DENSE_RANK() OVER (
            PARTITION BY mcs.category
            ORDER BY mcs.total_revenue DESC
        ) AS category_revenue_rank,

        SUM(mcs.total_revenue) OVER (
            PARTITION BY mcs.source_db, mcs.branch_id
        ) AS branch_total_revenue,

        ROUND(
            mcs.total_revenue /
            NULLIF(
                SUM(mcs.total_revenue) OVER (
                    PARTITION BY mcs.source_db, mcs.branch_id
                ),
                0
            ) * 100,
            2
        ) AS revenue_percent_in_branch
    FROM monthly_category_summary mcs
)

SELECT
    rr.source_db,
    rr.branch_id,
    rr.branch_name,
    rr.branch_city,
    rr.order_year,
    rr.order_month,
    rr.category,
    rr.brand,
    rr.payment_method,

    rr.total_orders,
    rr.total_customers,
    rr.total_employees,
    rr.total_products,
    rr.total_quantity,
    rr.total_revenue,
    rr.total_discount,
    rr.total_tax,
    rr.avg_item_value,
    rr.avg_order_value,
    rr.avg_customer_age,
    rr.avg_employee_salary,
    rr.avg_stock_quantity,

    rr.revenue_rank_in_month,
    rr.category_revenue_rank,
    rr.branch_total_revenue,
    rr.revenue_percent_in_branch,

    es.employee_id AS top_employee_id,
    es.employee_name AS top_employee_name,
    es.employee_revenue AS top_employee_revenue,

    cs.customer_id AS top_customer_id,
    cs.customer_name AS top_customer_name,
    cs.customer_revenue AS top_customer_revenue

FROM ranked_report rr

LEFT JOIN (
    SELECT *
    FROM (
        SELECT
            es.*,
            ROW_NUMBER() OVER (
                PARTITION BY es.source_db, es.branch_id
                ORDER BY es.employee_revenue DESC
            ) AS rn
        FROM employee_summary es
    )
    WHERE rn = 1
) es
    ON rr.source_db = es.source_db
   AND rr.branch_id = es.branch_id

LEFT JOIN (
    SELECT *
    FROM (
        SELECT
            cs.*,
            ROW_NUMBER() OVER (
                PARTITION BY cs.source_db, cs.branch_id
                ORDER BY cs.customer_revenue DESC
            ) AS rn
        FROM customer_summary cs
    )
    WHERE rn = 1
) cs
    ON rr.source_db = cs.source_db
   AND rr.branch_id = cs.branch_id

WHERE rr.revenue_rank_in_month <= 10

ORDER BY
    rr.source_db,
    rr.branch_id,
    rr.order_year,
    rr.order_month,
    rr.revenue_rank_in_month,
    rr.total_revenue DESC;
;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);