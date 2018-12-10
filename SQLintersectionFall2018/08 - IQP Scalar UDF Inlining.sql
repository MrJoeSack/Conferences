-- *************************************************** --
-- Scalar UDF Inlining
-- *************************************************** --
USE [tpch10g-btree];
GO

ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

CREATE OR ALTER FUNCTION dbo.CalcAvgQuantityByPartKey
	(@PartKey INT)
RETURNS INT
AS
BEGIN
        DECLARE @Quantity INT

        SELECT @Quantity = AVG([L_Quantity])
        FROM [dbo].[lineitem]
        WHERE [L_PartKey] = @PartKey

        RETURN (@Quantity)
END
GO

-- Remember - use tpch10g-btree

-- Before
-- ~ 23 seconds
SELECT TOP 1000
       L_OrderKey,
       L_PartKey,
       L_SuppKey,
       L_ExtendedPrice,
       dbo.CalcAvgQuantityByPartKey(L_PartKey)
FROM dbo.lineitem
WHERE L_Quantity > 44
ORDER BY L_Tax DESC
OPTION (RECOMPILE,USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));

-- After
-- ~ 11 seconds
SELECT TOP 1000
       L_OrderKey,
       L_PartKey,
       L_SuppKey,
       L_ExtendedPrice,
       dbo.CalcAvgQuantityByPartKey(L_PartKey)
FROM dbo.lineitem
WHERE L_Quantity > 44
ORDER BY L_Tax DESC
OPTION (RECOMPILE);
