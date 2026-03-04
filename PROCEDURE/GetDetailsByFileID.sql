
CREATE PROCEDURE [dbo].[GetDetailsByFileID]
(
	@FileID INT
)
AS

SET NOCOUNT ON
DECLARE @testing BIT = 0

--DECLARE @FileID INT
--SET @FileID = 60
--SET @testing = 1

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @AdvJobNo INT

--STEP 1: fetch Adv Job # to use to pull detail data from COMS
SELECT TOP 1 @AdvJobNo=Advantage_Job_ID
	FROM FileLog
	WHERE FileID=CAST(@FileID AS INT)

IF OBJECT_ID('tempdb..#tmpPkgPhases') IS NOT NULL
    DROP TABLE #tmpPkgPhases

CREATE TABLE #tmpPkgPhases
(
	Id VARCHAR(255),
	Name VARCHAR(255),
	QuoteId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	Job_Name__c VARCHAR(MAX),
	SB_Creative_Name__c VARCHAR(MAX),
	CPQ_Package__c NVARCHAR(MAX),
	CPQ_Phase__c NVARCHAR(MAX),
	SBQQ__Description__c NVARCHAR(MAX),
	CPQ_Job_Specific_Name__c NVARCHAR(MAX),
	CPQ_Estimated_Quantity__c INT,
	SB_DM_Prelim_Quantity__c INT,
	CPQ_Mail_Ship_Date__c DATETIME,
)

--/*
--STEP 1: Get all initial data
SET @LinkedServer = 'COMS_UATSB'
SET @OPENQUERY = 'SELECT *
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.Job_Name__c, SB_Creative_Name__r.Name, CPQ_Package__c, CPQ_Phase__c, SBQQ__Description__c, CPQ_Job_Specific_Name__c, CPQ_Estimated_Quantity__c, SB_DM_Prelim_Quantity__c, CPQ_Mail_Ship_Date__c
	FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Advantage_Job_Code__c =' + CAST(@AdvJobNo AS VARCHAR(20)) 
	+ '  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL ' + ' '')' 

--PRINT @OPENQUERY+@TSQL
INSERT #tmpPkgPhases
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	SELECT * FROM #tmpPkgPhases ORDER BY CPQ_Package__c, CPQ_Phase__c

	SELECT CASE WHEN Child_ID IS NULL THEN Parent_ID ELSE Child_ID END DeliverableID, COUNT(*) TotalRecords
		FROM ORIGINAL 
		WHERE FileID=@FileID
		GROUP BY CASE WHEN Child_ID IS NULL THEN Parent_ID ELSE Child_ID END
END

SELECT A.*, B.Advantage_Job_Code__c, B.Name, B.CPQ_Job_Specific_Name__c, B.SB_Creative_Name__c, B.CPQ_Package__c, B.CPQ_Phase__c, B.CPQ_Mail_Ship_Date__c, B.CPQ_Estimated_Quantity__c, B.SB_DM_Prelim_Quantity__c, C.Client_Code, C.Vertical 
FROM (SELECT CASE WHEN Child_ID IS NULL THEN Parent_ID ELSE Child_ID END DeliverableID, COUNT(*) TotalRecords
	FROM ORIGINAL 
	WHERE FileID=@FileID
	GROUP BY CASE WHEN Child_ID IS NULL THEN Parent_ID ELSE Child_ID END) A 
	JOIN #tmpPkgPhases B ON CAST(RIGHT(B.Name,7) AS INT)=A.DeliverableID
	JOIN FileLog C ON C.FileID=@FileID
ORDER BY B.CPQ_Package__c, B.CPQ_Phase__c, A.DeliverableID

