---1. Tìm top 10 sản phẩm có doanh thu cao nhất trong tháng 05/2024 trên toàn hệ thống 3 chi nhánh
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
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2026-05'

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
        AND TO_CHAR(o.order_date, 'YYYY-MM') = '2026-05'
)
GROUP BY 
    product_id,
    product_name,
    category,
    brand
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
/

---2. Doanh thu theo phương thức thanh toán
SELECT 
    source_branch,
    payment_method,
    COUNT(*) AS total_orders,
    SUM(total_price_usd) AS total_revenue,
    ROUND(AVG(total_price_usd), 2) AS avg_order_value
FROM (
    SELECT 'BRANCH1' AS source_branch, payment_method, total_price_usd
    FROM BRANCH1.ORDERS

    UNION ALL

    SELECT 'BRANCH2' AS source_branch, payment_method, total_price_usd
    FROM BRANCH2.ORDERS@giamdoc2_link

    UNION ALL

    SELECT 'BRANCH3' AS source_branch, payment_method, total_price_usd
    FROM BRANCH3.ORDERS@giamdoc3_link
)
GROUP BY source_branch, payment_method
ORDER BY source_branch, total_revenue DESC;
/

---3. Khách hàng mua ở cả 3 chi nhánh
SELECT 
    c.customer_id,
    c.customer_name,
    c.city,
    c.country
FROM BRANCH1.CUSTOMERS c
WHERE c.customer_id IN (
    SELECT customer_id
    FROM BRANCH1.ORDERS

    INTERSECT

    SELECT customer_id
    FROM BRANCH2.ORDERS@giamdoc2_link

    INTERSECT

    SELECT customer_id
    FROM BRANCH3.ORDERS@giamdoc3_link
);
/

---4. Sản phẩm có tồn kho ở chi nhánh 1 nhưng chưa có ở chi nhánh 2
SELECT 
    pi.product_id,
    pi.product_name,
    pi.category,
    pi.brand
FROM BRANCH1.PRODUCTS_INFO pi
WHERE pi.product_id IN (
    SELECT product_id
    FROM BRANCH1.PRODUCTS_STOCK
    WHERE stock_quantity > 0

    MINUS

    SELECT product_id
    FROM BRANCH2.PRODUCTS_STOCK@giamdoc2_link
    WHERE stock_quantity > 0
);
/

---5. Sản phẩm đã bán ở tất cả 3 chi nhánh
WITH required_branches AS (
    SELECT 1 AS branch_id FROM dual
    UNION ALL SELECT 2 AS branch_id FROM dual
    UNION ALL SELECT 3 AS branch_id FROM dual
),
sold_products AS (
    SELECT DISTINCT 1 AS branch_id, oi.product_id
    FROM BRANCH1.ORDER_ITEMS oi
    JOIN BRANCH1.ORDERS o ON oi.order_id = o.order_id

    UNION ALL

    SELECT DISTINCT 2 AS branch_id, oi.product_id
    FROM BRANCH2.ORDER_ITEMS@giamdoc2_link oi
    JOIN BRANCH2.ORDERS@giamdoc2_link o ON oi.order_id = o.order_id

    UNION ALL

    SELECT DISTINCT 3 AS branch_id, oi.product_id
    FROM BRANCH3.ORDER_ITEMS@giamdoc3_link oi
    JOIN BRANCH3.ORDERS@giamdoc3_link o ON oi.order_id = o.order_id
)
SELECT 
    pi.product_id,
    pi.product_name,
    pi.category,
    pi.brand
FROM BRANCH1.PRODUCTS_INFO pi
WHERE NOT EXISTS (
    SELECT rb.branch_id
    FROM required_branches rb
    WHERE NOT EXISTS (
        SELECT 1
        FROM sold_products sp
        WHERE sp.product_id = pi.product_id
          AND sp.branch_id = rb.branch_id
    )
);
/

---6. Nhân viên có doanh thu cao
SELECT 
    source_branch,
    employee_id,
    employee_name,
    COUNT(order_id) AS total_orders,
    SUM(total_price_usd) AS total_revenue,
    ROUND(AVG(total_price_usd), 2) AS avg_order_value
