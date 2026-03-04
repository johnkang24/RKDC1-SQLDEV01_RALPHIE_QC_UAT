CREATE PROCEDURE [dbo].[Ralphie_LogQCFiles]
AS

DECLARE @SQL VARCHAR(1000)
DECLARE @FileExists AS INT = 0
DECLARE @SourceQCFolder VARCHAR(200)
SET @SourceQCFolder = '\\Rkdc1-sqldev01\tempdata\RALPHIE\staging\READY TO QC'
DECLARE @SourceQCDirectory SYSNAME = @SourceQCFolder
DECLARE @LoadMessage VARCHAR(255)

BEGIN
--STEP 1: look for new files
  IF OBJECT_ID('tempdb..#DirTree') IS NOT NULL
    DROP TABLE #DirTree

  CREATE TABLE #DirTree (
    Id int identity(1,1),
    SubDirectory nvarchar(255),
    Depth smallint,
    FileFlag bit,
    ParentDirectoryID int
   )

   INSERT INTO #DirTree (SubDirectory, Depth, FileFlag)
   EXEC master..xp_dirtree @SourceQCDirectory, 1, 1

   SELECT * FROM #DirTree

   UPDATE #DirTree
   SET ParentDirectoryID = (
    SELECT MAX(Id) FROM #DirTree d2
    WHERE Depth = d.Depth - 1 AND d2.Id < d.Id
   )
   FROM #DirTree d

  DECLARE 
    @ID INT,
    @SourceQCFile VARCHAR(MAX),
    @Depth TINYINT,
    @FileFlag BIT,
    @ParentDirectoryID INT,
    @wkSubParentDirectoryID INT,
    @wkSubDirectory VARCHAR(MAX)

  DECLARE @SourceQCFiles TABLE
  (
    FileNamePath VARCHAR(MAX),
    TransLogFlag BIT,
    BackupFile VARCHAR(MAX),    
    DatabaseName VARCHAR(MAX)
  )

  DECLARE FileCursor CURSOR LOCAL FORWARD_ONLY FOR
  SELECT * FROM #DirTree WHERE FileFlag = 1

  OPEN FileCursor
  FETCH NEXT FROM FileCursor INTO 
    @ID,
    @SourceQCFile,
    @Depth,
    @FileFlag,
    @ParentDirectoryID  

  SET @wkSubParentDirectoryID = @ParentDirectoryID

  WHILE @@FETCH_STATUS = 0
  BEGIN
	/* ignore subdirectories for now
	--loop to generate path in reverse, starting with backup file then prefixing subfolders in a loop
	WHILE @wkSubParentDirectoryID IS NOT NULL
	BEGIN
		SELECT @wkSubDirectory = SubDirectory, @wkSubParentDirectoryID = ParentDirectoryID 
		FROM #DirTree 
		WHERE ID = @wkSubParentDirectoryID

		SELECT @SourceQCFile = @wkSubDirectory + '\' + @SourceQCFile
	END
    --no more subfolders in loop so now prefix the root backup folder
	*/

    SELECT @SourceQCFile = @SourceQCDirectory + '\' + @SourceQCFile

    --put backupfile into a table and then later work out which ones are log and full backups  
    INSERT INTO @SourceQCFiles (FileNamePath) VALUES(@SourceQCFile)

    FETCH NEXT FROM FileCursor INTO 
      @ID,
      @SourceQCFile,
      @Depth,
      @FileFlag,
      @ParentDirectoryID 

    SET @wkSubParentDirectoryID = @ParentDirectoryID      
  END

  CLOSE FileCursor
  DEALLOCATE FileCursor
  ;
  WITH src AS (SELECT * FROM @SourceQCFiles)
	MERGE INTO FileLog WITH (SERIALIZABLE) AS tgt
	USING src ON tgt.FileNamePath  = src.FileNamePath
	WHEN MATCHED THEN UPDATE
	SET FileLoaded=0
		,[LastModifiedDate]=GETDATE()
	WHEN NOT MATCHED THEN INSERT(FileNamePath)
	VALUES(src.FileNamePath)
   ;

   --update values from Ralphie DB
	UPDATE A SET fb0_recordID=A.fb0_recordID, AdvantageJobNumber=C.fb1_column02
	FROM FileLog A JOIN RALPHIE_COMS.[dbo].[fb0_Jobs] B ON B.fb0_client=A.Client_Code AND B.fb0_SchemaName=A.SchemaName
		JOIN [RALPHIE_COMS].[dbo].[fb1_SpreadsheetInterface] C ON C.fb1_fb0recordid=B.fb0_recordID AND C.[fb1_column01] LIKE 'Advantage%'
		JOIN @SourceQCFiles D ON D.FileNamePath=A.FileNamePath

