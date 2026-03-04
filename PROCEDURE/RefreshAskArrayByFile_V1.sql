CREATE PROCEDURE [dbo].[RefreshAskArrayByFile_V1]
(
	@file_id INT,
	@giftType INT = 0,
	@partial BIT=0,
	@status BIT=0 OUTPUT
)
AS

DECLARE @testing BIT=0

--TESTING!
--DECLARE @file_id INT,@giftType INT = 0, @status BIT=0
--SET @file_id = 39
--SET @giftType =1
--SET @status = 0
--SET @testing = 1

DECLARE @client_code VARCHAR(10), @fb0_GridDate date, @multiplier int, @asktablecode VARCHAR(50), @askrunid VARCHAR(50)

BEGIN
	
	SELECT @askrunid=COALESCE(AskRunID,'')
	FROM FileLog
	WHERE FileID=@file_id

	--STEP 1: reset all values
	IF @partial=0 BEGIN
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
				,AskOptionID = NULL
		WHERE FileID=@file_id
			--AND AskOptionID IS NULL
	END ELSE BEGIN
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
				,AskOptionID = NULL
		WHERE FileID=@file_id
			AND COALESCE(AskOptionID,0)=0
	END

	IF @testing=1 BEGIN
		SELECT * FROM ORIGINAL
		WHERE FileID=@file_id
			AND AskOptionID IS NULL
	END

	UPDATE ProcessLog SET AskArray_Processed=0
	WHERE FileID=@file_id

	--STEP 2: copy records into the AskRuntime table to be processed
	SELECT @client_code=B.client_code, @asktablecode=AskTableCode, @fb0_GridDate=B.[LastGiftDate], @multiplier=Multiplier
	FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
	WHERE A.FileID=@file_id

	SET @askrunid = @client_code+'_'+CAST(@file_id AS VARCHAR(10))+'_'+FORMAT(GETDATE(), 'yyyy-MM-dd_HH_mm_ss')

	--these will need to come from COMS
	--SET @asktablecode = 'RKDSTD'
	--SET @fb0_GridDate = '2025-04-17'
	--SET @multiplier = 5

	DECLARE @Vertical VARCHAR(50)
	SELECT @Vertical=Vertical
	FROM FileLog
	WHERE FileID=@file_id

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
		  ,AskTableCode
		  ,Original_ID
	--      ,[ltramt]
	--      ,[misc7]
	--		,giftdate
		  ,CASE WHEN LEFT(rm,1)='U' THEN 999 ELSE datediff(month, CAST(giftdate AS DATE), @fb0_GridDate)-
					CASE WHEN DATEPART(day, CAST(giftdate AS DATE)) > DATEPART(day, @fb0_GridDate) THEN 1 ELSE 0 END END recency
		  ,CASE WHEN LEFT(rm,1)='U' THEN 0 ELSE SUBSTRING(misc7,2,1) END frequency
		  --,ROUND([giftamt],2) monetary
		  --,CASE WHEN @giftType=1 THEN ROUND([last_giftamt],2) ELSE ROUND([giftamt],2) END monetary
		  ,CASE WHEN @Vertical='Missions' THEN ROUND([last_giftamt],2) ELSE ROUND([giftamt],2) END monetary
		  ,Multiplier
		  ,[rm]
	FROM [ORIGINAL] A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
	WHERE A.FileID=@file_id
		AND AskOptionID IS NULL
		--JCK:12.04.2025 - skip when RKDOPEN table is set
		AND AsktableCode<>'RKDOPEN'
	ORDER BY rm

	--JCK:12.04.2025 - update for RKDOPEN table
	UPDATE A SET AskOptionID=0
	FROM [ORIGINAL] A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
	WHERE A.FileID=@file_id
		--AND AskOptionID IS NULL
		AND AsktableCode='RKDOPEN'

	--STEP 3: call the SP to generate the new ask values
	EXECUTE AskArray.dbo.ExecuteAskRuntime @askrunid

	DECLARE @error_total INT
	SELECT @error_total=COUNT(*)
	FROM AskArray.dbo.AskRuntime 
	WHERE AskRunId=@askrunid
		AND (Status<>'Success' AND COALESCE(AskOptionID,0)<1 )

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
			,AskOptionID = B.AskOptionID
	FROM ORIGINAL A JOIN AskArray.dbo.AskRuntime B ON B.Id=A.Original_ID AND B.AskRunId=@askrunid
	WHERE A.FileID=@file_id

	--save last used askrunid
	UPDATE FileLog SET AskRunID=@askrunid
	WHERE FileID=@file_id

	--STEP 4: if no errors
	IF @error_total=0 BEGIN
		UPDATE ProcessLog SET AskArray_Processed=1
		WHERE FileID=@file_id

		SET @status = 1
	END
END

