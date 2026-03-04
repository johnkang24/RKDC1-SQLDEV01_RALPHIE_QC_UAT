CREATE PROCEDURE [dbo].[Refresh_SourceVersionControl]
AS
BEGIN
	DECLARE @bcpString NVARCHAR(900)
	DECLARE @bcpOutFile	NVARCHAR(max)
	DECLARE @shellresult INT
	DECLARE @routine_type NVARCHAR(255)	
	DECLARE @proc_name NVARCHAR(255)
	DECLARE @proc_code NVARCHAR(max)
	DECLARE @proc_lastaltered DATETIME
	DECLARE @db_name NVARCHAR(255)

	--TEST5 version control

	IF OBJECT_ID('tempdb..##tmpStoredProc') IS NOT NULL 
		DROP TABLE ##tmpStoredProc

	CREATE TABLE ##tmpStoredProc
	(
		ROUTINE_DEFINITION VARCHAR(MAX),
	)

	--STEP 1: pull just those that have been changed since last run
	DECLARE db_cursor CURSOR FOR
	SELECT A.ROUTINE_TYPE, A.ROUTINE_NAME, C.definition --A.ROUTINE_DEFINITION
		, A.LAST_ALTERED, B.DB_NAME
	FROM INFORMATION_SCHEMA.ROUTINES A 
		LEFT JOIN Integration.dbo.DB_SP_LOG B ON B.DB_NAME=DB_NAME() AND B.[ROUTINE_NAME]=A.ROUTINE_NAME AND B.ROUTINE_TYPE=A.ROUTINE_TYPE
		JOIN sys.sql_modules C ON C.object_id=OBJECT_ID(A.ROUTINE_NAME)
	WHERE A.ROUTINE_TYPE IN ('PROCEDURE','FUNCTION')
		AND (B.[LAST_ALTERED]<>A.LAST_ALTERED OR B.DB_NAME IS NULL)

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @routine_type, @proc_name, @proc_code, @proc_lastaltered, @db_name

	WHILE @@FETCH_STATUS = 0  
	BEGIN

		SET @bcpOutFile  = '\\rkdc1-sqldev01\TempData\SOURCECODE\RKDC1-SQLDEV01_RALPHIE_QC_UAT\' + @routine_type + '\' + @proc_name + '.sql'

		TRUNCATE TABLE ##tmpStoredProc
		INSERT ##tmpStoredProc (ROUTINE_DEFINITION) VALUES (@proc_code)

		/* not sure why this isn't working making me use temp table
		set @SelectString = 'SELECT TOP 1 ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE=''''PROCEDURE'''' AND SPECIFIC_NAME=''''' + @proc_name + ''''''
		set @bcpOutFile  = '\\rkdc1-sqldev01\TempData\SOURCECODE\' + @proc_name + '.sql'
		set @bcpString = 'bcp "' + rtrim(@SelectString) + ' " queryout "'  + @bcpOutFile + '" -c -T -t,'
		select @bcpString
		EXECUTE @shellresult = xp_cmdshell @bcpString
		*/

		SET @bcpString = 'bcp "SELECT ROUTINE_DEFINITION FROM ##tmpStoredProc" queryout "'  + @bcpOutFile + '" -c -T -t,'
		select @bcpString
		EXECUTE @shellresult = xp_cmdshell @bcpString

		IF @db_name > '' BEGIN
			--update log with same last altered date
			UPDATE A SET LAST_ALTERED=B.LAST_ALTERED
			FROM Integration.dbo.DB_SP_LOG A JOIN INFORMATION_SCHEMA.ROUTINES B  ON B.[ROUTINE_NAME]=A.ROUTINE_NAME AND B.ROUTINE_TYPE=A.ROUTINE_TYPE
			WHERE A.DB_NAME=DB_NAME()
		END ELSE BEGIN
			INSERT Integration.dbo.DB_SP_LOG ([DB_NAME], ROUTINE_TYPE, ROUTINE_NAME, LAST_ALTERED)
			VALUES (DB_NAME(), @routine_type, @proc_name, @proc_lastaltered)
		END	

		FETCH NEXT FROM db_cursor INTO @routine_type, @proc_name, @proc_code, @proc_lastaltered, @db_name
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	--STEP 2: same for all the tables
	DECLARE @table_name VARCHAR(100)
	DECLARE @table_definition VARCHAR(MAX)
	DECLARE @lastModified DATETIME

	DECLARE db_cursor CURSOR FOR
		SELECT A.TABLE_NAME, C.DB_NAME, B.modify_date
        FROM INFORMATION_SCHEMA.TABLES A
			JOIN  sys.tables B ON B.name=A.TABLE_NAME
			LEFT JOIN Integration.dbo.DB_SP_LOG C ON C.DB_NAME=DB_NAME() AND C.[ROUTINE_NAME]=A.TABLE_NAME AND C.ROUTINE_TYPE='TABLE'
        WHERE TABLE_TYPE = 'BASE TABLE'
			AND (C.[LAST_ALTERED]<>B.modify_date OR C.DB_NAME IS NULL)

	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @table_name, @db_name, @lastModified

	SET @routine_type='TABLE'
	WHILE @@FETCH_STATUS = 0  
	BEGIN

		SET @bcpOutFile  = '\\rkdc1-sqldev01\TempData\SOURCECODE\RKDC1-SQLDEV01_RALPHIE_QC_UAT\' + @routine_type + '\' + @table_name + '.sql'

		SET @table_definition = dbo.udf_CreateTableScript(@table_name)

		TRUNCATE TABLE ##tmpStoredProc
		INSERT ##tmpStoredProc (ROUTINE_DEFINITION) VALUES (@table_definition)

		/* not sure why this isn't working making me use temp table
		set @SelectString = 'SELECT TOP 1 ROUTINE_DEFINITION FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE=''''PROCEDURE'''' AND SPECIFIC_NAME=''''' + @proc_name + ''''''
		set @bcpOutFile  = '\\rkdc1-sqldev01\TempData\SOURCECODE\' + @proc_name + '.sql'
		set @bcpString = 'bcp "' + rtrim(@SelectString) + ' " queryout "'  + @bcpOutFile + '" -c -T -t,'
		select @bcpString
		EXECUTE @shellresult = xp_cmdshell @bcpString
		*/

		SET @bcpString = 'bcp "SELECT ROUTINE_DEFINITION FROM ##tmpStoredProc" queryout "'  + @bcpOutFile + '" -c -T -t,'
		select @bcpString
		EXECUTE @shellresult = xp_cmdshell @bcpString

		IF @db_name > '' BEGIN
			--update log with same last altered date
			UPDATE Integration.dbo.DB_SP_LOG SET LAST_ALTERED=@lastModified
			WHERE DB_NAME=@db_name
				AND ROUTINE_TYPE=@routine_type
				AND ROUTINE_NAME=@table_name
		END ELSE BEGIN
			INSERT Integration.dbo.DB_SP_LOG ([DB_NAME], ROUTINE_TYPE, ROUTINE_NAME, LAST_ALTERED)
			VALUES (DB_NAME(), @routine_type, @table_name, @proc_lastaltered)
		END	

		FETCH NEXT FROM db_cursor INTO @table_name, @db_name, @lastModified
	END 

	CLOSE db_cursor  
	DEALLOCATE db_cursor 

	SELECT * FROM ##tmpStoredProc
END