--	STEP 2: load each file	
   DECLARE @FileID INT, @FileNamePath VARCHAR(MAX), @FileType VARCHAR(100), @TotalCount INT
   	DECLARE db_cursor CURSOR FOR 
	SELECT FileID, FileNamePath, FileType
	FROM FileLog
	WHERE FileLoaded=0

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @FileID, @FileNamePath, @FileType

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		SELECT @FileExists=1 FROM @SourceQCFiles WHERE FileNamePath=@FileNamePath
		IF ( @FileExists = 1 ) BEGIN

			BEGIN TRY
				EXECUTE stp_CommaBulkInsert @FileID, @FileNamePath, @FileType

				SET @TotalCount = 0
				IF @FileType='POSNCOA' BEGIN
					SELECT @TotalCount=COUNT(*) FROM POSNCOA WHERE FileID=@FileID
				END ELSE IF @FileType='REJECT' BEGIN
					SELECT @TotalCount=COUNT(*) FROM REJECT WHERE FileID=@FileID
				END ELSE BEGIN
					SELECT @TotalCount=COUNT(*) FROM POSORIGINAL WHERE FileID=@FileID;
					--add/update ProcessLog table with parent_id
					--EXECUTE Sync_PorcessLog @FileID
					/*
					  WITH src AS (SELECT parent_ID FROM POSORIGINAL WHERE FileID=@FileID)
						MERGE INTO ProcessLog WITH (SERIALIZABLE) AS tgt
						USING src ON tgt.Parent_ID  = src.Parent_ID
						WHEN MATCHED THEN UPDATE
						SET --Status='Pending'
							[LastModifiedDate]=GETDATE()
						WHEN NOT MATCHED THEN INSERT(Parent_ID)
						VALUES(src.Parent_ID)
					   ;
					*/
				END

				--if there are matching records flag as being loaded
				--PRINT @TotalCount
				IF @TotalCount > 0 BEGIN
					SET @SQL = 'MOVE "' + @FileNamePath + '" "' + @SourceQCFolder+'\PROCESSED\'+reverse(left(reverse(@FileNamePath),charindex('\',reverse(@FileNamePath))-1)) + '"'
					EXECUTE xp_cmdshell  @SQL 

					--update the log record
					UPDATE [dbo].[FileLog] SET [FileLoaded]=1, TotalCount=@TotalCount WHERE FileID=@FileID
					SET @LoadMessage = ''
				END ELSE BEGIN
					SET @LoadMessage = 'No records found'
				END
			END TRY
			BEGIN CATCH
				SET @LoadMessage = ERROR_MESSAGE()
			END CATCH
	
			--update the status message
			UPDATE [dbo].[FileLog] SET Last_Message=@LoadMessage WHERE FileID=@FileID

		END ELSE BEGIN
			--update the log record
			UPDATE [dbo].[FileLog] SET Last_Message='File not found' WHERE FileID=@FileID
		END

		FETCH NEXT FROM db_cursor INTO @FileID, @FileNamePath, @FileType
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor

END
