--Function: Hàm tính tổng doanh thu theo thương hiệu từ 3 chi nhánh trong 1 khoảng thời gian
CREATE OR REPLACE FUNCTION get_total_revenue_by_brand(

    p_brand      IN VARCHAR2,

    p_start_date IN DATE,

    p_end_date   IN DATE

)

RETURN VARCHAR2

AUTHID CURRENT_USER -- Giữ quyền Invoker's Rights để xử lý Role của Giám đốc

IS

    v_cn1_revenue   NUMBER := 0;

    v_cn2_revenue   NUMBER := 0;

    v_cn3_revenue   NUMBER := 0;

    v_total_revenue NUMBER := 0;

BEGIN



    -- =========================================================================

    -- 1. CHI NHÁNH 3 (LOCAL) - Schema Owner: branch3

    -- =========================================================================

    BEGIN

        SELECT NVL(SUM(oi3.total_price_usd), 0)

        INTO v_cn3_revenue

        FROM branch3.orders o3

        INNER JOIN branch3.order_items oi3

            ON o3.order_id = oi3.order_id

        INNER JOIN branch3.products_info p3

            ON oi3.product_id = p3.product_id

        WHERE p3.brand = p_brand

          AND o3.branch_id = 3

          AND o3.order_date BETWEEN p_start_date AND p_end_date;



    EXCEPTION

        WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE('Lỗi xảy ra tại Chi nhánh 3 (Local): ' || SQLERRM);

            v_cn3_revenue := 0;

    END;



    -- =========================================================================

    -- 2. CHI NHÁNH 1 (REMOTE) - Schema Owner: branch1 | DB Link: giamdoc1_link

    -- =========================================================================

    BEGIN

        SELECT NVL(SUM(oi1.total_price_usd), 0)

        INTO v_cn1_revenue

        FROM branch1.orders@giamdoc1_link o1

        INNER JOIN branch1.order_items@giamdoc1_link oi1

            ON o1.order_id = oi1.order_id

        INNER JOIN branch1.products_info@giamdoc1_link p1

            ON oi1.product_id = p1.product_id

        WHERE p1.brand = p_brand

          AND o1.branch_id = 1

          AND o1.order_date BETWEEN p_start_date AND p_end_date;



    EXCEPTION

        WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE('Lỗi xảy ra tại Chi nhánh 1 (Remote): ' || SQLERRM);

            v_cn1_revenue := 0;

    END;



    -- =========================================================================

    -- 3. CHI NHÁNH 2 (REMOTE) - Schema Owner: branch2 | DB Link: giamdoc2_link

    -- =========================================================================

    BEGIN

        SELECT NVL(SUM(oi2.total_price_usd), 0)

        INTO v_cn2_revenue

        FROM branch2.orders@giamdoc2_link o2

        INNER JOIN branch2.order_items@giamdoc2_link oi2

            ON o2.order_id = oi2.order_id

        INNER JOIN branch2.products_info@giamdoc2_link p2

            ON oi2.product_id = p2.product_id

        WHERE p2.brand = p_brand

          AND o2.branch_id = 2

          AND o2.order_date BETWEEN p_start_date AND p_end_date;



    EXCEPTION

        WHEN OTHERS THEN

            DBMS_OUTPUT.PUT_LINE('Lỗi xảy ra tại Chi nhánh 2 (Remote): ' || SQLERRM);

            v_cn2_revenue := 0;

    END;



    -- =========================================================================

    -- 4. TỔNG HỢP VÀ ĐỊNH DẠNG KẾT QUẢ DOANH THU TOÀN HỆ THỐNG

    -- =========================================================================

    v_total_revenue := v_cn3_revenue + v_cn1_revenue + v_cn2_revenue;



    RETURN 'Total Revenue: '

           || TO_CHAR(v_total_revenue, '999,999,999.99')

           || ' USD';



END;

/

--Grant quyền sử dụng cho giám đốc
 GRANT EXECUTE ON get_total_revenue_by_brand TO giamdoc;

--testcase 1:Dữ liệu hợp lệ
SELECT branch3.get_total_revenue_by_brand(

           'Apple',

           TO_DATE('01-01-2025', 'DD-MM-YYYY'),

           TO_DATE('31-12-2025', 'DD-MM-YYYY')

       ) AS revenue_2025

FROM dual;

--testcase 2: brand không tồn tại
SELECT branch3.get_total_revenue_by_brand(

           'UnknownBrand',

           TO_DATE('01-01-2025', 'DD-MM-YYYY'),

           TO_DATE('31-12-2025', 'DD-MM-YYYY')

       ) AS revenue_test_case_2

FROM dual;

--testcase 3: khoảng thời gian không hợp lệ
SELECT branch3.get_total_revenue_by_brand(

          'Apple',

          TO_DATE('01-01-2030', 'DD-MM-YYYY'),

          TO_DATE('31-12-2030', 'DD-MM-YYYY')

      ) AS revenue_test_case_3

FROM dual;
