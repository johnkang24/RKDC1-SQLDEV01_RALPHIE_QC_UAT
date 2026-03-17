
CREATE PROCEDURE [dbo].[GetDeliverablesByParentID]
(
	@Parent_ID VARCHAR(50)
)
AS

SET NOCOUNT ON


DECLARE @testing BIT = 0

--TESTING
--DECLARE @Parent_ID INT
--SET @Parent_ID = '163009'
--SET @testing = 1

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @AdvJobNo INT, @QuoteID VARCHAR(50)

--STEP 1: fetch Adv Job # to use to pull detail data from COMS
SELECT @AdvJobNo=B.Advantage_Job_ID, @QuoteID=QuoteID
	FROM ProcessLog A JOIN Filelog B ON B.FileID=A.FileID
	WHERE Parent_ID=CAST(@Parent_ID AS INT)

IF OBJECT_ID('tempdb..#tmpPkgPhases') IS NOT NULL
    DROP TABLE #tmpPkgPhases

CREATE TABLE #tmpPkgPhases
(
	Id VARCHAR(255),
	Name VARCHAR(255),
	QuoteId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	Job_Name__c VARCHAR(MAX),
	SB_Creative_Name NVARCHAR(MAX),
	SB_RKD_Audience__c NVARCHAR(MAX),
	CPQ_Package__c NVARCHAR(MAX),
	CPQ_Phase__c NVARCHAR(MAX),
	SBQQ__Description__c NVARCHAR(MAX),
	CPQ_Job_Specific_Name__c NVARCHAR(MAX),
	CPQ_Estimated_Quantity__c INT,
	CPQ_Mail_Ship_Date__c DATETIME,
	Material_Vendor NVARCHAR(MAX),
	Lettershop_Vendor NVARCHAR(MAX),
)

IF COALESCE(@AdvJobNo,'')>'' BEGIN
	--/*
	--STEP 1: Get all initial data
	SET @LinkedServer = 'COMS_UATSB'
	SET @OPENQUERY = 'SELECT *
		FROM OPENQUERY('+ @LinkedServer + ','''
	--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
	SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.Job_Name__c, SB_Creative_Name__r.Name, SB_RKD_Audience__c, CPQ_Package__c, CPQ_Phase__c, SBQQ__Description__c, CPQ_Job_Specific_Name__c, CPQ_Estimated_Quantity__c, CPQ_Mail_Ship_Date__c, SB_Material_Vendor__r.Name, CPQ_Lettershop_Vendor__r.Name
		FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Advantage_Job_Code__c =' + CAST(@AdvJobNo AS VARCHAR(20)) 
		+ '  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL ' + ' '')' 

	PRINT @OPENQUERY+@TSQL
	INSERT #tmpPkgPhases
	EXEC (@OPENQUERY+@TSQL)
	IF @testing=1 BEGIN
		SELECT * FROM #tmpPkgPhases ORDER BY CPQ_Package__c, CPQ_Phase__c
	END

	SELECT C.Advantage_Job_ID, A.*, B.Job_Name__c, B.SB_Creative_Name, B.SB_RKD_Audience__c, B.Name, B.CPQ_Job_Specific_Name__c, B.CPQ_Package__c, B.CPQ_Phase__c
		,CPQ_Estimated_Quantity__c, CPQ_Mail_Ship_Date__c
		,CASE WHEN A.Phase_Code<>B.CPQ_Phase__c OR A.QC_File IS NULL THEN NULL ELSE A.QC_Approved END AS QC_Approved
		,CASE WHEN A.Phase_Code<>B.CPQ_Phase__c OR A.QC_File IS NULL THEN '' ELSE A.QC_File END AS QC_File
		,CASE WHEN A.Phase_Code<>B.CPQ_Phase__c OR A.QC_File IS NULL THEN NULL ELSE A.CreatedDate END AS CreatedDate
		,CASE WHEN A.Phase_Code<>B.CPQ_Phase__c OR A.QC_File IS NULL THEN NULL ELSE A.Data_Loader END AS Data_Loader
		,CASE WHEN A.Phase_Code<>B.CPQ_Phase__c OR A.QC_File IS NULL THEN '' ELSE A.Lettershop_FileName END AS Lettershop_FileName
		,CASE WHEN A.Package_Code=B.CPQ_Package__c AND A.Phase_Code=B.CPQ_Phase__c THEN 1 ELSE 0 END IsParent
		,B.Material_Vendor
		,B.Lettershop_Vendor
	FROM ProcessLog A LEFT JOIN #tmpPkgPhases B ON B.CPQ_Package__c=A.Package_Code
		LEFT JOIN Filelog C ON C.FileID=A.FileID AND C.Advantage_Job_ID=@AdvJobNo
	WHERE A.QuoteID=@QuoteID
	ORDER BY B.CPQ_Package__c, B.CPQ_Phase__c 
END ELSE BEGIN
	SELECT * FROM #tmpPkgPhases
END
