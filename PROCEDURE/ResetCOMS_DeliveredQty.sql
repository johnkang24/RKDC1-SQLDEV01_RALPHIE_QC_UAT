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
FROM ORIGINAL A
	LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id
WHERE A.FileID=@FileID 
	AND (B.dupedrop IS NULL OR B.dupedrop<>'TRUE')
	AND ( B.error_code IS NULL OR B.error_code NOT IN (
	'-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220',
	'311','312','313','411','412','413','414','415','416','417','418','419','420','421',
	'422','423','491','492','493','494'
	))
	AND COALESCE(A.child_id,'') =''
GROUP BY Parent_ID
UNION ALL
SELECT [dbo].udf_ConvertIDtoQuoteline(Child_ID), COUNT(*)
FROM ORIGINAL A
	LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id
WHERE A.FileID=@FileID 
	AND (B.dupedrop IS NULL OR B.dupedrop<>'TRUE')
	AND ( B.error_code IS NULL OR B.error_code NOT IN (
	'-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220',
	'311','312','313','411','412','413','414','415','416','417','418','419','420','421',
	'422','423','491','492','493','494'
	))
	AND COALESCE(A.child_id,'') >''
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

