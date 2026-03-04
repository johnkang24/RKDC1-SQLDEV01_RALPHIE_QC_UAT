CREATE PROCEDURE [dbo].[ValidateQCApproval]
(
	@parent_ID INT
)
AS

SET NOCOUNT ON

--DECLARE @parent_ID INT
--SET @parent_ID = 87912

DECLARE @QCApprovalValidation TABLE (
	error_type VARCHAR(100),
	error_level INT,
	error_msg VARCHAR(100),
	error_count INT
)

--STEP 1: suspect file check
INSERT @QCApprovalValidation (error_type, error_level, error_msg, error_count)
SELECT 
    'unique_serials' AS check_name,
	1 errorlevel,
	'Failed',
	SUM(serial_count)
FROM (
    SELECT 
        serial, 
        COUNT(*) AS serial_count
    FROM [dbo].[ORIGINAL]
    WHERE parent_id = @parent_id
    GROUP BY serial
) AS serial_counts
HAVING MAX(serial_count) > 1 
UNION ALL
SELECT 
    'client_code missing',
	1 errorlevel,
	'Failed',
	COUNT(client_code)
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND client_code IS NOT NULL
HAVING COUNT(client_code) = 0


--STEP 2: get any suspect records
DECLARE @SuspectRecords TABLE (
    id VARCHAR(100),
    error VARCHAR(100),
	salutation VARCHAR(100),
	addressee1 VARCHAR(100),
	address1 VARCHAR(100),
	city VARCHAR(100),
	state VARCHAR(100),
	zip VARCHAR(100),
	Original_ID INT
);
INSERT INTO @SuspectRecords
EXEC [GetSuspectRecordData] @parent_id = @parent_ID;

INSERT @QCApprovalValidation (error_type, error_level, error_msg, error_count)
SELECT 'Suspect Records', 1, error, COUNT(*)
FROM @SuspectRecords GROUP BY error;

--STEP 2: get any suspect records
DECLARE @SuspectFileRecords TABLE (
	check_name VARCHAR(100),
	status VARCHAR(100)
)
INSERT INTO @SuspectFileRecords
EXEC [GetSuspectFileData] @parent_id = @parent_ID;
INSERT @QCApprovalValidation (error_type, error_level, error_msg, error_count)
SELECT 'Suspect File Data', 1, check_name, COUNT(*)
FROM @SuspectFileRecords
WHERE status='Failed'
GROUP BY check_name;

--STEP 3: send back all
SELECT * FROM @QCApprovalValidation

