CREATE PROCEDURE [dbo].[RefreshAskArray]
(
	@parent_id INT
)
AS

DECLARE @client_code VARCHAR(10), @fb0_GridDate date, @multiplier int, @asktablecode VARCHAR(50), @askrunid VARCHAR(50)

--STEP 1: reset all values
UPDATE ORIGINAL
	SET ltramt=NULL
		,ug1 = NULL
		,ug2 = NULL
		,ug3 = NULL
		,ug4 = NULL
		,ug5 = NULL
		,ug6 = NULL
		,m1 = NULL
		,m2 = NULL
		,m3 = NULL
		,m4 = NULL
		,m5 = NULL
		,m6 = NULL
WHERE parent_id=@parent_id

--STEP 2: copy records into the AskRuntime table to be processed
SELECT @client_code=B.client_code, @asktablecode=AskTableCode, @fb0_GridDate=B.[LastGiftDate], @multiplier=Multiplier
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
WHERE A.Parent_ID=@parent_id

SET @askrunid = @client_code+'_'+CAST(@parent_id AS VARCHAR(10))+'_'+FORMAT(GETDATE(), 'yyyy-MM-dd_HH_mm_ss')

--these will need to come from COMS
--SET @asktablecode = 'RKDSTD'
--SET @fb0_GridDate = '2025-04-17'
--SET @multiplier = 5

INSERT AskArray.dbo.AskRuntime
([AskRunId]
      ,[ClientCode]
      ,[AskTableCode]
      ,[Id]
      ,[Recency]
      ,[Frequency]
      ,[Monetary]
      ,[Multiplier]
      ,[SpecialCode]
)
SELECT @askrunid AskRunId
      ,[client_code]
	  ,@asktablecode AskTableCode
      ,Original_ID
--      ,[ltramt]
--      ,[misc7]
--		,giftdate
	  ,CASE WHEN LEFT(rm,1)='U' THEN 999 ELSE datediff(month, CAST(giftdate AS DATE), @fb0_GridDate)-
				CASE WHEN DATEPART(day, CAST(giftdate AS DATE)) > DATEPART(day, @fb0_GridDate) THEN 1 ELSE 0 END END recency
	  ,CASE WHEN LEFT(rm,1)='U' THEN 0 ELSE SUBSTRING(misc7,2,1) END frequency
      ,ROUND([giftamt],2) monetary
	  ,@multiplier multiplier
      ,[rm]
FROM [ORIGINAL]
WHERE parent_id=@parent_id
ORDER BY rm

--STEP 3: call the SP to generate the new ask values
EXECUTE AskArray.dbo.ExecuteAskRuntime_v1 @askrunid

DECLARE @error_total INT
SELECT @error_total=COUNT(*)
FROM AskArray.dbo.AskRuntime 
WHERE AskRunId=@askrunid
	AND (Status<>'Success' AND COALESCE(AskOptionID,0)<1 )

--STEP 4: if no errors (batch) load new values
IF @error_total=0 BEGIN
	UPDATE A
		SET ltramt=B.LetterAmt
			,lg = B.Ask1
			,ug1 = B.Ask2
			,ug2 = B.Ask3
			,ug3 = B.Ask4
			,ug4 = B.Ask5
			,ug5 = B.Ask6
			,mg = B.M1
			,m1 = B.M2
			,m2 = B.M3
			,m3 = B.M4
			,m4 = B.M5
			,m5 = B.M6
	FROM ORIGINAL A JOIN AskArray.dbo.AskRuntime B ON B.Id=A.id AND B.AskRunId=@askrunid
	WHERE A.parent_id=@parent_id
END

