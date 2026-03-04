CREATE PROCEDURE [dbo].[GetQCReportForCultivationAndAcquisition]
(
	@adv_job_id NVARCHAR(100),
	@client NVARCHAR(100),
	@year INT,
	@schedule_blocks NVARCHAR(100),
	@qc_file_status NVARCHAR(50)
)
AS

/*
DECLARE @adv_job_id INT
SET @adv_job_id = 50957
*/

DECLARE @deliverable_name NVARCHAR(50)
DECLARE @quote_id NVARCHAR(50)
DECLARE @quoteline_id NVARCHAR(50)
DECLARE @schedules NVARCHAR(50)

-- get quote_id and quoteline_id from the query below

select @quote_id = QuoteID, @quoteline_id = QuoteLine_ID 
from 
	dbo.FileLog fl 
join 
	dbo.ProcessLog pl on fl.FileID = pl.FileID 
where 
	fl.Advantage_Job_ID IN (SELECT value FROM STRING_SPLIT(@adv_job_id, ','))
	AND (
		@client IS NULL OR @client = ''
		OR fl.Client_Code IN (SELECT value FROM STRING_SPLIT(@client, ','))
	)


PRINT 'QuoteID: ' + @quote_id
PRINT 'QuoteLine_ID: ' + @quoteline_id
	
-- get deliverable name, schedule block and year from COMS

DECLARE @SQL NVARCHAR(MAX)
DECLARE @OPENQUERY NVARCHAR(MAX), @TSQL NVARCHAR(MAX), @LinkedServer nvarchar(4000)

SET @LinkedServer = 'COMS_UATSB'

