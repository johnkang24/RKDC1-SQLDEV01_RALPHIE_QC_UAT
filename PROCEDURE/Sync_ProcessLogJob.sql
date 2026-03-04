
CREATE PROCEDURE [dbo].[Sync_ProcessLogJob]
(
	@AdvJobNo INT
) AS


SET NOCOUNT ON

DECLARE @PackageCode VARCHAR(255)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)

/*
DECLARE @AdvJobNo INT
SET @AdvJobNo = 78809
*/

IF OBJECT_ID('tempdb..#tmpDeliverable') IS NOT NULL
    DROP TABLE #tmpDeliverable

CREATE TABLE #tmpDeliverable
(
	Id VARCHAR(255),
	JobId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	Package_Code VARCHAR(255),
)

--/*
--STEP 1: Get all initial data
SET @LinkedServer = 'COMS_UATSB'
SET @OPENQUERY = 'SELECT *
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, SBQQ__Quote__r.Id, SBQQ__Quote__r.Advantage_Job_Code__c, CPQ_Package__c
	FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Advantage_Job_Code__c =' + CAST(@AdvJobNo AS VARCHAR(20)) + '  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL'')' 

--PRINT @OPENQUERY+@TSQL
INSERT #tmpDeliverable
EXEC (@OPENQUERY+@TSQL) 
--SELECT * FROM #tmpDeliverable
SELECT @AdvJobNo=Advantage_Job_Code__c, @PackageCode=Package_Code FROM #tmpDeliverable

IF OBJECT_ID('tempdb..#tmpPkgPhases') IS NOT NULL
    DROP TABLE #tmpPkgPhases

CREATE TABLE #tmpPkgPhases
(
	Id VARCHAR(255),
	Name VARCHAR(255),
	QuoteId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	CPQ_Package__c NVARCHAR(MAX),
	CPQ_Phase__c NVARCHAR(MAX),
	SBQQ__Description__c NVARCHAR(MAX),
	CPQ_Job_Specific_Name__c NVARCHAR(MAX),
	CPQ_Estimated_Quantity__c INT,
	CPQ_Mail_Ship_Date__c DATETIME,
	PackageQty INT,
)

--/*
--STEP 1: Get all initial data
SET @LinkedServer = 'COMS_UATSB'
SET @OPENQUERY = 'SELECT *, 0 PackageQty
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, CPQ_Package__c, CPQ_Phase__c, SBQQ__Description__c, CPQ_Job_Specific_Name__c, CPQ_Estimated_Quantity__c, CPQ_Mail_Ship_Date__c
	FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Advantage_Job_Code__c =' + CAST(@AdvJobNo AS VARCHAR(20)) 
	+ '  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL ' + ' '')' 

--PRINT @OPENQUERY+@TSQL
INSERT #tmpPkgPhases
EXEC (@OPENQUERY+@TSQL)
SELECT * FROM #tmpPkgPhases

--STEP 2: get/set pkg total
IF OBJECT_ID('tempdb..#tmpPkgTotal') IS NOT NULL
	DROP TABLE #tmpPkgTotal

SELECT B.Id, QuoteId, Advantage_Job_Code__c, Name, A.CPQ_Package__c, CPQ_Mail_Ship_Date__c, CPQ_Job_Specific_Name__c, SUM(CPQ_Estimated_Quantity__c) PackageQty
INTO #tmpPkgTotal
FROM #tmpPkgPhases A JOIN (SELECT A.Id, A.CPQ_Package__c, B.CPQ_Phase__c
	FROM #tmpPkgPhases A JOIN (SELECT CPQ_Package__c, MIN(CPQ_Phase__c) CPQ_Phase__c FROM #tmpPkgPhases GROUP BY CPQ_Package__c) B ON B.CPQ_Package__c=A.CPQ_Package__c
		AND B.CPQ_Phase__c=A.CPQ_Phase__c) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c
GROUP BY QuoteId, Advantage_Job_Code__c, Name, CPQ_Mail_Ship_Date__c, CPQ_Job_Specific_Name__c, A.CPQ_Package__c, B.Id
--SELECT * FROM #tmpPkgTotal

;
WITH src AS (SELECT * FROM #tmpPkgTotal)
MERGE INTO ProcessLog WITH (SERIALIZABLE) AS tgt
USING src ON tgt.Advantage_Job_Id  = src.Advantage_Job_Code__c AND tgt.Package_Code=src.CPQ_Package__c
WHEN MATCHED AND (Estimated_Qty<>src.PackageQty
		OR Mail_Date<>src.CPQ_Mail_Ship_Date__c
		--OR QuoteId<>src.QuoteId
		OR QuoteLine_ID<>src.Id
		OR QuoteLine_Name<>src.Name)
		THEN UPDATE
	SET Estimated_Qty=src.PackageQty
		,Mail_Date=src.CPQ_Mail_Ship_Date__c
		--,QuoteID=src.QuoteId
		,QuoteLine_ID=src.Id
		,QuoteLine_Name=src.Name
		,[LastModifiedDate]=GETDATE()	
WHEN NOT MATCHED THEN INSERT(QuoteID, Advantage_Job_ID, Job_Specific_Name, QuoteLine_ID, QuoteLine_Name, Package_Code, Estimated_Qty, Mail_Date)
VALUES(src.QuoteId, src.Advantage_Job_Code__c, src.CPQ_Job_Specific_Name__c, src.Id, src.Name, src.CPQ_Package__c, src.PackageQty, src.CPQ_Mail_Ship_Date__c)
;

