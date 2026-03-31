CREATE PROCEDURE [dbo].[GenerateNCOADropFile]
(
	--@AdvanJobNum VARCHAR(100),
	@fileID VARCHAR(100),
	@outputPath VARCHAR(500) = NULL
)
AS

DECLARE @testing BIT = 0

----TESTING
--DECLARE @AdvanJobNum INT
--SET @AdvanJobNum = 91090
--DECLARE @outputPath VARCHAR(MAX), @fileID VARCHAR(100)
--SET @fileID = 60
--SET @outputPath = '\\rkdc1-sqldev01\tempdata\QC FILES\OUTPUT FILES\NCOA\2025 Data\'
--SET @testing = 1

BEGIN

	SET NOCOUNT ON;

	DECLARE @is_acquisition BIT
	SELECT @is_acquisition=MAX(Is_Acquisition)
	FROM ProcessLog
	WHERE FileID=@fileID
		AND QC_Approved=1
		AND Is_Acquisition=0
	PRINT @is_acquisition

	IF @is_acquisition=0 BEGIN
		DECLARE @dbName SYSNAME = DB_NAME();
		DECLARE @sql NVARCHAR(MAX);
		DECLARE @file_name VARCHAR(MAX)
		DECLARE @ncoa_filename VARCHAR(MAX)
		DECLARE @ncoa_error_filename VARCHAR(MAX)
		DECLARE @bcpCommand VARCHAR(8000);

		--SELECT @fileID=FileID FROM FileLog WHERE Advantage_Job_ID=@AdvanJobNum AND FileType='ORIGINAL'
		--PRINT @fileID

		IF @outputPath IS NULL
			SET @outputPath = '\\RKDC1-SQLDEV01\TempData\RALPHIE\staging\READY TO QC\OUTPUT FILES\NCOA'

		DECLARE @parent_ids VARCHAR(MAX);
		DECLARE @client_codes VARCHAR(MAX);
		DECLARE @mailmnths VARCHAR(MAX);
		DECLARE @mailpkg VARCHAR(MAX);

		---------------------------------------------------------------------------------------------------------------
		-- NCOA file
		---------------------------------------------------------------------------------------------------------------
		SELECT
			@parent_ids = STRING_AGG(sub.parent_id, '-'),
			@client_codes = COALESCE(MAX(sub.client_code),''),
			@mailmnths = COALESCE(MAX(sub.mailmnth),''),
			@mailpkg = COALESCE(MAX(sub.mailpkg),'')
		FROM (
			SELECT DISTINCT TOP 10000 B.parent_id, B.client_code, B.mailmnth, B.mailpkg
			FROM [dbo].[NCOA] A 
				JOIN [dbo].[ORIGINAL] B ON B.FileID = A.ParentFileID AND B.id = A.id
			WHERE B.FileID IN (SELECT FileID FROM FileLog WHERE Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID))  --B.FileID = @fileID 
			  AND mv_forward IN ('A','91','92','19')
			ORDER BY B.parent_id
		) AS sub;

		SET @file_name = @client_codes + '_' + @mailmnths + '_'+@mailpkg+'_NCOA'+'_'+ @parent_ids
		SET @ncoa_filename = @outputPath + '\' + @file_name + '.csv'
		PRINT @file_name
		SELECT @ncoa_filename

		--STEP 1: setup temp table to store the data to be outputted
		SET @sql = '
		IF OBJECT_ID(''' + @dbName + '.dbo.NCOADropExportStaging'', ''U'') IS NOT NULL
			DROP TABLE [' + @dbName + '].dbo.NCOADropExportStaging;';
		EXEC sp_executesql @sql;

		SET @sql = '
		CREATE TABLE [' + @dbName + '].dbo.NCOADropExportStaging (
			client_id VARCHAR(50),
			donor_id VARCHAR(50),
			company VARCHAR(200),
			addressee1 VARCHAR(200),
			addressee2 VARCHAR(200),
			address1 VARCHAR(200),
			address2 VARCHAR(200),
			city VARCHAR(100),
			state VARCHAR(50),
			zip VARCHAR(20),
			mv_forward VARCHAR(100),
			mv_effdate VARCHAR(100),
			recommendation VARCHAR(100),
			new_address_1 VARCHAR(200),
			new_address_2 VARCHAR(200),
			new_city VARCHAR(100),
			new_state VARCHAR(500),
			new_zip VARCHAR(200)
		);';
		EXEC sp_executesql @sql;

		-- Add column headers
		SET @sql = '
		INSERT INTO [' + @dbName + '].dbo.NCOADropExportStaging
		SELECT 
		''client_id'', ''donor_id'', ''company'', ''addressee1'', ''addressee2'', ''address1'', ''address2'', ''city'', ''state'', ''zip'', ''mv_forward'', ''mv_effdate'', ''recommendation'', ''new_address_1'', ''new_address_2'', ''new_city'',	''new_state'', ''new_zip'';
		';
		EXEC sp_executesql @sql;

		--STEP 2: fetch data and store into another temp table
		Set @sql='SELECT * INTO #ncoa FROM OPENROWSET(''SQLNCLI'', ''Server='+@@SERVERNAME+';Trusted_Connection=yes;DATABASE='+@dbName+';'',
		 ''EXEC GetNCOAChangesByFileID @fileID = ' + CAST(@fileID AS VARCHAR) + '''); '

		--STEP 3: add fetched data to first temp table
		SET @sql = @sql + '
		INSERT INTO [' + @dbName + '].dbo.NCOADropExportStaging (
		client_id, donor_id, company, addressee1, addressee2, address1, address2, city, state, zip, mv_forward, mv_effdate, recommendation, new_address_1, new_address_2, new_city,	new_state, new_zip
		)
		SELECT client_id, donor_id, company, addressee1, addressee2, address1, address2, city, state, zip, mv_forward, mv_effdate, ''''+recommendation+'''', new_address_1, new_address_2, new_city,	new_state, new_zip
		FROM #ncoa;';
		print @sql
		EXEC sp_executesql @sql;

		IF @testing=1 BEGIN
			SELECT * FROM NCOADropExportStaging
		END

		--STEP 4: ouput the data to a file
		SET @bcpCommand = 
			'bcp "SELECT * FROM [' + @dbName + '].dbo.NCOADropExportStaging" queryout "' 
			+ @ncoa_filename + '" -c -t, -T -S ' + @@SERVERNAME;
		PRINT @bcpCommand
		EXEC xp_cmdshell @bcpCommand;

		SET @sql = 'DROP TABLE [' + @dbName + '].dbo.NCOADropExportStaging;';
		EXEC sp_executesql @sql;
	
		---------------------------------------------------------------------------------------------------------------
		-- NCOA_ERROR file
		---------------------------------------------------------------------------------------------------------------
		SELECT
			@parent_ids = STRING_AGG(sub.parent_id, '-'),
			@client_codes = MAX(sub.client_code),
			@mailmnths = MAX(sub.mailmnth),
			@mailpkg = MAX(sub.mailpkg)
		FROM (
			SELECT DISTINCT TOP 1000000 B.parent_id, B.client_code, B.mailmnth, B.mailpkg
			FROM [dbo].[NCOA] A 
			JOIN [dbo].[ORIGINAL] B ON B.FileID = A.ParentFileID AND B.id = A.id
			WHERE B.FileID IN (SELECT FileID FROM FileLog WHERE Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID))  --B.FileID = @fileID 
			  AND A.error_code IN (
				'-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220',
				'311','312','313','411','412','413','414','415','416','417','418','419','420','421',
				'422','423','491','492','493','494'
			  )
			ORDER BY B.parent_id
		) AS sub
		ORDER BY MAX(parent_id);

		SET @file_name = @client_codes + '_' + COALESCE(@mailmnths,'') + '_'+COALESCE(@mailpkg,'')+'_NCOA_error_'+ @parent_ids
		SET @ncoa_error_filename = @outputPath + '\' + @file_name + '.csv'

		IF @testing=1 BEGIN
			print @parent_ids
			print @client_codes
			print @mailmnths
			print @file_name
			print @ncoa_error_filename
		END

		--STEP 1: setup temp table to store the data to be outputted
		SET @sql = '
		IF OBJECT_ID(''' + @dbName + '.dbo.NCOADropExportStaging'', ''U'') IS NOT NULL
			DROP TABLE [' + @dbName + '].dbo.NCOADropExportStaging;';
		EXEC sp_executesql @sql;

		SET @sql = '
		CREATE TABLE [' + @dbName + '].dbo.NCOADropExportStaging (
			client_id VARCHAR(50),
			donor_id VARCHAR(50),
			company VARCHAR(200),
			addressee1 VARCHAR(200),
			addressee2 VARCHAR(200),
			address1 VARCHAR(200),
			address2 VARCHAR(200),
			city VARCHAR(100),
			state VARCHAR(50),
			zip VARCHAR(20),
			error_code VARCHAR(200),
			error_description VARCHAR(255)
		);';
		EXEC sp_executesql @sql;

		-- Add column headers
		SET @sql = '
		INSERT INTO [' + @dbName + '].dbo.NCOADropExportStaging
		SELECT 
		''client_id'', ''donor_id'', ''company'', ''addressee1'', ''addressee2'', ''address1'', ''address2'', ''city'', ''state'', ''zip'', ''error_code'', ''error_description'';
		';
		EXEC sp_executesql @sql;

		--STEP 2: fetch data and store into another temp table
		Set @sql='SELECT * INTO #ncoa_errors FROM OPENROWSET(''SQLNCLI'', ''Server='+@@SERVERNAME+';Trusted_Connection=yes;DATABASE='+@dbName+';'',
		 ''EXEC GetNCOADropByFileID @fileID = ' + CAST(@fileID AS VARCHAR) + '''); '

		--STEP 3: add fetched data to first temp table
		SET @sql = @sql + '
		INSERT INTO [' + @dbName + '].dbo.NCOADropExportStaging (
		client_id, donor_id, company, addressee1, addressee2, address1, address2, city, state, zip, error_code, error_description
		)
		SELECT client_id, donor_id, company, addressee1, addressee2, address1, address2, city, state, zip, error_code, error_description
		FROM #ncoa_errors;';
		print @sql
		EXEC sp_executesql @sql;

		--STEP 4: ouput the data to a file
		SET @bcpCommand = 
			'bcp "SELECT * FROM [' + @dbName + '].dbo.NCOADropExportStaging" queryout "' 
			+ @ncoa_error_filename + '" -c -t, -T -S ' + @@SERVERNAME;
		PRINT @bcpCommand
		IF @testing=1 BEGIN
			PRINT 'xp_cmdshell '+@bcpCommand;
		END ELSE BEGIN
			EXEC xp_cmdshell @bcpCommand;
		END

		SET @sql = 'DROP TABLE [' + @dbName + '].dbo.NCOADropExportStaging;';
		EXEC sp_executesql @sql;

		IF @testing=1 BEGIN
			PRINT '@ncoa_filename='+@ncoa_filename
			PRINT '@ncoa_error_filename='+@ncoa_error_filename
		END ELSE BEGIN
			--STEP 5: finally, save the generated full path and file name
			UPDATE FileLog SET NCOA_FileName=@ncoa_filename, NCOA_Error_FileName=@ncoa_error_filename
			--WHERE FileID=@fileID
			WHERE FileID IN (SELECT FileID FROM FileLog WHERE Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID))
		END
	END
END

