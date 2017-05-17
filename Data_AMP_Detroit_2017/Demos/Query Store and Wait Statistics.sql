USE [master];
GO
ALTER DATABASE [WideWorldImportersDW] 
SET QUERY_STORE (	OPERATION_MODE = READ_WRITE, 
					DATA_FLUSH_INTERVAL_SECONDS = 60, 
					QUERY_CAPTURE_MODE = ALL,
					INTERVAL_LENGTH_MINUTES = 1);
GO

USE [WideWorldImportersDW];
GO

ALTER DATABASE CURRENT SET QUERY_STORE CLEAR ALL;

-- Next open up a separate window and execute the following
USE [WideWorldImportersDW];
GO

BEGIN TRANSACTION

DELETE[Fact].[Sale]
WHERE [Description] = 'DBA joke mug - mind if I join you? (White)' AND
	  [City Key] = 41568;
-- Hold off on rolling back until after the block
ROLLBACK TRANSACTION

-- Now back in this window, execute the following
SELECT SUM(Profit)
FROM [Fact].[Sale]
WHERE [Description] = 'DBA joke mug - mind if I join you? (White)';

-- After a few seconds - roll back the other transaction

EXECUTE sp_query_store_flush_db;


SELECT [q].[query_id], *
FROM sys.query_store_query_text AS [t]
INNER JOIN sys.query_store_query AS [q]
	ON [t].query_text_id = [q].query_text_id
WHERE query_sql_text LIKE '%SELECT SUM(%';


SELECT plan_id
FROM sys.query_store_plan
WHERE query_id = 2;


SELECT wait_category_desc, avg_query_wait_time_ms
FROM sys.query_store_wait_stats
WHERE	plan_id = 2 AND
		wait_category_desc NOT IN ('Unknown')
ORDER BY avg_query_wait_time_ms DESC;