-- SET @OPENQUERY = '
-- 	SELECT Deliverable_Name__c
-- 	FROM OPENQUERY([' + @LinkedServer + '], 
-- 		''SELECT Deliverable_Name__c FROM SBQQ__QuoteLine__c WHERE id = ''''' + @quoteline_id + ''''''')';

-- -- Save result to a temp table
-- CREATE TABLE #DeliverableName (Deliverable_Name__c NVARCHAR(255));
-- INSERT INTO #DeliverableName
-- EXEC(@OPENQUERY);

-- -- Assign value to variable
-- SELECT @deliverable_name = Deliverable_Name__c FROM #DeliverableName;

-- -- Drop temp table
-- DROP TABLE #DeliverableName;

-- get [SB_Schedule_Block__c] from the Quote 

-- only for testing purposes
SET @deliverable_name = 'Test Deliverable Name'
-- SET @quote_id = 'a10cX000004F7ZxQAK'
-- END testing


SET @OPENQUERY = '
	SELECT SB_Schedule_Block__c
	FROM OPENQUERY([' + @LinkedServer + '], 
		''SELECT SB_Schedule_Block__c FROM SBQQ__Quote__c WHERE id IN (''''' + @quote_id + ''''')'')';

-- Save result to a temp table
CREATE TABLE #ScheduleBlocks (SB_Schedule_Block__c NVARCHAR(255));
INSERT INTO #ScheduleBlocks
EXEC(@OPENQUERY);

-- Assign value to variable
SELECT @schedules = SB_Schedule_Block__c FROM #ScheduleBlocks;

-- Drop temp table
DROP TABLE #ScheduleBlocks;

PRINT 'SB_Schedule_Block__c: ' + @schedules

DECLARE @sb_name NVARCHAR(50)
DECLARE @sb_year NVARCHAR(50)


SET @OPENQUERY = '
	SELECT Name, SB_Year__c
	FROM OPENQUERY([' + @LinkedServer + '], 
		''SELECT Name, SB_Year__c FROM SB_Schedule_Block__c WHERE id IN (''''' + @schedules + ''''')'')';

-- Save result to a temp table
CREATE TABLE #ScheduleBlocksData (SB_Name NVARCHAR(255), SB_Year__c NVARCHAR(255));
INSERT INTO #ScheduleBlocksData
EXEC(@OPENQUERY);

-- Assign value to variable
SELECT @sb_name = SB_Name, @sb_year = SB_Year__c FROM #ScheduleBlocksData;

-- Drop temp table
DROP TABLE #ScheduleBlocksData;


-- Parse qc_file_status into table of lowercase values
WITH qc_status AS (
	SELECT TRIM(LOWER(value)) AS status
	FROM STRING_SPLIT(@qc_file_status, ',')
),

-- Identify QuoteIDs that have at least one FileID (i.e., valid runs)
valid_quoteids AS (
	SELECT DISTINCT QuoteID, FileID
	FROM dbo.ProcessLog
	WHERE FileID IS NOT NULL
),

-- Main joined rows with valid FileID
base_result AS (
	SELECT 
		fl.Client_Code, 
		sb.SB_Year__c AS Year, 
		sb.Name AS Schedule_Block, 
		fl.Advantage_Job_ID, 
		pl.Job_Name, 
		pl.Parent_ID, 
		@deliverable_name AS Deliverable_Name, 
		pl.Mail_Date, 
		CASE 
			WHEN pl.RejectedBy IS NOT NULL OR pl.Rejected_Date IS NOT NULL THEN 'Rejected'
			WHEN pl.FileID IS NULL THEN 'Not Run'
			WHEN pl.QC_Approved = 1 THEN 'Approved'
			WHEN pl.QC_Approved = 0 THEN 'Pending'
			ELSE NULL
		END AS QC_Status, 
		pl.QC_File AS QC_File_Link,
		pl.Data_Loader,
		pl.LastModifiedDate,
		pl.QuoteID
	FROM dbo.FileLog fl
	JOIN dbo.ProcessLog pl ON fl.FileID = pl.FileID
	JOIN dbo.QC_REPORT_ScheduleBlocksData sb ON pl.ProcessLog_Id = sb.ProcessLog_Id
	WHERE 
		fl.Advantage_Job_ID IN (SELECT TRIM(value) FROM STRING_SPLIT(@adv_job_id, ','))
		AND (@client IS NULL OR @client = '' OR fl.Client_Code IN (SELECT TRIM(value) FROM STRING_SPLIT(@client, ',')))
		AND (@schedule_blocks IS NULL OR @schedule_blocks = '' OR sb.Name IN (SELECT TRIM(value) FROM STRING_SPLIT(@schedule_blocks, ',')))
),

-- Include FileID IS NULL records if their QuoteID appears in valid_quoteids
null_fileid_matches AS (
	SELECT 
		fl.Client_Code, 
		sb.SB_Year__c AS Year, 
		sb.Name AS Schedule_Block, 
		fl.Advantage_Job_ID, 
		pl.Job_Name, 
		pl.Parent_ID, 
		@deliverable_name AS Deliverable_Name, 
		pl.Mail_Date, 
		'Not Run' AS QC_Status, 
		pl.QC_File AS QC_File_Link,
		pl.Data_Loader,
		pl.LastModifiedDate,
		pl.QuoteID
	FROM dbo.ProcessLog pl
	JOIN valid_quoteids vq ON pl.QuoteID = vq.QuoteID
	JOIN dbo.FileLog fl ON fl.FileID = vq.FileID
	JOIN dbo.QC_REPORT_ScheduleBlocksData sb ON pl.ProcessLog_Id = sb.ProcessLog_Id
	WHERE 
		pl.FileID IS NULL
		AND (@client IS NULL OR @client = '' OR fl.Client_Code IN (SELECT TRIM(value) FROM STRING_SPLIT(@client, ',')))
		AND (@schedule_blocks IS NULL OR @schedule_blocks = '' OR sb.Name IN (SELECT TRIM(value) FROM STRING_SPLIT(@schedule_blocks, ',')))
)

-- --Final result combining both sources
SELECT 
	Client_Code, Year, Schedule_Block, Advantage_Job_ID, Job_Name, Parent_ID, Deliverable_Name, Mail_Date, QC_Status, QC_File_Link, Data_Loader, LastModifiedDate
FROM base_result
WHERE 
	@qc_file_status IS NULL OR @qc_file_status = ''
	OR EXISTS (
		SELECT 1 
		FROM qc_status s
		WHERE 
			(s.status = 'approved' AND base_result.QC_Status = 'Approved')
			OR (s.status = 'pending' AND base_result.QC_Status = 'Pending')
			OR (s.status = 'rejected' AND base_result.QC_Status = 'Rejected')
	)

UNION ALL

SELECT 
	Client_Code, Year, Schedule_Block, Advantage_Job_ID, Job_Name, Parent_ID, Deliverable_Name, Mail_Date, QC_Status, QC_File_Link, Data_Loader, LastModifiedDate
FROM null_fileid_matches
WHERE EXISTS (
	SELECT 1 FROM qc_status WHERE status = 'not run'
)

