-- ==========================================================
-- TRIGGER
-- ==========================================================
-- Trigger 1: Kiểm tra tồn kho trước khi Insert, update; cập nhật tồn kho, tính tiền
CREATE OR REPLACE TRIGGER TRG_AFTER_ORDER_ITEM
AFTER INSERT OR UPDATE OR DELETE ON ORDER_ITEMS
FOR EACH ROW
DECLARE
    v_branch_id NUMBER;
    v_order_id NUMBER;
    v_product_id NUMBER;
    v_qty_diff NUMBER := 0;
    v_price_diff NUMBER := 0;
    v_current_stock NUMBER;
BEGIN
    IF INSERTING THEN
        v_order_id := :NEW.order_id;
        v_product_id := :NEW.product_id;
        v_qty_diff := - :NEW.quantity;
        v_price_diff := NVL(:NEW.total_price_usd, 0);

    ELSIF DELETING THEN
        v_order_id := :OLD.order_id;
        v_product_id := :OLD.product_id;
        v_qty_diff := :OLD.quantity;
        v_price_diff := - NVL(:OLD.total_price_usd, 0);

    ELSIF UPDATING THEN
        v_order_id := :NEW.order_id;
        v_product_id := :NEW.product_id;
        v_qty_diff := :OLD.quantity - :NEW.quantity;
        v_price_diff := NVL(:NEW.total_price_usd, 0) - NVL(:OLD.total_price_usd, 0);
    END IF;

    SELECT branch_id INTO v_branch_id
    FROM ORDERS
    WHERE order_id = v_order_id;

    SELECT stock_quantity INTO v_current_stock
    FROM PRODUCTS_STOCK
    WHERE product_id = v_product_id
      AND branch_id = v_branch_id;

    IF (v_current_stock + v_qty_diff) < 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Loi: Khong du hang trong kho!');
    END IF;

    UPDATE PRODUCTS_STOCK
    SET stock_quantity = stock_quantity + v_qty_diff
    WHERE product_id = v_product_id
      AND branch_id = v_branch_id;

    UPDATE ORDERS
    SET total_price_usd = NVL(total_price_usd, 0) + v_price_diff
    WHERE order_id = v_order_id;
END;
/

-- Trigger 2: Tự động tính toán giá tiền Item
CREATE OR REPLACE TRIGGER TRG_CALCULATE_ITEM_TOTAL
BEFORE INSERT OR UPDATE ON ORDER_ITEMS
FOR EACH ROW
BEGIN
    :NEW.discount_amount_usd := (:NEW.unit_price_usd * :NEW.quantity) * (:NEW.discount_percent / 100);
    :NEW.total_price_usd := (:NEW.unit_price_usd * :NEW.quantity) - :NEW.discount_amount_usd;
END;
/
