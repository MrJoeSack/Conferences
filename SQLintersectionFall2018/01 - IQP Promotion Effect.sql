-- *************************************************** --
-- TPC_H Query 14 - Promotion Effect
-- *************************************************** --
USE master;
GO

ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 150;
GO

USE [tpch10g-btree];
GO

SELECT 100.00 * SUM(   CASE
                           WHEN P_TYPE LIKE 'PROMO%' THEN
                               L_EXTENDEDPRICE * (1 - L_DISCOUNT)
                           ELSE
                               0
                       END
                   ) / SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS PROMO_REVENUE
FROM LINEITEM
    INNER JOIN PART
        ON L_PARTKEY = P_PARTKEY
WHERE L_SHIPDATE >= '1997-06-01'
      AND L_SHIPDATE < DATEADD(mm, 1, '1997-06-01');