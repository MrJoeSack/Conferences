-- *************************************************** --
-- Row mode MGF
-- *************************************************** --
ALTER DATABASE WideWorldImportersDW 
	SET COMPATIBILITY_LEVEL = 150;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

USE WideWorldImportersDW;
GO

-- Simulate out-of-date scenario
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 1;
GO

-- Make sure only the SELECT is highlighted
SELECT   
	fo.[Order Key], fo.Description,
	si.[Lead Time Days]
FROM    Fact.OrderHistory AS fo
INNER HASH JOIN Dimension.[Stock Item] AS si 
	ON fo.[Stock Item Key] = si.[Stock Item Key]
WHERE   fo.[Lineage Key] = 9
	AND si.[Lead Time Days] > 19;

-- Cleanup
UPDATE STATISTICS Fact.OrderHistory 
WITH ROWCOUNT = 3702672;
GO

USE [tpch10g-cci];
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO

-- What is the max used memory?
/* TPC_H  Query 12 - Shipping Modes and Order Priority */
SELECT	L_SHIPMODE,
	SUM(	CASE	WHEN O_ORDERPRIORITY  = '1-URGENT'	OR
			     O_ORDERPRIORITY  = '2-HIGH' 
			THEN 1 
			ELSE 0 
		END)	AS HIGH_LINE_COUNT,
	SUM(	CASE	WHEN O_ORDERPRIORITY <> '1-URGENT'	AND
			     O_ORDERPRIORITY <> '2-HIGH'
			THEN 1
			ELSE 0
		END)	AS LOW_LINE_COUNT
FROM	ORDERS,
	LINEITEM
WHERE	O_ORDERKEY	= L_ORDERKEY		AND
	L_SHIPMODE	IN ('FOB','MAIL')		AND
	L_COMMITDATE	< L_RECEIPTDATE		AND
	L_SHIPDATE	< L_COMMITDATE		AND
	L_RECEIPTDATE	>= '1997-01-01'			AND
	L_RECEIPTDATE	< dateadd(yy, 1, '1997-01-01')
GROUP	BY	L_SHIPMODE
ORDER	BY	L_SHIPMODE;
