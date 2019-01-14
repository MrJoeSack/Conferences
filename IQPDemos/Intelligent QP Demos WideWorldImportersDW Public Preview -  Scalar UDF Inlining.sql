-- ******************************************************** --
-- Scalar UDF Inlining

-- See https://aka.ms/IQP for more background

-- Demo scripts: https://aka.ms/IQPDemos 

-- Demo uses SQL Server 2019 Public Preview and also works on Azure SQL DB

-- Email IntelligentQP@microsoft.com for questions\feedback
-- ******************************************************** --
USE WideWorldImportersDW;
GO

ALTER DATABASE WideWorldImportersDW 
SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE SCOPED CONFIGURATION 
CLEAR PROCEDURE_CACHE;
GO
/*
Adapted from SQL Server Books Online
https://docs.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sqlallproducts-allversions 
*/
CREATE OR ALTER FUNCTION 
	dbo.customer_category(@CustomerKey INT) 
RETURNS CHAR(10) AS
BEGIN
  DECLARE @total_amount DECIMAL(18,2);
  DECLARE @category CHAR(10);

  SELECT @total_amount = 
	SUM([Total Including Tax]) 
	FROM [Fact].[OrderHistory]
	WHERE [Customer Key] = @CustomerKey;

  IF @total_amount < 500000
    SET @category = 'REGULAR';
  ELSE IF @total_amount < 1000000
    SET @category = 'GOLD';
  ELSE 
    SET @category = 'PLATINUM';

  RETURN @category;
END
GO

-- Before (show actual query execution plan for legacy behavior)
SELECT TOP 100
		[Customer Key], [Customer],
       dbo.customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE,USE HINT('DISABLE_TSQL_SCALAR_UDF_INLINING'));

-- After (show actual query execution plan for Scalar UDF Inlining)
SELECT TOP 100
		[Customer Key], [Customer],
       dbo.customer_category([Customer Key]) AS [Discount Price]
FROM [Dimension].[Customer]
ORDER BY [Customer Key]
OPTION (RECOMPILE);


