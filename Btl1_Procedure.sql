CREATE OR REPLACE PROCEDURE proc_create_order (
    p_customer_id       IN  NUMBER,
    p_employee_id       IN  NUMBER,
    p_branch_id         IN  NUMBER,
    p_payment_method    IN  VARCHAR2,
    p_tax_usd           IN  NUMBER DEFAULT 0,
    p_total_price_usd   IN  NUMBER DEFAULT 0,
    p_order_id          OUT NUMBER
)
AUTHID DEFINER
AS
    v_user              VARCHAR2(30);
    v_allowed_branch    NUMBER;
    v_local_branch      NUMBER;
    v_current_schema    VARCHAR2(30);
    v_count             NUMBER;
    v_new_order_id      NUMBER;

  FUNCTION get_table_name(p_branch NUMBER, p_table VARCHAR2)
    RETURN VARCHAR2
    IS
    BEGIN
      IF p_branch = v_local_branch THEN
          RETURN 'BRANCH' || p_branch || '.' || p_table;
      ELSE
          RETURN 'BRANCH' || p_branch || '.' || p_table || '@branch' || p_branch || '_link';
      END IF;
  END;
BEGIN
    v_user := SYS_CONTEXT('USERENV', 'SESSION_USER');
    v_current_schema := SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA');

    v_local_branch := TO_NUMBER(REGEXP_SUBSTR(v_current_schema, '[0-9]+'));

    CASE v_user
        WHEN 'TRUONGCN1' THEN v_allowed_branch := 1;
        WHEN 'NHANVIEN1' THEN v_allowed_branch := 1;
        WHEN 'TRUONGCN2' THEN v_allowed_branch := 2;
        WHEN 'NHANVIEN2' THEN v_allowed_branch := 2;
        WHEN 'TRUONGCN3' THEN v_allowed_branch := 3;
        WHEN 'NHANVIEN3' THEN v_allowed_branch := 3;
        ELSE
            RAISE_APPLICATION_ERROR(
                -20001,
                'User ' || v_user || ' khong co quyen tao don hang'
            );
    END CASE;

    IF p_branch_id <> v_allowed_branch THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'User ' || v_user || ' chi duoc tao don hang cho Branch ' || v_allowed_branch
        );
    END IF;

    IF NVL(p_tax_usd, 0) < 0 OR NVL(p_total_price_usd, 0) < 0 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'TAX_USD va TOTAL_PRICE_USD khong duoc am'
        );
    END IF;

    -- Kiểm tra khách hàng tồn tại
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM ' || get_table_name(p_branch_id, 'CUSTOMERS') ||
        ' WHERE customer_id = :1'
    INTO v_count
    USING p_customer_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Customer khong ton tai');
    END IF;

    -- Kiểm tra nhân viên thuộc đúng chi nhánh
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM ' || get_table_name(p_branch_id, 'EMPLOYEES') ||
        ' WHERE employee_id = :1 AND branch_id = :2'
    INTO v_count
    USING p_employee_id, p_branch_id;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Employee khong ton tai hoac khong thuoc Branch ' || p_branch_id
        );
    END IF;

    -- Lấy ORDER_ID lớn nhất toàn hệ thống
    EXECUTE IMMEDIATE '
        SELECT NVL(MAX(max_order_id), 0) + 1
        FROM (
            SELECT MAX(order_id) AS max_order_id FROM ' || get_table_name(1, 'ORDERS') || '
            UNION ALL
            SELECT MAX(order_id) AS max_order_id FROM ' || get_table_name(2, 'ORDERS') || '
            UNION ALL
            SELECT MAX(order_id) AS max_order_id FROM ' || get_table_name(3, 'ORDERS') || '
        )'
    INTO v_new_order_id;

    -- Thêm đơn hàng vào đúng chi nhánh
    EXECUTE IMMEDIATE
        'INSERT INTO ' || get_table_name(p_branch_id, 'ORDERS') || ' (
            order_id,
            customer_id,
            employee_id,
            branch_id,
            payment_method,
            tax_usd,
            total_price_usd
        )
        VALUES (:1, :2, :3, :4, :5, :6, :7)'
    USING
        v_new_order_id,
        p_customer_id,
        p_employee_id,
        p_branch_id,
        p_payment_method,
        NVL(p_tax_usd, 0),
        NVL(p_total_price_usd, 0);

    p_order_id := v_new_order_id;

    COMMIT;
END;
/

DECLARE
    v_order_id NUMBER;
BEGIN
    proc_create_order(
        p_customer_id     => 11,
        p_employee_id     => 353,
        p_branch_id       => 2,
        p_payment_method  => 'Cash',
        p_tax_usd         => 3,
        p_total_price_usd => 95,
        p_order_id        => v_order_id
    );

    DBMS_OUTPUT.PUT_LINE('Order ID moi: ' || v_order_id);
END;
/









DELETE FROM order_items
WHERE order_id = ;

DELETE FROM orders
WHERE order_id = ;

COMMIT;

SELECT * 
FROM BRANCH2.orders
ORDER BY ORDER_ID DESC;