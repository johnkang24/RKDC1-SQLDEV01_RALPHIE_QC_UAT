CREATE PROCEDURE [dbo].[GenerateLettershopFile]
(
	--@AdvJobNo VARCHAR(100),
	@FileID INT,
	@outputPath VARCHAR(500)
)
AS

BEGIN

	SET NOCOUNT ON;
	--DECLARE @dbName SYSNAME = 'RALPHIE_QC';
	--DECLARE @coms_db SYSNAME = '[COMS_UATSB]';

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @package_code VARCHAR(10);
	DECLARE @phase_code VARCHAR(10);
	DECLARE @mail_date DATE;
	DECLARE @quote_id VARCHAR(50);
	DECLARE @quoteline_id VARCHAR(50);
	DECLARE @file_id VARCHAR(50);
	DECLARE @adv_job_id VARCHAR(50);
	DECLARE @vertical VARCHAR(MAX);
	DECLARE @component_no VARCHAR(MAX);
	DECLARE @job_name VARCHAR(MAX);
	DECLARE @creativecode VARCHAR(50);
	DECLARE @test_control_cd VARCHAR(MAX);
	DECLARE @audience_code VARCHAR(MAX);
	DECLARE @audience_name VARCHAR(MAX);
	DECLARE @creativeAbbreviated VARCHAR(MAX);
	DECLARE @client_code VARCHAR(50);
	DECLARE @parentID VARCHAR(50)
	DECLARE @advantageJobNo VARCHAR(50)
	DECLARE @packageCode VARCHAR(50)
	DECLARE @outputFilename VARCHAR(500)

	DECLARE @testing BIT = 0

	--TESTING
	--DECLARE @FileID INT, @outputPath VARCHAR(500)
	--SET @outputPath = '\\Rkdc1-SQLDEV01\tempdata\QC FILES\OUTPUT FILES\LETTERSHOP\ClientCode\FBLCO\2026_Production_Files\ReadyToUpload\'
	--SET @testing = 0
	--SET @FileID = 88

	
	--DECLARE @fileID VARCHAR(50);
	--SELECT @fileID=FileID FROM FileLog WHERE Advantage_Job_ID=@AdvJobNo AND FileType='ORIGINAL'

	DECLARE @is_acquisition BIT
	SELECT @is_acquisition=COALESCE(MAX(Is_Acquisition),0)
	FROM ProcessLog
	WHERE FileID=@FileID
		AND QC_Approved=1
		AND COALESCE(Lettershop_FileName,'')=''

	IF @testing=1 BEGIN
		PRINT @is_acquisition
		SELECT COALESCE(A.AudienceCode,'D'), B.Client_Code, A.Mail_Date, A.CreativeAbbreviated, A.Parent_ID
		FROM dbo.ProcessLog A 
			JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
		WHERE A.Is_Acquisition=@is_acquisition
	END

	DECLARE db_cursor CURSOR FOR 
	--SELECT A.AudienceCode, B.Client_Code, A.Mail_Date,A.CreativeName, A.Parent_ID
	SELECT COALESCE(A.AudienceCode,'D'), B.Client_Code, A.Mail_Date, A.CreativeAbbreviated, A.Parent_ID, B.Advantage_Job_ID, A.Package_Code
	FROM dbo.ProcessLog A 
		JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	WHERE A.Is_Acquisition=@is_acquisition

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @audience_code, @client_code, @mail_date, @creativecode, @parentID, @advantageJobNo, @packageCode

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT @mail_date
		--JCK:03.25.2026 - changes to naming convention
		--SET @outputFilename = @outputPath+@audience_code+'_'+@client_code+'_'+SUBSTRING(CAST(@mail_date AS VARCHAR(10)),3,2)+'-'+FORMAT(@mail_date, 'MMM')+'_'+COALESCE(@creativecode,'')+'_'+@parentID+'.csv'
		SET @outputFilename = @outputPath+@audience_code+'_'+@client_code+'_'+SUBSTRING(CAST(@mail_date AS VARCHAR(10)),3,2)+'-'+FORMAT(@mail_date, 'MMM')+'_'+COALESCE(@creativecode,'')+'_'+@advantageJobNo+'_'+@packageCode+'.csv'
		PRINT @parentID
		PRINT @outputFilename

		IF @testing=1 BEGIN
			PRINT 'EXECUTE [GenerateLettershopFileByParentID]' + @parentID + ', ' + @outputFilename
		END ELSE BEGIN
			EXECUTE [GenerateLettershopFileByParentID] @parentID, @outputFilename
		END

		FETCH NEXT FROM db_cursor INTO @audience_code, @client_code, @mail_date, @creativecode, @parentID
	END

	CLOSE db_cursor  
	DEALLOCATE db_cursor
END

