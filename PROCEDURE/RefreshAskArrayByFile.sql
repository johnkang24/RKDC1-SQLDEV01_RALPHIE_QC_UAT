CREATE PROCEDURE [dbo].[RefreshAskArrayByFile]
(
	@file_id INT,
	@giftType INT = 0,
	@partial BIT=0,
	@status BIT=0 OUTPUT
)
AS

DECLARE @testing BIT=0

--TESTING!
--DECLARE @file_id INT,@giftType INT = 0, @status BIT=0, @partial bit=0
--SET @file_id = 80
--SET @giftType =1
--SET @status = 0
--SET @testing = 0

DECLARE @client_code VARCHAR(10), @fb0_GridDate date, @multiplier int, @asktablecode VARCHAR(50), @askrunid VARCHAR(50)
DECLARE @JobID VARCHAR(50)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)

SET @LinkedServer = 'COMS_UATSB'

BEGIN
	
	SELECT @askrunid=COALESCE(AskRunID,'')
	FROM FileLog
	WHERE FileID=@file_id

	--STEP 1: reset all values
	IF @partial=0 BEGIN
		UPDATE ORIGINAL
			SET ltramt=NULL
				,lg = NULL
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
				,lg = NULL
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
	SELECT @client_code=B.client_code, @asktablecode=AskTableCode, @fb0_GridDate=B.[LastGiftDate], @multiplier=Multiplier, @JobID=B.Advantage_Job_ID
	FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
	WHERE A.FileID=@file_id

	--STEP 3: get deliverable-level ask table codes from COMS
	IF OBJECT_ID('tempdb..#tmpDeliverables') IS NOT NULL
		DROP TABLE #tmpDeliverables

	CREATE TABLE #tmpDeliverables
	(
		LineID VARCHAR(255),
		SB_Ask_Array_Code__c VARCHAR(255),
	)

	--STEP 3: Get all package-phase data
	SET @OPENQUERY = 'SELECT CAST(REPLACE(Name,''QL-'','''') AS INT) LineID, SB_Ask_Array_Code__c
		FROM OPENQUERY('+ @LinkedServer + ','''
	SET @TSQL = 'SELECT Name, SB_Ask_Array_Code__c
			FROM SBQQ__QuoteLine__c 
			WHERE SBQQ__Quote__r.Advantage_Job_Code_Formula__c =''''' + @JobID + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL ' + ' '')' 

	INSERT #tmpDeliverables
	EXEC (@OPENQUERY+@TSQL)

	--STEP 4: get deliverable-level ask table codes from COMS
	IF OBJECT_ID('tempdb..#tmpSpecialCodes') IS NOT NULL
		DROP TABLE #tmpSpecialCodes

	CREATE TABLE #tmpSpecialCodes
	(
		LineID VARCHAR(255),
		SB_Ask_Array_Code__c VARCHAR(255),
		SpecialCodes VARCHAR(MAX),
	)
	
	INSERT #tmpSpecialCodes
	SELECT A.LineID, A.SB_Ask_Array_Code__c, STRING_AGG(AO.SpecialCode,',') SpecialCodes
	FROM #tmpDeliverables A
		JOIN AskArray.dbo.AskTable AT ON AT.AsktableCode=A.SB_Ask_Array_Code__c
		JOIN AskArray.dbo.AskOptions AO ON AO.AskTableId=AT.AskTableId AND AO.SpecialCode IS NOT NULL
	GROUP BY A.LineID, A.SB_Ask_Array_Code__c

	IF @testing=1 BEGIN
		SELECT * FROM #tmpDeliverables
		SELECT * FROM #tmpSpecialCodes
	END


	--STEP 5: get deliverable-level ask table codes from COMS
	SET @askrunid = @client_code+'_'+CAST(@file_id AS VARCHAR(10))+'_'+FORMAT(GETDATE(), 'yyyy-MM-dd_HH_mm_ss')
	--SET @askrunid = 'MWKWI_72_2026-03-02_13_03_15'

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
		  ,C.SB_Ask_Array_Code__c
		  ,Original_ID
	--      ,[ltramt]
	--      ,[misc7]
	--		,giftdate
		  --,CASE WHEN LEFT(rm,1)='U' THEN 999 ELSE datediff(month, CAST(giftdate AS DATE), @fb0_GridDate)-
		  ,CASE WHEN giftdate IS NULL THEN NULL ELSE datediff(month, CAST(giftdate AS DATE), @fb0_GridDate)-
				CASE WHEN DATEPART(day, CAST(giftdate AS DATE)) > DATEPART(day, @fb0_GridDate) THEN 1 ELSE 0 END 
		  END recency
		  --,CASE WHEN LEFT(rm,1)='U' THEN 0 
		  ,CASE WHEN LEN(COALESCE(misc7,''))<2 THEN NULL
			ELSE CASE WHEN @Vertical='Missions' AND CAST([last_giftamt] AS MONEY) > 0 AND SUBSTRING(misc7,2,1)='0' THEN 1 ELSE SUBSTRING(misc7,2,1) END
		  END frequency
		  ,CASE WHEN @Vertical='Missions' THEN 
			CASE WHEN CAST([last_giftamt] AS MONEY) < 0 THEN 0.00 ELSE ROUND(CAST([last_giftamt] AS MONEY),2) END
			ELSE ROUND(CAST([giftamt] AS MONEY),2) 
		  END monetary
		  ,Multiplier
		  ,CASE WHEN CHARINDEX([rm],COALESCE(S.SpecialCodes,''))>0 THEN [rm] ELSE dbo.[udf_TransformRM]([rm]) END rm
	FROM [ORIGINAL] A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
		JOIN #tmpDeliverables C ON C.LineID=CASE WHEN COALESCE(A.child_id,'')='' THEN A.parent_id ELSE A.child_id END
		LEFT JOIN #tmpSpecialCodes S ON S.LineID=CASE WHEN COALESCE(A.child_id,'')='' THEN A.parent_id ELSE A.child_id END
	WHERE A.FileID=@file_id
		AND AskOptionID IS NULL
		--JCK:12.04.2025 - skip when RKDOPEN table is set
		AND C.SB_Ask_Array_Code__c<>'RKDOPEN'
	ORDER BY rm

	--STEP 6: call the SP to generate the new ask values
	EXECUTE AskArray.dbo.ExecuteAskRuntime @askrunid

	DECLARE @error_total INT
	SELECT @error_total=COUNT(*)
	FROM AskArray.dbo.AskRuntime 
	WHERE AskRunId=@askrunid
		AND (COALESCE(Status,'')<>'Success' AND COALESCE(AskOptionID,0)<1 )

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

	--JCK:12.04.2025 - update for RKDOPEN table
	UPDATE A SET AskOptionID=0
	FROM [ORIGINAL] A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
		JOIN #tmpDeliverables C ON C.LineID=CASE WHEN COALESCE(A.child_id,'')='' THEN A.parent_id ELSE A.child_id END
	WHERE A.FileID=@file_id
		AND C.SB_Ask_Array_Code__c='RKDOPEN'

	--save last used askrunid
	UPDATE FileLog SET AskRunID=@askrunid
	WHERE FileID=@file_id

	--STEP 7: if no errors
	IF @error_total=0 BEGIN
		UPDATE ProcessLog SET AskArray_Processed=1
		WHERE FileID=@file_id

		SET @status = 1
	END ELSE BEGIN
		UPDATE P SET AskArray_Processed=0
		FROM ProcessLog P
		JOIN (SELECT A.parent_ID
		FROM ORIGINAL A 
			JOIN AskArray.dbo.AskRuntime B ON B.Id=A.Original_ID AND B.AskRunId=@askrunid
		WHERE A.FileID=@file_id
			AND B.AskOptionID IS NULL
		GROUP BY A.parent_ID) A ON A.parent_id=P.Parent_ID
		WHERE P.FileID=@file_id
	END
END

