CREATE PROCEDURE [dbo].[LoadSourceFile]
(
	@FileToLoad VARCHAR(255),
	@ParentFileID INT=0,
	@Acquisition BIT=0,
	@FileIDs VARCHAR(100) OUTPUT
)
AS

--TESTING
--DECLARE @FileToLoad VARCHAR(255), @ParentFileID INT, @Acquisition BIT=0, @FileIDs VARCHAR(100)
--SET @FileToLoad = '\\rkdc1-sqldev01\tempdata\RALPHIE\staging\Holliston\2605\XCPFBMay26TEST\Output\XCPFBMay26TEST_COMS_ORIGINAL.CSV'
--SET @ParentFileID = 0

DECLARE @FileID INT
DECLARE @SQL VARCHAR(1000)
DECLARE @FileExists AS INT = 0
DECLARE @LoadMessage VARCHAR(255)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @FileNamePath VARCHAR(MAX), @FileType VARCHAR(100), @TotalCount INT, @AdvJobNo VARCHAR(50), @AdvJobNo2 VARCHAR(50), @Parent_ID VARCHAR(50),  @Vertical VARCHAR(100), @Client_code VARCHAR(50), @AccountID VARCHAR(50), @Name VARCHAR(MAX), @Legacy_Client_Code__c VARCHAR(MAX)
DECLARE @AccountName VARCHAR(MAX), @ScheduleBlockName VARCHAR(MAX)
DECLARE @QuoteLineID VARCHAR(MAX), @JustFileName VARCHAR(MAX)
DECLARE @SourceQCFolder VARCHAR(200)
SET @SourceQCFolder = '\\Rkdc1-sqldev01\tempdata\QC FILES'
DECLARE @SourceQCDirectory SYSNAME = @SourceQCFolder
DECLARE @primaryFileID INT, @counter INT = 1
SET @AdvJobNo = ''
SET @AccountID = ''
SET @Parent_ID = @ParentFileID
SET @Vertical = ''
SET @Client_code = ''
SET @LoadMessage = ''
SET @TotalCount = 0

SELECT @FileExists=dbo.fn_FileExists(@FileToLoad)
PRINT @FileExists

