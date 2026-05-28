
--1.1. Demo lỗi LOST UPDATE bằng READ COMMITTED 

COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

COMMIT;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT stock_quantity
FROM products_stock
WHERE product_id = 950



UPDATE products_stock
SET stock_quantity = 90
WHERE product_id = 950;

COMMIT;

ROLLBACK;
--Reset data
UPDATE products_stock
SET stock_quantity = 548
WHERE product_id = 950;

COMMIT;

--Non repeatable read
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
END;
/

SELECT product_id, branch_id, stock_quantity
FROM products_stock
WHERE product_id = 950

-- Kết quả lần 1: stock_quantity = 548


SELECT product_id, branch_id, stock_quantity
FROM products_stock
WHERE product_id = 950


-- Kết quả lần 2: stock_quantity = 150

COMMIT;

--Phantom read
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
END;

SELECT product_id, branch_id, stock_quantity
FROM products_stock
WHERE stock_quantity < 10
ORDER BY product_id DESC;

-- Lần 1: chưa có product_id = 999999

SELECT product_id, branch_id, stock_quantity
FROM products_stock
WHERE stock_quantity < 10
ORDER BY product_id DESC;

-- Lần 2: xuất hiện thêm product_id = 999999

COMMIT;

DELETE FROM PRODUCTS_INFO
WHERE PRODUCT_ID = 999999

--Deadlock
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITT;
BEGIN
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
END;
UPDATE products_stock
SET stock_quantity = stock_quantity + 1
WHERE product_id = 1
  AND branch_id = 2;

-- Chưa COMMIT
-- Branch2 đang giữ khóa dòng product_id = 1, branch_id = 2

UPDATE EMPLOYEES
SET branch_id = 2
WHERE employee_id BETWEEN 351 AND 700;

COMMIT;