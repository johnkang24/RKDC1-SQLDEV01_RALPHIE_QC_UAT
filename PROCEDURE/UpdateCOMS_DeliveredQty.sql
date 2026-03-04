CREATE PROCEDURE [dbo].[UpdateCOMS_DeliveredQty]
(
	@FileID INT
)
AS

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @UnapprovedCount INT
DECLARE @QuoteName VARCHAR(10), @DeliveredQty INT
DECLARE @testing BIT = 0

--TESTING
--DECLARE @FileID INT
--SET @FileID = 70
--SET @testing = 1

SET @LinkedServer = 'COMS_UATSB'

DECLARE @is_acquisition BIT
SELECT @is_acquisition=MAX(Is_Acquisition)
FROM ProcessLog
WHERE FileID=@FileID

--STEP 1: confirm all QC packages are approved
SELECT @UnapprovedCount=COUNT(*)
FROM ProcessLog
WHERE QuoteID = (SELECT DISTINCT QuoteID FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID))
	AND QC_Approved<>1
	AND Is_Acquisition=@is_acquisition

IF @UnapprovedCount > 0 BEGIN
	PRINT '@UnapprovedCount='+CAST(@UnapprovedCount AS VARCHAR(10))
	RETURN
END

IF @testing=1 BEGIN
	SELECT '@UnapprovedCount', @UnapprovedCount
END

--STEP 2: get all delivered qtys by QL
DECLARE db_cursor CURSOR FOR 
--SELECT [dbo].udf_ConvertIDtoQuoteline(A.Parent_ID) QuoteLineID, COUNT(*) DeliveredQty
SELECT [dbo].udf_ConvertIDtoQuoteline(A.Parent_ID) QuoteLineID, C.Delivered_Qty
FROM ORIGINAL A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	JOIN ProcessLog C ON C.FileID=B.FileID AND C.Is_Acquisition=@is_acquisition
WHERE COALESCE(child_id,'') =''
GROUP BY A.Parent_ID, C.Delivered_Qty
UNION ALL
--SELECT [dbo].udf_ConvertIDtoQuoteline(Child_ID), COUNT(*)
SELECT [dbo].udf_ConvertIDtoQuoteline(Child_ID), C.Delivered_Qty
FROM ORIGINAL A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	JOIN ProcessLog C ON C.FileID=B.FileID AND C.Is_Acquisition=@is_acquisition
WHERE COALESCE(child_id,'') >''
GROUP BY Child_ID, C.Delivered_Qty

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @QuoteName, @DeliveredQty

WHILE @@FETCH_STATUS = 0  
BEGIN
	--UPDATE COMS deliverable with actual qty
	SET @OPENQUERY = 'UPDATE OPENQUERY('+ @LinkedServer + ','''
	SET @TSQL = 'SELECT Id, CPQ_Actual_Quantity__c
		FROM SBQQ__QuoteLine__c WHERE Name=''''' + @QuoteName + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' '')
		SET CPQ_Actual_Quantity__c='+CAST(@DeliveredQty AS VARCHAR(10)) + ';'

	IF @testing=1 BEGIN
		SELECT @OPENQUERY+@TSQL
	END ELSE BEGIN
		EXEC (@OPENQUERY+@TSQL)
	END

	FETCH NEXT FROM db_cursor INTO @QuoteName, @DeliveredQty
END

CLOSE db_cursor  
DEALLOCATE db_cursor

