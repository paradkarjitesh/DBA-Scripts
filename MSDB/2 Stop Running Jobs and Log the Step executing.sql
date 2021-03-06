/**************************************************************************
** CREATED BY:   Bulent Gucuk
** CREATED DATE: 2019.02.26
** CREATED FOR:  Stopping the jobs before maintenance
** NOTES:	The script depends on the DBA database and table named dbo.JobsRunning
**			If you get an error make sure to alter the script to accomandate the
**			database and table name, when executed it will log all the jobs running at
**			step and will stop the job.  Run it only once, truncate command will truncate
**			the table and you will lose the list of jobs enabled before
***************************************************************************/
USE msdb;
GO
DECLARE @RowId SMALLINT = 1
	, @MaxRowId SMALLINT
	, @job_name SYSNAME;

TRUNCATE TABLE DBA.dbo.JobsRunning;

DROP TABLE IF EXISTS #Jobs;
CREATE TABLE #Jobs
           (job_id               UNIQUEIDENTIFIER NOT NULL,  
           last_run_date         INT              NOT NULL,  
           last_run_time         INT              NOT NULL,  
           next_run_date         INT              NOT NULL,  
           next_run_time         INT              NOT NULL,  
           next_run_schedule_id  INT              NOT NULL,  
           requested_to_run      INT              NOT NULL, -- BOOL  
           request_source        INT              NOT NULL,  
           request_source_id     sysname          COLLATE database_default NULL,  
           running               INT              NOT NULL, -- BOOL  
           current_step          INT              NOT NULL,  
           current_retry_attempt INT              NOT NULL,  
           job_state             INT              NOT NULL
		   );

INSERT INTO #Jobs
EXEC master.dbo.xp_sqlagent_enum_jobs 1,dbo;

INSERT INTO DBA.dbo.JobsRunning
SELECT
	  ROW_NUMBER () OVER(ORDER BY J.NAME) AS RowId
	, j.name AS job_name
	, j.job_id
	, ja.start_execution_date
	, t.current_step AS current_executed_step_id
	, Js.step_name
--INTO DBA.dbo.JobsRunning
FROM	#Jobs AS t
	INNER JOIN dbo.sysjobs AS j ON j.job_id = t.job_id
	INNER JOIN dbo.sysjobactivity AS ja ON ja.job_id = j.job_id
	INNER JOIN dbo.sysjobsteps AS js ON js.job_id = t.job_id AND t.current_step = js.step_id
WHERE	t.running = 1
AND		ja.session_id = (SELECT TOP 1 session_id FROM msdb.dbo.syssessions ORDER BY agent_start_date DESC)

SELECT @MaxRowId = @@ROWCOUNT;

SELECT @MaxRowId, * from DBA.DBO.JobsRunning;

WHILE @RowId <= @MaxRowId
	BEGIN
		SELECT @job_name = job_name
		FROM	DBA.dbo.JobsRunning
		WHERE	RowId = @RowId;

		EXEC msdb.dbo.sp_stop_job @job_name = @job_name;

		SELECT @RowId = @RowId + 1;
	END
