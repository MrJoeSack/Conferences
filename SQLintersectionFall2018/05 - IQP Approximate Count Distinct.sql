-- *************************************************** --
-- Approximate Count DISTINCT
-- *************************************************** --
USE [tpch10g-btree];
GO

ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

SELECT COUNT(DISTINCT [L_OrderKey])
FROM [dbo].[lineitem];

SELECT APPROX_COUNT_DISTINCT([L_OrderKey])
FROM [dbo].[lineitem];