FROM (
    SELECT 
        'BRANCH1' AS source_branch,
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        o.order_id,
        o.total_price_usd
    FROM BRANCH1.ORDERS o
    JOIN BRANCH1.EMPLOYEES e ON o.employee_id = e.employee_id

    UNION ALL

    SELECT 
        'BRANCH2' AS source_branch,
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        o.order_id,
        o.total_price_usd
    FROM BRANCH2.ORDERS@giamdoc2_link o
    JOIN BRANCH2.EMPLOYEES@giamdoc2_link e ON o.employee_id = e.employee_id

    UNION ALL

    SELECT 
        'BRANCH3' AS source_branch,
        e.employee_id,
        e.first_name || ' ' || e.last_name AS employee_name,
        o.order_id,
        o.total_price_usd
    FROM BRANCH3.ORDERS@giamdoc3_link o
    JOIN BRANCH3.EMPLOYEES@giamdoc3_link e ON o.employee_id = e.employee_id
)
GROUP BY source_branch, employee_id, employee_name
HAVING SUM(total_price_usd) >= 50000
ORDER BY total_revenue DESC;
/

---7. Loại sản phẩm có mức giảm giá cao
SELECT 
    category,
    COUNT(*) AS total_order_lines,
    SUM(quantity) AS total_quantity_sold,
    ROUND(AVG(discount_percent), 2) AS avg_discount_percent,
    ROUND(SUM(discount_amount_usd), 2) AS total_discount_amount,
    ROUND(SUM(total_price_usd), 2) AS total_revenue
FROM (
    SELECT pi.category, oi.quantity, oi.discount_percent,
           oi.discount_amount_usd, oi.total_price_usd
    FROM BRANCH1.ORDER_ITEMS oi
    JOIN BRANCH1.PRODUCTS_INFO pi ON oi.product_id = pi.product_id

    UNION ALL

    SELECT pi.category, oi.quantity, oi.discount_percent,
           oi.discount_amount_usd, oi.total_price_usd
    FROM BRANCH2.ORDER_ITEMS@giamdoc2_link oi
    JOIN BRANCH2.PRODUCTS_INFO@giamdoc2_link pi ON oi.product_id = pi.product_id

    UNION ALL

    SELECT pi.category, oi.quantity, oi.discount_percent,
           oi.discount_amount_usd, oi.total_price_usd
    FROM BRANCH3.ORDER_ITEMS@giamdoc3_link oi
    JOIN BRANCH3.PRODUCTS_INFO@giamdoc3_link pi ON oi.product_id = pi.product_id
)
GROUP BY category
HAVING AVG(discount_percent) >= 8
ORDER BY avg_discount_percent DESC;
/

---8. Đơn hàng bất thường cao hơn trung bình chi nhánh
WITH all_orders AS (
    SELECT 'BRANCH1' AS source_branch, order_id, order_date,
           customer_id, employee_id, payment_method, total_price_usd
    FROM BRANCH1.ORDERS

    UNION ALL

    SELECT 'BRANCH2' AS source_branch, order_id, order_date,
           customer_id, employee_id, payment_method, total_price_usd
    FROM BRANCH2.ORDERS@giamdoc2_link

    UNION ALL

    SELECT 'BRANCH3' AS source_branch, order_id, order_date,
           customer_id, employee_id, payment_method, total_price_usd
    FROM BRANCH3.ORDERS@giamdoc3_link
),
branch_avg AS (
    SELECT source_branch, AVG(total_price_usd) AS avg_branch_order_value
    FROM all_orders
    GROUP BY source_branch
)
SELECT 
    ao.source_branch,
    ao.order_id,
    ao.order_date,
    ao.customer_id,
    ao.employee_id,
    ao.payment_method,
    ao.total_price_usd,
    ROUND(ba.avg_branch_order_value, 2) AS avg_branch_order_value,
    ROUND(ao.total_price_usd / ba.avg_branch_order_value, 2) AS ratio_to_avg
FROM all_orders ao
JOIN branch_avg ba ON ao.source_branch = ba.source_branch
WHERE ao.total_price_usd > ba.avg_branch_order_value * 2
ORDER BY ratio_to_avg DESC;
/

