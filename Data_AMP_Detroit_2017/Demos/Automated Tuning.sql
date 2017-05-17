USE [master];
GO
ALTER DATABASE [WideWorldImporters] 
SET QUERY_STORE (OPERATION_MODE = READ_WRITE, 
DATA_FLUSH_INTERVAL_SECONDS = 60, INTERVAL_LENGTH_MINUTES = 1, 
QUERY_CAPTURE_MODE = ALL);
GO

/********************************************************
*	SETUP - clear everything
********************************************************/
USE [WideWorldImporters];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE CURRENT SET QUERY_STORE CLEAR ALL;
ALTER DATABASE CURRENT SET 
AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = OFF);

/********************************************************
*	PART I
*	Plan regression identification.
********************************************************/

-- 1. Start workload - execute procedure 20 times:
-- Confirm that execution time is ~100ms (10 sec total)
-- Include Actual Execution Plan
BEGIN
    DECLARE @packagetypeid INT = 7;
    EXEC [dbo].[report] @packagetypeid
END
GO 20

-- 2. Execute procedure that causes plan regression
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

DECLARE @packagetypeid INT = 1;
EXEC [report] @packagetypeid;

-- 3. Start workload again - verify that is slower.
-- Execution time should be ~1sec per query (30sec in total)
BEGIN
    DECLARE @packagetypeid INT = 7;
    EXEC [dbo].[report] @packagetypeid;
END
GO 20

EXECUTE sp_query_store_flush_db;

-- 4. Find recommendation recommended by database:
SELECT reason, score,
      JSON_VALUE(details, '$.implementationDetails.script') script,
      planForceDetails.*
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [new plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.forcedPlanId'
          ) as planForceDetails;
-- Note: User can apply script and force plan to correct the error.
-- In part II will be shown better approach - automatic tuning.

/********************************************************
*	PART II
*	Automatic tuning
********************************************************/

/********************************************************
*	RESET - clear everything
********************************************************/
USE [WideWorldImporters];
GO
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE CURRENT SET QUERY_STORE CLEAR ALL;

ALTER DATABASE CURRENT SET 
AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);

-- Verify that actual state on FLGP is ON:
SELECT  [name], [actual_state_desc]
FROM    [sys].[database_automatic_tuning_options];

-- 1. Start workload - execute procedure 20 times:
-- Confirm that execution time is ~100ms (10 sec total)
-- Include Actual Execution Plan
BEGIN
    DECLARE @packagetypeid INT = 7;
    EXEC [dbo].[report] @packagetypeid
END
GO 20

-- 2. Execute procedure that causes plan regression
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;

DECLARE @packagetypeid INT = 1;
EXEC [report] @packagetypeid;

-- 3. Start workload again - verify that is slower.
-- Execution time should be ~1sec per query (30sec in total)
BEGIN
    DECLARE @packagetypeid INT = 7;
    EXEC [dbo].[report] @packagetypeid;
END
GO 20

-- 4. Find recommendation that returns query perf regression
SELECT reason, score,
	JSON_VALUE(state, '$.currentValue') state,
    JSON_VALUE(details, '$.implementationDetails.script') script,
    planForceDetails.*
FROM sys.dm_db_tuning_recommendations
  CROSS APPLY OPENJSON (Details, '$.planForceDetails')
    WITH (  [query_id] int '$.queryId',
            [new plan_id] int '$.regressedPlanId',
            [recommended plan_id] int '$.forcedPlanId'
          ) as planForceDetails;

		  
-- 5. Wait until recommendation is applied and start workload again - verify that it is faster.
-- Execution should be ~100ms per query, ~ 10sec total, query plan should have scan
BEGIN
    DECLARE @packagetypeid INT = 7;
    EXEC [dbo].[report] @packagetypeid;
END
GO 20

-- Open query store Tracked Queries and look at plan history