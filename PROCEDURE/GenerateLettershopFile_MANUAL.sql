CREATE PROCEDURE [dbo].[GenerateLettershopFile_MANUAL]
(
	@FileID INT,
	@outputfiles BIT=1,
	@testing BIT = 0,
	@rerunText VARCHAR(10) = ''
)
AS

DECLARE @errors INT, @askRunID VARCHAR(100)
DECLARE @fileName VARCHAR(MAX), @folder VARCHAR(MAX), @vertical VARCHAR(100)
DECLARE @parentID VARCHAR(100)

--TESTING
--DECLARE @FileID INT,@testing BIT = 0,@rerunText VARCHAR(10) = 'V5'
--SET @FileID = 72
--SET @testing = 1

SELECT @askRunID=AskRunID FROM FileLog WHERE FileID=@FileID

IF @testing=0 BEGIN
	EXEC [dbo].[RefreshAskArrayByFile] @FileID, 0, 0
END

SELECT @errors=COUNT(*) FROM ORIGINAL 
WHERE FileID=@FileID AND AskOptionID IS NULL

PRINT @errors
IF @errors = 0 AND @outputfiles=1 BEGIN
	SELECT @vertical=Vertical FROM FileLog WHERE FileID=@FileID

	--STEP 1: get destination folder from previous run
	--SET @folder = '\\Rkdc1-SQLDEV01\tempdata\QC FILES\OUTPUT FILES\LETTERSHOP\ClientCode\WAYMO\2026_Production_Files\ReadyToUpload'
	SELECT TOP 1 @folder=SUBSTRING(Lettershop_FileName, 
            1, CHARINDEX('ReadyToUpload\', Lettershop_FileName)+12)
	FROM ProcessLog WHERE FileID=@FileID

	--STEP 2: get each file we need to create/recreate
	DECLARE db_cursor CURSOR FOR 
	SELECT Parent_ID, SUBSTRING(Lettershop_FileName, 
            CHARINDEX('ReadyToUpload\', Lettershop_FileName)+14,100) AS FileName
	FROM dbo.ProcessLog
	WHERE FileID=@FileID

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @parentID, @fileName

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		IF @rerunText>'' BEGIN
			SET @fileName = @folder + '\' + REPLACE(@fileName,'.csv','_'+@rerunText+'.csv')
		END ELSE BEGIN
			SET @fileName = @folder + '\' + @fileName
		END

		IF @vertical='Missions' BEGIN
			IF @testing=1 BEGIN
				SELECT 'EXEC [dbo].[GenerateLettershopFileByParentID_Missions] ' + @parentID + ', ' +@fileName
			END ELSE BEGIN
				EXEC [dbo].[GenerateLettershopFileByParentID_Missions] @parentID, @fileName
			END
		END ELSE BEGIN
			IF @testing=1 BEGIN
				SELECT 'EXEC [dbo].[GenerateLettershopFileByParentID] ' + @parentID + ', ' +@fileName
			END ELSE BEGIN
				EXEC [dbo].[GenerateLettershopFileByParentID] @parentID, @fileName
			END
		END

		FETCH NEXT FROM db_cursor INTO @parentID, @fileName
	END

	CLOSE db_cursor  
	DEALLOCATE db_cursor
END ELSE BEGIN
	SELECT * 
	FROM ORIGINAL A JOIN AskArray.dbo.AskRuntime B ON B.Id=A.Original_ID
		AND B.AskRunId=@askRunID
	WHERE FileID=@FileID AND A.AskOptionID IS NULL
	ORDER BY B.Recency
END

SELECT * FROM FileLog WHERE FileID=@FileID
SELECT * FROM ProcessLog WHERE FileID=@FileID

