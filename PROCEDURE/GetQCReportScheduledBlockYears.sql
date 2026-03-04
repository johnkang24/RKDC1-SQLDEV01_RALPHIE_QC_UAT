CREATE PROCEDURE [dbo].[GetQCReportScheduledBlockYears]
AS

DECLARE @quotes NVARCHAR(4000)
DECLARE @schedules NVARCHAR(4000)

SELECT @quotes = STRING_AGG(QuoteID, ',')
FROM (
	SELECT DISTINCT QuoteID
	FROM dbo.FileLog fl
	JOIN dbo.ProcessLog pl ON fl.FileID = pl.FileID
) AS q


DECLARE @OPENQUERY NVARCHAR(MAX), @TSQL NVARCHAR(MAX), @LinkedServer nvarchar(4000)
SET @LinkedServer = 'COMS_UATSB'

SET @quotes = 'a10cX000004e7WnQAI,a10cX000004g86vQAA,a10cX000004r5SHQAY,a10cX000004WE7BQAW,a10cX000004qa0HQAQ,a10cX000004uRCvQAM,a10cX000004hsvhQAA'


-- Format for nested query inside OPENQUERY
SET @quotes = '''' + REPLACE(@quotes, ',', ''',''') + ''''
SET @quotes = REPLACE(@quotes, '''', '''''')


SET @OPENQUERY = '
	SELECT distinct SB_Schedule_Block__c
	FROM OPENQUERY([' + @LinkedServer + '],
		''SELECT SB_Schedule_Block__c 
		 FROM SBQQ__Quote__c 
		 WHERE SB_Schedule_Block__c != null AND id IN (' + @quotes + ')'')';

---- Save result to a temp table
CREATE TABLE #ScheduleBlocksIds (SB_Schedule_Block__c NVARCHAR(255));
INSERT INTO #ScheduleBlocksIds
EXEC(@OPENQUERY);

-- -- Assign value to variable
SELECT @schedules = STRING_AGG(SB_Schedule_Block__c, ',')
FROM (
	SELECT DISTINCT SB_Schedule_Block__c
	FROM #ScheduleBlocksIds
) AS sb;

SET @schedules = '''' + REPLACE(@schedules, ',', ''',''') + ''''
SET @schedules = REPLACE(@schedules, '''', '''''')

SET @OPENQUERY = '
	SELECT id, SB_Schedule__c, Name, SB_Year__c
	FROM OPENQUERY([' + @LinkedServer + '], 
		''SELECT id, SB_Schedule__c, Name, SB_Year__c FROM SB_Schedule_Block__c WHERE id IN (' + @schedules + ')'')';

IF OBJECT_ID('dbo.QC_REPORT_ScheduleBlocksData', 'U') IS NOT NULL
	DROP TABLE dbo.QC_REPORT_ScheduleBlocksData;

IF OBJECT_ID('dbo.QC_REPORT_ScheduleBlocksData', 'U') IS NULL
	CREATE TABLE dbo.QC_REPORT_ScheduleBlocksData (sch_bl_id NVARCHAR(255), quote_id NVARCHAR(255), Name NVARCHAR(255), SB_Year__c NVARCHAR(255));
INSERT INTO dbo.QC_REPORT_ScheduleBlocksData
EXEC(@OPENQUERY);

-- Update quote_id in QC_REPORT_ScheduleBlocksData by joining with SBQQ__Quote__c via sch_bl_id = SB_Schedule_Block__c
DECLARE @UpdateQuery NVARCHAR(MAX)
SET @UpdateQuery = '
UPDATE d
SET quote_id = q.id
FROM dbo.QC_REPORT_ScheduleBlocksData d
INNER JOIN OPENQUERY([' + @LinkedServer + '], 
	''SELECT id, SB_Schedule_Block__c FROM SBQQ__Quote__c''
) q
	ON d.sch_bl_id = q.SB_Schedule_Block__c;
'
EXEC(@UpdateQuery)


IF COL_LENGTH('dbo.QC_REPORT_ScheduleBlocksData', 'ProcessLog_id') IS NULL
BEGIN
	ALTER TABLE dbo.QC_REPORT_ScheduleBlocksData
	ADD ProcessLog_id INT;
	ALTER TABLE dbo.QC_REPORT_ScheduleBlocksData
	ADD CONSTRAINT FK_QC_REPORT_ScheduleBlocksData_ProcessLog
	FOREIGN KEY (ProcessLog_id) REFERENCES dbo.ProcessLog(ProcessLog_id);

	-- Update ProcessLog_id in QC_REPORT_ScheduleBlocksData by joining with ProcessLog on quote_id = QuoteID
	UPDATE d
	SET d.ProcessLog_id = p.ProcessLog_id
	FROM dbo.QC_REPORT_ScheduleBlocksData d
	INNER JOIN dbo.ProcessLog p
		ON d.quote_id = p.QuoteID;
END

-- Insert a sample row for testing
insert into dbo.QC_REPORT_ScheduleBlocksData Values ('knp', 'a10cX000004i9EzQAI', '03 2026', '2026', 144);
insert into dbo.QC_REPORT_ScheduleBlocksData Values ('knp', 'a10cX000004hsvhQAA', '25  2026', '2026', 149);
insert into dbo.QC_REPORT_ScheduleBlocksData Values ('knp', 'a10cX000004hsvhQAA', '25  2026', '2026', 151);
insert into dbo.QC_REPORT_ScheduleBlocksData Values ('knp', 'a10cX000004hsvhQAA', '25  2026', '2026', 153);
-- END TESTING


-- SELECT 'No Year' AS SB_YEAR__c
-- UNION ALL
SELECT DISTINCT SB_YEAR__c FROM QC_REPORT_ScheduleBlocksData;

DROP TABLE IF EXISTS #ScheduleBlocksIds;


