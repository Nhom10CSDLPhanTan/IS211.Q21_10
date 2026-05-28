---Cau truy van chua toi uu
---Tìm top 10 sản phẩm có doanh thu cao nhất trong tháng 05/2024 trên toàn hệ thống 3 chi nhánh
SELECT
    product_id,
    product_name,
    category,
    brand,
    SUM(quantity) AS total_quantity,
    SUM(total_price_usd) AS total_revenue,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM (
    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH1.ORDERS o,
        BRANCH1.ORDER_ITEMS oi,
        BRANCH1.PRODUCTS_INFO pi,
        BRANCH1.CUSTOMERS c,
        BRANCH1.EMPLOYEES e,
        BRANCH1.BRANCHES b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'

    UNION

    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH2.ORDERS@giamdoc2_link o,
        BRANCH2.ORDER_ITEMS@giamdoc2_link oi,
        BRANCH2.PRODUCTS_INFO@giamdoc2_link pi,
        BRANCH2.CUSTOMERS@giamdoc2_link c,
        BRANCH2.EMPLOYEES@giamdoc2_link e,
        BRANCH2.BRANCHES@giamdoc2_link b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'

    UNION

    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH3.ORDERS@giamdoc3_link o,
        BRANCH3.ORDER_ITEMS@giamdoc3_link oi,
        BRANCH3.PRODUCTS_INFO@giamdoc3_link pi,
        BRANCH3.CUSTOMERS@giamdoc3_link c,
        BRANCH3.EMPLOYEES@giamdoc3_link e,
        BRANCH3.BRANCHES@giamdoc3_link b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'
)
GROUP BY
    product_id,
    product_name,
    category,
    brand
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

--explain cho chưa tối ưu
EXPLAIN PLAN FOR
SELECT
    product_id,
    product_name,
    category,
    brand,
    SUM(quantity) AS total_quantity,
    SUM(total_price_usd) AS total_revenue,
    COUNT(DISTINCT order_id) AS number_of_orders
FROM (
    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH1.ORDERS o,
        BRANCH1.ORDER_ITEMS oi,
        BRANCH1.PRODUCTS_INFO pi,
        BRANCH1.CUSTOMERS c,
        BRANCH1.EMPLOYEES e,
        BRANCH1.BRANCHES b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'

    UNION

    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH2.ORDERS@giamdoc2_link o,
        BRANCH2.ORDER_ITEMS@giamdoc2_link oi,
        BRANCH2.PRODUCTS_INFO@giamdoc2_link pi,
        BRANCH2.CUSTOMERS@giamdoc2_link c,
        BRANCH2.EMPLOYEES@giamdoc2_link e,
        BRANCH2.BRANCHES@giamdoc2_link b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'

    UNION

    SELECT
        pi.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        oi.quantity,
        oi.total_price_usd,
        o.order_id
    FROM
        BRANCH3.ORDERS@giamdoc3_link o,
        BRANCH3.ORDER_ITEMS@giamdoc3_link oi,
        BRANCH3.PRODUCTS_INFO@giamdoc3_link pi,
        BRANCH3.CUSTOMERS@giamdoc3_link c,
        BRANCH3.EMPLOYEES@giamdoc3_link e,
        BRANCH3.BRANCHES@giamdoc3_link b
    WHERE
        o.order_id = oi.order_id
        AND oi.product_id = pi.product_id
        AND o.customer_id = c.customer_id
        AND o.employee_id = e.employee_id
        AND o.branch_id = b.branch_id
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2024-05'
)
GROUP BY
    product_id,
    product_name,
    category,
    brand
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);


---tối ưu câu truy vấn phù hợp cho phân tán
----query tối ưu
WITH branch_sales AS (
    SELECT
        'BRANCH1' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH1.ORDERS o
    JOIN BRANCH1.ORDER_ITEMS oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id

    UNION ALL

    SELECT
        'BRANCH2' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH2.ORDERS@giamdoc2_link o
    JOIN BRANCH2.ORDER_ITEMS@giamdoc2_link oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id

    UNION ALL

    SELECT
        'BRANCH3' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH3.ORDERS@giamdoc3_link o
    JOIN BRANCH3.ORDER_ITEMS@giamdoc3_link oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id
),
total_product_sales AS (
    SELECT
        product_id,
        SUM(total_quantity) AS total_quantity,
        SUM(total_revenue) AS total_revenue,
        SUM(number_of_orders) AS number_of_orders
    FROM branch_sales
    GROUP BY product_id
)
SELECT
    pi.product_id,
    pi.product_name,
    pi.category,
    pi.brand,
    tps.total_quantity,
    tps.total_revenue,
    tps.number_of_orders
FROM total_product_sales tps
JOIN BRANCH1.PRODUCTS_INFO pi
    ON tps.product_id = pi.product_id
ORDER BY tps.total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

---explain
EXPLAIN PLAN FOR
WITH branch_sales AS (
    SELECT
        'BRANCH1' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH1.ORDERS o
    JOIN BRANCH1.ORDER_ITEMS oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id

    UNION ALL

    SELECT
        'BRANCH2' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH2.ORDERS@giamdoc2_link o
    JOIN BRANCH2.ORDER_ITEMS@giamdoc2_link oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id

    UNION ALL

    SELECT
        'BRANCH3' AS source_branch,
        oi.product_id,
        SUM(oi.quantity) AS total_quantity,
        SUM(oi.total_price_usd) AS total_revenue,
        COUNT(DISTINCT o.order_id) AS number_of_orders
    FROM BRANCH3.ORDERS@giamdoc3_link o
    JOIN BRANCH3.ORDER_ITEMS@giamdoc3_link oi
        ON o.order_id = oi.order_id
    WHERE o.order_date >= TIMESTAMP '2024-05-01 00:00:00'
      AND o.order_date <  TIMESTAMP '2024-06-01 00:00:00'
    GROUP BY oi.product_id
),
total_product_sales AS (
    SELECT
        product_id,
        SUM(total_quantity) AS total_quantity,
        SUM(total_revenue) AS total_revenue,
        SUM(number_of_orders) AS number_of_orders
    FROM branch_sales
    GROUP BY product_id
)
SELECT
    pi.product_id,
    pi.product_name,
    pi.category,
    pi.brand,
    tps.total_quantity,
    tps.total_revenue,
    tps.number_of_orders
FROM total_product_sales tps
JOIN BRANCH1.PRODUCTS_INFO pi
    ON tps.product_id = pi.product_id
ORDER BY tps.total_revenue DESC
FETCH FIRST 10 ROWS ONLY;

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);
/