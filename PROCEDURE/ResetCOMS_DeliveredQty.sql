CREATE PROCEDURE [dbo].[ResetCOMS_DeliveredQty]
(
	@FileID INT
)
AS

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @UnapprovedCount INT
DECLARE @QuoteName VARCHAR(10), @DeliveredQty INT

--DECLARE @FileID INT
--SET @FileID = 24

SET @LinkedServer = 'COMS_UATSB'

--STEP 2: get all delivered qtys by QL
DECLARE db_cursor CURSOR FOR 
SELECT [dbo].udf_ConvertIDtoQuoteline(Parent_ID) QuoteLineID, COUNT(*) DeliveredQty
FROM ORIGINAL
WHERE FileID=@FileID
	AND COALESCE(child_id,'') =''
GROUP BY Parent_ID
UNION ALL
SELECT [dbo].udf_ConvertIDtoQuoteline(Child_ID), COUNT(*)
FROM ORIGINAL
WHERE FileID=@FileID
	AND COALESCE(child_id,'') >''
GROUP BY Child_ID


OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @QuoteName, @DeliveredQty

WHILE @@FETCH_STATUS = 0  
BEGIN
	--UPDATE COMS deliverable with actual qty
	SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
	SET @TSQL = 'SELECT Id, CPQ_Actual_Quantity__c
		FROM SBQQ__QuoteLine__c WHERE Name=''''' + @QuoteName + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' '')
		SET CPQ_Actual_Quantity__c=NULL;'
	EXEC (@OPENQUERY+@TSQL)

	FETCH NEXT FROM db_cursor INTO @QuoteName, @DeliveredQty
END

CLOSE db_cursor  
DEALLOCATE db_cursor