IF ( @FileExists = 1 ) BEGIN
  ;
  WITH src AS (SELECT @FileToLoad FileNamePath)
	MERGE INTO FileLog WITH (SERIALIZABLE) AS tgt
	USING src ON tgt.FileNamePath  = src.FileNamePath
	WHEN MATCHED THEN UPDATE
	SET FileLoaded=0
		,[LastModifiedDate]=GETDATE()
	WHEN NOT MATCHED THEN INSERT(FileNamePath)
	VALUES(src.FileNamePath)
   ;

	/*
	--03.24.2025 - remove reliance on Ralphie to get details but pull from COMS instead during ORIGINAL file Sync_ProcessLog call
	--update values from Ralphie DB
	UPDATE A SET fb0_recordID=A.fb0_recordID, AdvantageJobNumber=C.fb1_column02
	FROM FileLog A JOIN RALPHIE_COMS.[dbo].[fb0_Jobs] B ON B.fb0_client=A.Client_Code AND B.fb0_SchemaName=A.SchemaName
		JOIN [RALPHIE_COMS].[dbo].[fb1_SpreadsheetInterface] C ON C.fb1_fb0recordid=B.fb0_recordID AND C.[fb1_column01] LIKE 'Advantage%'
	WHERE A.FileNamePath=@FileToLoad
	*/

	SELECT @FileID=MIN(FileID), @FileNamePath=FileNamePath
	FROM FileLog
	WHERE FileNamePath=@FileToLoad
		AND FileLoaded=0
	GROUP BY FileNamePath
	SELECT @FileID

	IF CHARINDEX('original', @FileNamePath)>0 BEGIN
		SET @FileType = 'ORIGINAL'
	END ELSE IF CHARINDEX('ncoa', @FileNamePath)>0 BEGIN
		SET @FileType = 'NCOA'
	END ELSE IF CHARINDEX('reject', @FileNamePath)>0 BEGIN
		SET @FileType = 'REJECT'
	END ELSE BEGIN
		SET @FileType = ''
	END

	SET @FileIDs = STR(@FileID)
	PRINT @FileID
	PRINT @FileNamePath
	PRINT @FileType
	PRINT @ParentFileID
	PRINT @Acquisition

	BEGIN TRY
		IF @Acquisition=1 BEGIN
			SELECT 'stp_CommaBulkInsert_acquisition ' + STR(@FileID) + ' ' + @FileNamePath + ' ' +  'ORIGINAL_ACQUSITION' + ' ' + STR(@ParentFileID)
			EXECUTE stp_CommaBulkInsert_acquisition @FileID, @FileNamePath, 'ORIGINAL_ACQUSITION', @ParentFileID
		END ELSE BEGIN
			SELECT 'stp_CommaBulkInsert ' + STR(@FileID) + ' ' + @FileNamePath + ' ' + @FileType + ' ' + STR(@ParentFileID)
			EXECUTE stp_CommaBulkInsert @FileID, @FileNamePath, @FileType, @ParentFileID
		END

		IF @FileType='NCOA' BEGIN
			--SELECT TOP 1 @Client_code=area, @TotalCount=COUNT(*) FROM NCOA WHERE FileID=@FileID GROUP BY area
			SELECT @TotalCount=COUNT(*) FROM NCOA WHERE FileID=@FileID
			--get values from parent file ID
			SELECT @AdvJobNo=Advantage_Job_ID, @Vertical=Vertical FROM FileLog WHERE FileID=@ParentFileID
		END ELSE IF @FileType='REJECT' BEGIN
			SELECT @TotalCount=COUNT(*) FROM REJECT WHERE FileID=@FileID
		END ELSE BEGIN
			--get vertical
			IF OBJECT_ID('tempdb..#tmpVertical') IS NOT NULL
				DROP TABLE #tmpVertical

			CREATE TABLE #tmpVertical
			(
				AccountID VARCHAR(255),
				AccountName VARCHAR(MAX),
				Advantage_Job_Code__c VARCHAR(255),
				Vertical VARCHAR(255),
				ScheduleBlock_Name VARCHAR(MAX),
				Legacy_Client_Code__c VARCHAR(MAX),
				Name VARCHAR(MAX),
			)
			SET @LinkedServer = 'COMS_UATSB'
			--JCK:03.31.2026 - added to check for multi-jobs in single ORIGINAL file
			--SET @QuoteLineID = [dbo].[udf_ConvertIDtoQuoteline](@Parent_ID)
			SELECT @QuoteLineID = STRING_AGG([dbo].[udf_ConvertIDtoQuoteline](parent_id),''''',''''')
			FROM (SELECT DISTINCT parent_id
				FROM ORIGINAL
				WHERE FileID=@FileID) A

			SET @OPENQUERY = 'SELECT SBQQ__Quote__r_SBQQ__Account__c, SBQQ__Quote__r_SBQQ__Account__r_Name, SBQQ__Quote__r_Advantage_Job_Code__c, SBQQ__Quote__r_SBQQ__Account__r_SB_Vertical__c, SBQQ__Quote__r_SB_Schedule_Block__r_Name, SBQQ__Quote__r_SBQQ__Account__r_Legacy_Client_Code__c, STRING_AGG(Name, '','')
				FROM OPENQUERY('+ @LinkedServer + ','''
			SET @TSQL = 'SELECT SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.Name, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.SBQQ__Account__r.SB_Vertical__c, SBQQ__Quote__r.SB_Schedule_Block__r.Name, Name, SBQQ__Quote__r.SBQQ__Account__r.Legacy_Client_Code__c
				FROM SBQQ__QuoteLine__c WHERE Name IN (''''' + @QuoteLineID + ''''')  '')
				GROUP BY SBQQ__Quote__r_SBQQ__Account__c, SBQQ__Quote__r_SBQQ__Account__r_Name, SBQQ__Quote__r_Advantage_Job_Code__c, SBQQ__Quote__r_SBQQ__Account__r_SB_Vertical__c, SBQQ__Quote__r_SB_Schedule_Block__r_Name, SBQQ__Quote__r_SBQQ__Account__r_Legacy_Client_Code__c
				ORDER BY SBQQ__Quote__r_Advantage_Job_Code__c'
			PRINT @OPENQUERY+@TSQL
			INSERT #tmpVertical
			EXEC (@OPENQUERY+@TSQL)
			SELECT * FROM #tmpVertical
			SELECT TOP 1 @AccountID=AccountID, @AccountName=AccountName, @AdvJobNo=Advantage_Job_Code__c, @Vertical=Vertical, @ScheduleBlockName=ScheduleBlock_Name, @Name=Name
			FROM #tmpVertical
			PRINT '@AccountID='+@AccountID

			--get total from the file 
			SELECT TOP 1 @Parent_ID=MIN(parent_id), @TotalCount=COUNT(*) 
			FROM ORIGINAL 
			WHERE FileID=@FileID 
				--AND parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,','))
			--GROUP BY client_code
			SELECT @Parent_ID, @Client_code, @TotalCount
		END

		--if there are matching records flag as being loaded
		PRINT '@TotalCount='+CAST(@TotalCount AS VARCHAR(50))
		IF @TotalCount > 0 BEGIN
			SET @JustFileName = REPLACE(reverse(left(reverse(@FileNamePath),charindex('\',reverse(@FileNamePath))-1)),'.','_'+convert(varchar(30), getdate(),112) + 
					replace(convert(varchar(30), getdate(),108),':','')+'.')
			SET @SQL = 'COPY "' + @FileNamePath + '" "' + @SourceQCFolder+'\PROCESSED\' + @JustFileName + '"'
			EXECUTE xp_cmdshell  @SQL 
			SET @LoadMessage = 'Successfully loaded ' + CAST(@TotalCount AS VARCHAR(50)) + ' records'

			--create a event log
			INSERT INTO FileLoadLog (FileID, SourceFile, DestinationFile) VALUES
				(@FileID, @FileNamePath, @JustFileName)
		END ELSE BEGIN
			SET @LoadMessage = 'ERROR: No records found'
		END
	END TRY
	BEGIN CATCH
		SET @LoadMessage = ERROR_MESSAGE()
		PRINT @LoadMessage
		SET @SQL = 'COPY "' + @FileNamePath + '" "' + @SourceQCFolder+'\UNPROCESSED\' + @JustFileName + '"'
		PRINT @SQL
		EXECUTE xp_cmdshell  @SQL 

		--create a event log
		INSERT INTO FileLoadLog (FileID, SourceFile, DestinationFile) VALUES
			(@FileID, @FileNamePath, @SourceQCFolder+'\UNPROCESSED\' + @FileNamePath)
	END CATCH
END ELSE BEGIN
	SET @LoadMessage = 'ERROR: File not found'
END

--update the status in the file log record
PRINT @LoadMessage
--SELECT @LoadMessage
--SELECT * FROM FileLog WHERE FileID=@FileID
UPDATE [dbo].[FileLog] 
	SET FileType=@FileType, Last_Message=@LoadMessage, FileLoaded=CASE WHEN LEFT(@LoadMessage,5)='ERROR' THEN 0 ELSE 1 END
		,Advantage_Job_ID=@AdvJobNo, Vertical=@Vertical
		,Client_Code=@Client_code, TotalCount=@TotalCount 
		,AccountId=@AccountID
		,Client_Name=@AccountName
		,ScheduleBlock_Name=@ScheduleBlockName
		--reset in case of reload
		,Lettershop_FileName=NULL
		,AppealTracking_FileName=NULL
		,NCOA_FileName=NULL
		,NCOA_Error_FileName=NULL
		,MergeDupe_FileName=NULL
		,PromoHarvester_FileName=NULL
WHERE FileID=@FileID

--JCK:11.03.2025 - not sure why this has to be added at the end but FileID gets set to 0 otherwise really strange
IF @FileType='ORIGINAL' BEGIN
	SET @primaryFileID = @FileID

	DECLARE db_cursor CURSOR FOR
	SELECT AccountID, AccountName, Advantage_Job_Code__c, Vertical, ScheduleBlock_Name, Legacy_Client_Code__c, Name
	FROM #tmpVertical
	--ORDER BY Advantage_Job_Code__c

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @AccountID, @AccountName, @AdvJobNo2, @Vertical, @ScheduleBlockName, @Legacy_Client_Code__c, @Name

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		--new job within the same file
		IF @AdvJobNo = @AdvJobNo2 BEGIN
				--SELECT @TotalCount=COUNT(*) 
				--FROM ORIGINAL 
				--WHERE FileID=@primaryFileID 
				--	AND  parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,','))
				--UPDATE FileLog SET TotalCount=@TotalCount WHERE FileID=@primaryFileID
				UPDATE FileLog SET Client_Code=@Legacy_Client_Code__c, FileLoaded=CASE WHEN LEFT(@LoadMessage,5)='ERROR' THEN 0 ELSE 1 END
					, TotalCount=(SELECT COUNT(*) 
						FROM ORIGINAL 
						WHERE FileID=@FileID 
							AND  parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,',')))
				WHERE FileNamePath=@FileNamePath AND Advantage_Job_ID=@AdvJobNo2 AND FileType=@FileType
		END ELSE BEGIN
			--SELECT 'SELECT 1 FROM FileLog WHERE FileNamePath='+@FileNamePath+' AND Advantage_Job_ID='+@AdvJobNo+' AND FileType='+@FileType
			IF NOT EXISTS(SELECT 1 FROM FileLog WHERE FileNamePath=@FileNamePath AND Advantage_Job_ID=@AdvJobNo2 AND FileType=@FileType) BEGIN
				PRINT 'Creating new FileLog record from original...'
				SELECT TOP 1 @Client_code=client_code, @TotalCount=COUNT(*) 
				FROM ORIGINAL 
				WHERE FileID=@primaryFileID 
					AND  parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,','))
				GROUP BY client_code
				SELECT @Parent_ID, @Client_code, @TotalCount
			
				INSERT FileLog (FileNamePath, FileLoaded, LastModifiedDate, FileType, Last_Message, AccountId, Advantage_Job_ID, Vertical, Client_Code, Client_Name, TotalCount, ScheduleBlock_Name)
				SELECT FileNamePath, FileLoaded, LastModifiedDate, FileType, LoadMessage=@LoadMessage, AccountID=@AccountID, AdvJobNo=@AdvJobNo2, 
					Vertical=@Vertical, Client_code=@Legacy_Client_Code__c, AccountName=@AccountName, TotalCount=@TotalCount, ScheduleBlock_Name=@ScheduleBlockName
				FROM FileLog
				WHERE FileID=@primaryFileID

				SELECT @FileID=SCOPE_IDENTITY();
			END ELSE BEGIN
				PRINT '@FileID='+CAST(@FileID AS VARCHAR(100))
				PRINT '@Legacy_Client_Code__c='+@Legacy_Client_Code__c
				UPDATE FileLog SET Client_Code=@Legacy_Client_Code__c, FileLoaded=CASE WHEN LEFT(@LoadMessage,5)='ERROR' THEN 0 ELSE 1 END
					, TotalCount=(SELECT COUNT(*) 
						FROM ORIGINAL 
						WHERE FileID=@primaryFileID 
							AND  parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,',')))
				WHERE FileNamePath=@FileNamePath AND Advantage_Job_ID=@AdvJobNo2 AND FileType=@FileType
				SELECT @FileID=FileID FROM FileLog WHERE FileNamePath=@FileNamePath AND Advantage_Job_ID=@AdvJobNo2 AND FileType=@FileType
			END

			--set new FileID for matching data in ORIGINAL
			UPDATE ORIGINAL SET FileID=@FileID
			WHERE FileID=@primaryFileID
				AND parent_id IN (SELECT dbo.udf_ConvertQuotelineToId(value) FROM STRING_SPLIT(@Name,','))

			SET @FileIDs = @FileIDs + ';' + STR(@FileID)
		END

		BEGIN TRY
			PRINT 'Calling Sync_ProcessLog '+CAST(@FileID AS VARCHAR(10))
			--add/update ProcessLog table with parent_id
			EXECUTE Sync_ProcessLog @FileID
		END TRY
		BEGIN CATCH
			PRINT ERROR_MESSAGE()
		END CATCH

		FETCH NEXT FROM db_cursor INTO @AccountID, @AccountName, @AdvJobNo2, @Vertical, @ScheduleBlockName, @Legacy_Client_Code__c, @Name
		SET @counter = @counter + 1
	END

	CLOSE db_cursor  
	DEALLOCATE db_cursor
END

--SELECT @FileIDs
