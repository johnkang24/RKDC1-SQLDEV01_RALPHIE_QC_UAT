CREATE PROCEDURE [dbo].[GenerateLettershopFile]
(
	--@AdvJobNo VARCHAR(100),
	@FileID INT,
	@outputPath VARCHAR(500)
)
AS

BEGIN

	SET NOCOUNT ON;
	
	DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)

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

	SET @LinkedServer = 'COMS_UATSB'

	--TESTING
	--DECLARE @FileID INT, @outputPath VARCHAR(500)
	--SET @outputPath = '\\Rkdc1-SQLDEV01\tempdata\QC FILES\OUTPUT FILES\LETTERSHOP\ClientCode\FBLCO\2026_Production_Files\ReadyToUpload\'
	--SET @testing = 1
	--SET @FileID = 140
	
	DECLARE @is_acquisition BIT
	SELECT @is_acquisition=COALESCE(MAX(A.Is_Acquisition),0), @adv_job_id=B.Advantage_Job_ID
	FROM ProcessLog A 
			JOIN FileLog B ON B.FileID=A.FileID
	WHERE A.FileID=@FileID
		AND A.QC_Approved=1
		AND COALESCE(A.Lettershop_FileName,'')=''
	GROUP BY B.Advantage_Job_ID

	IF @testing=1 BEGIN
		PRINT @is_acquisition
		SELECT COALESCE(A.AudienceCode,'D'), B.Client_Code, A.Mail_Date, A.CreativeAbbreviated, A.Parent_ID
		FROM dbo.ProcessLog A 
			JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
		WHERE A.Is_Acquisition=@is_acquisition
	END
	
	DECLARE db_cursor CURSOR FOR 
	--SELECT A.AudienceCode, B.Client_Code, A.Mail_Date,A.CreativeName, A.Parent_ID
	--SELECT COALESCE(A.AudienceCode,'D'), B.Client_Code, A.Mail_Date, A.CreativeAbbreviated, A.Parent_ID, B.Advantage_Job_ID, A.Package_Code
	SELECT B.Client_Code, A.Mail_Date, A.CreativeAbbreviated, A.Parent_ID, B.Advantage_Job_ID, A.Package_Code
	FROM dbo.ProcessLog A 
		JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	WHERE A.Is_Acquisition=@is_acquisition

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @client_code, @mail_date, @creativecode, @parentID, @advantageJobNo, @packageCode

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		PRINT @mail_date

		--JCK:03.27.2026 - added to get distinct audience codes by package to be used in the file name	
		IF OBJECT_ID('tempdb..#tmpDeliverables') IS NOT NULL
			DROP TABLE #tmpDeliverables

		CREATE TABLE #tmpDeliverables
		(
			Id VARCHAR(255),
			Name VARCHAR(255),
			Advantage_Job_Code__c VARCHAR(255),
			SB_RKD_Audience__c NVARCHAR(MAX),
			SB_RKD_Audience_Code__c NVARCHAR(MAX),
			CPQ_Package__c NVARCHAR(MAX),
			CPQ_Phase__c NVARCHAR(MAX),
		)
		PRINT @adv_job_id
		SET @OPENQUERY = 'SELECT *
			FROM OPENQUERY('+ @LinkedServer + ','''
		SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__r.Advantage_Job_Code__c, SB_RKD_Audience__c, SB_RKD_Audience_Code__c, CPQ_Package__c, CPQ_Phase__c
			FROM SBQQ__QuoteLine__c 
			WHERE SBQQ__Quote__r.Advantage_Job_Code__c =' +  @adv_job_id +' AND SB_RKD_Audience__c!=''''Ship to Client'''' AND CPQ_Package__c  =''''' + @PackageCode + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL'')' 
		PRINT @OPENQUERY+@TSQL
		INSERT #tmpDeliverables
		EXEC (@OPENQUERY+@TSQL)

		IF @testing=1 begin
			SELECT * FROM #tmpDeliverables;
		END
		;
		WITH dedup AS (
			SELECT SB_RKD_Audience_Code__c,
					MIN(CPQ_Phase__c) AS first_order
			FROM #tmpDeliverables
			GROUP BY SB_RKD_Audience_Code__c
		)
		SELECT @audience_code=STRING_AGG(SB_RKD_Audience_Code__c, '')
				WITHIN GROUP (ORDER BY first_order)
		FROM dedup;
		IF @audience_code IS NULL AND (SELECT COUNT(*) FROM #tmpDeliverables)>0 BEGIN
			SET @audience_code = 'D'
		END

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

		FETCH NEXT FROM db_cursor INTO @client_code, @mail_date, @creativecode, @parentID, @advantageJobNo, @packageCode
	END

	CLOSE db_cursor  
	DEALLOCATE db_cursor
END

