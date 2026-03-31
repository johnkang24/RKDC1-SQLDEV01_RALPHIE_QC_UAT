CREATE PROCEDURE [dbo].[LoadSourceFile_V1]
(
	@FileToLoad VARCHAR(255),
	@ParentFileID INT=0,
	@Acquisition BIT=0,
	@FileID INT OUTPUT
)
AS

--TESTING
--DECLARE @FileToLoad VARCHAR(255), @ParentFileID INT, @FileID INT, @Acquisition BIT=0
--SET @FileToLoad = '\\rkdc1-sqldev01\tempdata\RALPHIE\staging\FoodBank\2601\SHMTNNOV25NDAN\Output\SHMTNNOV25NDAN_COMS_ORIGINAL.CSV'
--SET @ParentFileID = 0

DECLARE @SQL VARCHAR(1000)
DECLARE @FileExists AS INT = 0
DECLARE @LoadMessage VARCHAR(255)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @FileNamePath VARCHAR(MAX), @FileType VARCHAR(100), @TotalCount INT, @AdvJobNo VARCHAR(50), @Parent_ID VARCHAR(50),  @Vertical VARCHAR(100), @Client_code VARCHAR(50), @AccountID VARCHAR(50)
DECLARE @AccountName VARCHAR(MAX), @ScheduleBlockName VARCHAR(MAX)
DECLARE @QuoteLineID VARCHAR(16), @JustFileName VARCHAR(MAX)
DECLARE @SourceQCFolder VARCHAR(200)
SET @SourceQCFolder = '\\Rkdc1-sqldev01\tempdata\QC FILES'
DECLARE @SourceQCDirectory SYSNAME = @SourceQCFolder
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

	SELECT @FileID=FileID, @FileNamePath=FileNamePath
	FROM FileLog
	WHERE FileNamePath=@FileToLoad
		AND FileLoaded=0

	IF CHARINDEX('original', @FileNamePath)>0 BEGIN
		SET @FileType = 'ORIGINAL'
	END ELSE IF CHARINDEX('ncoa', @FileNamePath)>0 BEGIN
		SET @FileType = 'NCOA'
	END ELSE IF CHARINDEX('reject', @FileNamePath)>0 BEGIN
		SET @FileType = 'REJECT'
	END ELSE BEGIN
		SET @FileType = ''
	END

	PRINT @FileID
	PRINT @FileNamePath
	PRINT @FileType
	PRINT @ParentFileID
	PRINT @Acquisition

	BEGIN TRY
		IF @Acquisition=1 BEGIN
			SELECT 'stp_CommaBulkInsert_acquisition @FileID, @FileNamePath, ''ORIGINAL_ACQUSITION'', @ParentFileID'
			EXECUTE stp_CommaBulkInsert_acquisition @FileID, @FileNamePath, 'ORIGINAL_ACQUSITION', @ParentFileID
		END ELSE BEGIN
			SELECT 'stp_CommaBulkInsert ' + STR(@FileID) + ' ' + @FileNamePath + ' ' + @FileType + ' ' + STR(@ParentFileID)
			EXECUTE stp_CommaBulkInsert @FileID, @FileNamePath, @FileType, @ParentFileID
		END

		IF @FileType='NCOA' BEGIN
			SELECT TOP 1 @Client_code=area, @TotalCount=COUNT(*) FROM NCOA WHERE FileID=@FileID GROUP BY area
			--get values from parent file ID
			SELECT @AdvJobNo=Advantage_Job_ID, @Vertical=Vertical FROM FileLog WHERE FileID=@ParentFileID
		END ELSE IF @FileType='REJECT' BEGIN
			SELECT @TotalCount=COUNT(*) FROM REJECT WHERE FileID=@FileID
		END ELSE BEGIN
			SELECT TOP 1 @Parent_ID=MIN(parent_id), @Client_code=client_code, @TotalCount=COUNT(*) FROM ORIGINAL WHERE FileID=@FileID GROUP BY client_code
			SELECT @Parent_ID, @Client_code, @TotalCount

			--JCK:11.03.2025 - added at the end
			--BEGIN TRY
			--	PRINT 'Calling Sync_ProcessLog '+CAST(@FileID AS VARCHAR(10))
			--	--add/update ProcessLog table with parent_id
			--	EXECUTE Sync_ProcessLog @FileID
			--END TRY
			--BEGIN CATCH
			--	PRINT ERROR_MESSAGE()
			--END CATCH

			--get vertical
			IF OBJECT_ID('tempdb..#tmpVertical') IS NOT NULL
				DROP TABLE #tmpVertical

			CREATE TABLE #tmpVertical
			(
				AccountID VARCHAR(255),
				AccountName VARCHAR(MAX),
				Advantage_Job_Code__c VARCHAR(255),
				Vertical VARCHAR(255),
				ScheduleBlock_Name VARCHAR(MAX)
			)
			SET @LinkedServer = 'COMS_UATSB'
			--SET @QuoteLineID = 'QL-'+RIGHT('0000000'+CAST(@Parent_ID AS VARCHAR(20)),7)
			SET @QuoteLineID = [dbo].[udf_ConvertIDtoQuoteline](@Parent_ID)
			SET @OPENQUERY = 'SELECT *
				FROM OPENQUERY('+ @LinkedServer + ','''
			--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
			SET @TSQL = 'SELECT SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.SBQQ__Account__r.Name, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.SBQQ__Account__r.SB_Vertical__c, SBQQ__Quote__r.SB_Schedule_Block__r.Name
				FROM SBQQ__QuoteLine__c WHERE Name=''''' + @QuoteLineID + '''''  '')' 	
			PRINT @OPENQUERY+@TSQL
			INSERT #tmpVertical
			EXEC (@OPENQUERY+@TSQL)
			SELECT * FROM #tmpVertical
			SELECT @AccountID=AccountID, @AccountName=AccountName, @AdvJobNo=Advantage_Job_Code__c, @Vertical=Vertical, @ScheduleBlockName=ScheduleBlock_Name 
			FROM #tmpVertical
			PRINT '@AccountID='+@AccountID
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
UPDATE [dbo].[FileLog] 
	SET FileType=@FileType, Last_Message=@LoadMessage, [FileLoaded]=CASE WHEN LEFT(@LoadMessage,5)='ERROR' THEN 0 ELSE 1 END
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
	BEGIN TRY
		PRINT 'Calling Sync_ProcessLog '+CAST(@FileID AS VARCHAR(10))
		--add/update ProcessLog table with parent_id
		EXECUTE Sync_ProcessLog @FileID
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH
END