---9. Sản phẩm bán nhiều nhưng tồn kho thấp toàn hệ thống
WITH sales AS (
    SELECT product_id, SUM(quantity) AS sold_quantity
    FROM BRANCH1.ORDER_ITEMS
    GROUP BY product_id

    UNION ALL

    SELECT product_id, SUM(quantity) AS sold_quantity
    FROM BRANCH2.ORDER_ITEMS@giamdoc2_link
    GROUP BY product_id

    UNION ALL

    SELECT product_id, SUM(quantity) AS sold_quantity
    FROM BRANCH3.ORDER_ITEMS@giamdoc3_link
    GROUP BY product_id
),
stock AS (
    SELECT product_id, SUM(stock_quantity) AS stock_quantity
    FROM BRANCH1.PRODUCTS_STOCK
    GROUP BY product_id

    UNION ALL

    SELECT product_id, SUM(stock_quantity) AS stock_quantity
    FROM BRANCH2.PRODUCTS_STOCK@giamdoc2_link
    GROUP BY product_id

    UNION ALL

    SELECT product_id, SUM(stock_quantity) AS stock_quantity
    FROM BRANCH3.PRODUCTS_STOCK@giamdoc3_link
    GROUP BY product_id
),
total_sales AS (
    SELECT product_id, SUM(sold_quantity) AS total_sold_quantity
    FROM sales
    GROUP BY product_id
),
total_stock AS (
    SELECT product_id, SUM(stock_quantity) AS total_stock_quantity
    FROM stock
    GROUP BY product_id
)
SELECT 
    pi.product_id,
    pi.product_name,
    pi.category,
    pi.brand,
    ts.total_sold_quantity,
    NVL(tst.total_stock_quantity, 0) AS total_stock_quantity,
    CASE 
        WHEN NVL(tst.total_stock_quantity, 0) = 0 THEN 'OUT_OF_STOCK'
        WHEN NVL(tst.total_stock_quantity, 0) < ts.total_sold_quantity * 0.2 THEN 'CRITICAL'
        WHEN NVL(tst.total_stock_quantity, 0) < ts.total_sold_quantity * 0.5 THEN 'LOW'
        ELSE 'NORMAL'
    END AS stock_status
FROM total_sales ts
JOIN BRANCH1.PRODUCTS_INFO pi ON ts.product_id = pi.product_id
LEFT JOIN total_stock tst ON ts.product_id = tst.product_id
WHERE NVL(tst.total_stock_quantity, 0) < ts.total_sold_quantity * 0.5
ORDER BY ts.total_sold_quantity DESC;
/

---10. Top sản phẩm theo doanh thu từng chi nhánh
WITH product_revenue AS (
    SELECT 'BRANCH1' AS source_branch, oi.product_id,
           SUM(oi.quantity) AS total_quantity,
           SUM(oi.total_price_usd) AS total_revenue
    FROM BRANCH1.ORDER_ITEMS oi
    JOIN BRANCH1.ORDERS o ON oi.order_id = o.order_id
    GROUP BY oi.product_id

    UNION ALL

    SELECT 'BRANCH2' AS source_branch, oi.product_id,
           SUM(oi.quantity) AS total_quantity,
           SUM(oi.total_price_usd) AS total_revenue
    FROM BRANCH2.ORDER_ITEMS@giamdoc2_link oi
    JOIN BRANCH2.ORDERS@giamdoc2_link o ON oi.order_id = o.order_id
    GROUP BY oi.product_id

    UNION ALL

    SELECT 'BRANCH3' AS source_branch, oi.product_id,
           SUM(oi.quantity) AS total_quantity,
           SUM(oi.total_price_usd) AS total_revenue
    FROM BRANCH3.ORDER_ITEMS@giamdoc3_link oi
    JOIN BRANCH3.ORDERS@giamdoc3_link o ON oi.order_id = o.order_id
    GROUP BY oi.product_id
),
ranked_products AS (
    SELECT 
        pr.source_branch,
        pr.product_id,
        pi.product_name,
        pi.category,
        pi.brand,
        pr.total_quantity,
        pr.total_revenue,
        RANK() OVER (
            PARTITION BY pr.source_branch
            ORDER BY pr.total_revenue DESC
        ) AS revenue_rank
    FROM product_revenue pr
    JOIN BRANCH1.PRODUCTS_INFO pi ON pr.product_id = pi.product_id
)
SELECT 
    source_branch,
    product_id,
    product_name,
    category,
    brand,
    total_quantity,
    total_revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 5
ORDER BY source_branch, revenue_rank;
