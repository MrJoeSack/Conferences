-- *************************************************** --
-- Scalar UDF Inlining
-- *************************************************** --
USE [tpch10g-btree];
GO

ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

CREATE OR ALTER FUNCTION dbo.discount_price(@price DECIMAL(12,2), @discount DECIMAL(12,2)) 
RETURNS DECIMAL (12,2) AS
BEGIN
  RETURN @price * (1 - @discount);
END
GO

-- ~ 20 seconds cold cache
SELECT L_SHIPDATE,
       O_SHIPPRIORITY,
       SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))
FROM LINEITEM,
     ORDERS
WHERE O_ORDERKEY = L_ORDERKEY
GROUP BY L_SHIPDATE,
         O_SHIPPRIORITY
ORDER BY L_SHIPDATE;

-- 30+ minutes - so we won't be doing this
-- Look at estimated plan
SELECT L_SHIPDATE,
       O_SHIPPRIORITY,
       SUM(dbo.discount_price(L_EXTENDEDPRICE, L_DISCOUNT))
FROM LINEITEM,
     ORDERS
WHERE O_ORDERKEY = L_ORDERKEY
GROUP BY L_SHIPDATE,
         O_SHIPPRIORITY
ORDER BY L_SHIPDATE
OPTION (RECOMPILE, USE HINT ('DISABLE_TSQL_SCALAR_UDF_INLINING'));

-- Scalar UDF Inlining in-effect
-- ~ 11 seconds
SELECT L_SHIPDATE,
       O_SHIPPRIORITY,
       SUM(dbo.discount_price(L_EXTENDEDPRICE, L_DISCOUNT))
FROM LINEITEM,
     ORDERS
WHERE O_ORDERKEY = L_ORDERKEY
GROUP BY L_SHIPDATE,
         O_SHIPPRIORITY
ORDER BY L_SHIPDATE;