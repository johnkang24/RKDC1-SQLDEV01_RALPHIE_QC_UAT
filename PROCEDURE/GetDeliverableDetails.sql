CREATE PROCEDURE GetDeliverableDetails
(
	@DeliverableID INT
) AS

SET NOCOUNT ON

DECLARE @QuoteLineID VARCHAR(16), @PackageCode VARCHAR(255), @AdvJobNo INT, @JobID VARCHAR(18)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @testing BIT = 0

--TESTING
--DECLARE @DeliverableID INT
--SET @DeliverableID = 163009
--SET @testing=1

SET @QuoteLineID = [dbo].udf_ConvertIDtoQuoteline(@DeliverableID)

SELECT @JobID=A.QuoteID, @AdvJobNo=B.Advantage_Job_ID, @PackageCode=Package_Code
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
WHERE Parent_ID=@DeliverableID
PRINT @JobID

IF OBJECT_ID('tempdb..#tmpDeliverables') IS NOT NULL
    DROP TABLE #tmpDeliverables

CREATE TABLE #tmpDeliverables
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

IF COALESCE(@JobID,'')>'' BEGIN
	--Get all package data
	SET @LinkedServer = 'COMS_UATSB'
	SET @OPENQUERY = 'SELECT *
		FROM OPENQUERY('+ @LinkedServer + ','''
	SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.Job_Name__c, SB_Creative_Name__r.Name, SB_RKD_Audience__c, CPQ_Package__c, CPQ_Phase__c, SBQQ__Description__c, CPQ_Job_Specific_Name__c, CPQ_Estimated_Quantity__c, CPQ_Mail_Ship_Date__c, SB_Material_Vendor__r.Name, CPQ_Lettershop_Vendor__r.Name
		FROM SBQQ__QuoteLine__c 
		WHERE SBQQ__Quote__c =''''' +  @JobID +''''' AND CPQ_Package__c  =''''' + @PackageCode + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL'')' 
	PRINT @OPENQUERY+@TSQL
	INSERT #tmpDeliverables
	EXEC (@OPENQUERY+@TSQL)
END

SELECT *, [dbo].[udf_ConvertQuotelineToId](Name) DeliverableID
FROM #tmpDeliverables


