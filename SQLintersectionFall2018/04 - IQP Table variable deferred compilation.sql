-- *************************************************** --
-- Table variable deferred compilation
-- *************************************************** --
USE master;
GO

ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 140;
GO

USE [tpch10g-btree];
GO

-- ~ 20 - 50 seconds
DECLARE @LINEITEMS TABLE 
	(L_OrderKey INT NOT NULL,
	 L_Quantity INT NOT NULL
	);

INSERT @LINEITEMS
SELECT TOP 750000
	L_OrderKey, L_Quantity
FROM dbo.lineitem
WHERE L_Quantity = 43;

SELECT	O_OrderKey,
		O_CustKey,
		O_OrderStatus,
		L_QUANTITY
FROM	
	ORDERS,
	@LINEITEMS
WHERE	O_ORDERKEY	=	L_ORDERKEY
	AND O_OrderStatus = 'O'
OPTION (USE HINT('DISALLOW_BATCH_MODE'));
GO

USE master;
GO

-- ~ 7 - 8 seconds
ALTER DATABASE [tpch10g-btree] SET COMPATIBILITY_LEVEL = 150;
GO

USE [tpch10g-btree];
GO

DECLARE @LINEITEMS TABLE 
	(L_OrderKey INT NOT NULL,
	 L_Quantity INT NOT NULL
	);

INSERT @LINEITEMS
SELECT TOP 750000
	L_OrderKey, L_Quantity
FROM dbo.lineitem
WHERE L_Quantity = 43;

SELECT	O_OrderKey,
		O_CustKey,
		O_OrderStatus,
		L_QUANTITY
FROM	
	ORDERS,
	@LINEITEMS
WHERE	O_ORDERKEY	=	L_ORDERKEY
	AND O_OrderStatus = 'O'
OPTION (USE HINT('DISALLOW_BATCH_MODE'));
GO

