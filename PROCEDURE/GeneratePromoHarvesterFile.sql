CREATE PROCEDURE [dbo].[GeneratePromoHarvesterFile]
(
	@parent_id VARCHAR(100),
	@outputPath VARCHAR(500)
)
AS

----TESTING
----DECLARE @parent_id VARCHAR(50)
----SET @parent_id = 50963
----DECLARE @output_path VARCHAR(50)
----SET @output_path = 'C:\SOME_PATH'

BEGIN

	SET NOCOUNT ON;
	--DECLARE @dbName SYSNAME = 'RALPHIE_QC';
	DECLARE @dbName SYSNAME = DB_NAME();
	DECLARE @coms_db SYSNAME = '[COMS_UATSB]';

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @package_code VARCHAR(10);
	DECLARE @phase_code VARCHAR(10);
	DECLARE @mail_date VARCHAR(50);
	DECLARE @quote_id VARCHAR(50);
	DECLARE @quoteline_id VARCHAR(50);
	DECLARE @file_id VARCHAR(50);
	DECLARE @adv_job_id VARCHAR(50);
	DECLARE @vertical VARCHAR(50);
	DECLARE @component_no VARCHAR(50);
	DECLARE @job_name VARCHAR(50);
	DECLARE @job_specific_name VARCHAR(50);
	DECLARE @test_control_cd VARCHAR(50);
	DECLARE @audience_code VARCHAR(50);
	DECLARE @audience_name VARCHAR(50);
	DECLARE @client_code VARCHAR(50);

	select 
		@quote_id = QuoteID, @quoteline_id = QuoteLine_ID, @package_code = Package_Code, 
		@phase_code = Phase_Code, @file_id = FileID, @job_name = Job_Name, @job_specific_name = Job_Specific_Name
	FROM dbo.ProcessLog
	WHERE Parent_ID = @parent_id

	SELECT @adv_job_id = Advantage_Job_ID, @client_code = Client_Code, @vertical = Vertical FROM dbo.FileLog where FileID = @file_id

	SET @sql = N'
    SELECT @component_no_out = Advantage_Component_ID__c,
		   @mail_date_out = CPQ_Mail_Ship_Date__c,
           @test_control_cd_out = CPQ_T_C_R__c,
		   @audience_code_out = SB_RKD_Audience_Code__c,
		   @audience_name_out = SB_RKD_Audience__c
    FROM ' + @coms_db + N'.dbo.SBQQ__QuoteLine__c
    WHERE id = @quoteLineId_in;';

	EXEC sp_executesql 
		@sql, 
		N'@quoteLineId_in NVARCHAR(50), @component_no_out NVARCHAR(100) OUTPUT, @mail_date_out NVARCHAR(100) OUTPUT, @test_control_cd_out NVARCHAR(100) OUTPUT, @audience_code_out NVARCHAR(100) OUTPUT, @audience_name_out NVARCHAR(100) OUTPUT', 
		@quoteLineId_in = @quoteline_id, 
		@component_no_out = @component_no OUTPUT,
		@mail_date_out = @mail_date OUTPUT,
		@test_control_cd_out = @test_control_cd OUTPUT,
		@audience_code_out = @audience_code OUTPUT,
		@audience_name_out = @audience_name OUTPUT;


	-- Create a temp table
	SET @sql = '
	CREATE TABLE [' + @dbName + '].dbo.PromoHarvesterExportStaging(
        client_code VARCHAR(100),
        account_code VARCHAR(100),
        mail_date VARCHAR(100),
        source_code_1 VARCHAR(100),
        source_code_2 VARCHAR(100),
        source_code_3 VARCHAR(100),
        phase VARCHAR(100),
        package VARCHAR(100),
        source_code_4 VARCHAR(100),
        job_number VARCHAR(100),
        component_no VARCHAR(100),
        list VARCHAR(100),
        audience_code VARCHAR(100),
        model_lifecyle VARCHAR(100),
        model_loyalty VARCHAR(100),
        model_last_gift_years VARCHAR(100),
        model_last_gift_months VARCHAR(100),
        model_decile VARCHAR(100),
        model_ever_dm VARCHAR(100),
        model_ever_ol VARCHAR(100),
        model_ever_other VARCHAR(100),
        model_tier VARCHAR(100),
        model_rank VARCHAR(100),
        model_datetime VARCHAR(100),
        model_name VARCHAR(100),
        model_score VARCHAR(100),
        prime_leads_1 VARCHAR(100),
        prime_leads_2 VARCHAR(100),
        prime_leads_3 VARCHAR(100),
        prefix_title VARCHAR(100),
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        suffix VARCHAR(100),
        company_name VARCHAR(100),
        primary_address VARCHAR(100),
        secondary_address VARCHAR(100),
        city VARCHAR(100),
        state VARCHAR(100),
        zip VARCHAR(100),
        campaign_name VARCHAR(100),
        package_name VARCHAR(100),
        audience_name VARCHAR(100),
        campaign_type VARCHAR(100),
        test_control_volume VARCHAR(100),
        test_control_volume_code VARCHAR(100),
        panel_name VARCHAR(100),
        rec_was_mailed VARCHAR(100),
		rm VARCHAR(100),
		parent_id VARCHAR(100),
		child_id VARCHAR(100),
		mailtype VARCHAR(100),
		mailmnth VARCHAR(100),
		mailpkg VARCHAR(100),
		vertical VARCHAR(100),
		misc_1 VARCHAR(100),
		misc_2 VARCHAR(100),
		misc_3 VARCHAR(100)
    );';

	EXEC sp_executesql @sql;

	-- Add column headers
	SET @sql = '
	INSERT INTO [' + @dbName + '].dbo.PromoHarvesterExportStaging
	SELECT 
	''CLIENT_CODE'', ''ACCOUNT_CODE'', ''MAIL_DATE'', ''SOURCE_CODE_1'', ''SOURCE_CODE_2'', ''SOURCE_CODE_3'', ''PHASE'', ''PACKAGE'', ''SOURCE_CODE_4'', ''JOB_NUMBER'', ''COMPONENT_NO'', ''LIST'', ''AUDIENCE_CODE'', ''MDL_LIFECYLE'', ''MDL_LOYALTY'', ''MDL_LST_GFT_YRS'', ''MDL_LST_GFT_MNS'', ''MDL_DECILE'', ''MDL_EVER_DM'', ''MDL_EVER_OL'', ''MDL_EVER_OTHER'', ''MDL_TIER'', ''MDL_RANK'', ''MDL_DATETIME'', ''MDL_NAME'', ''MDL_SCORE'', ''PRIME_LEADS_1'', ''PRIME_LEADS_2'', ''PRIME_LEADS_3'', ''PREFIX_TITLE'', ''FIRST_NAME'', ''LAST_NAME'', ''SUFFIX'', ''COMPANY_NAME'', ''PRIMARY_ADDRESS'', ''SECONDARY_ADDRS'', ''CITY'', ''STATE'', ''ZIP'', ''CAMPAIGN_NAME'', ''PACKAGE_NAME'', ''AUDIENCE_NAME'', ''CAMPAIGN_TYPE'', ''TEST_CONTROL'', ''TEST_CONTROL_CD'', ''PANEL_NAME'', ''REC_WAS_MAILED'', ''RM'', ''PARENT_ID'', ''CHILD_ID'', ''MAILTYPE'', ''MAILMNTH'', ''MAILPKG'', ''VERTICAL'', ''MISC_1'', ''MISC_2'', ''MISC_3'';
	';

	EXEC sp_executesql @sql;
	

	-- Insert actual data
	SET @sql = '
	INSERT INTO [' + @dbName + '].dbo.PromoHarvesterExportStaging
	SELECT
        [client_code],
        [id] AS account_code,
        ''' + CONVERT(VARCHAR(10), @mail_date, 120) + ''' AS mail_date,
        [appeal1] AS source_code_1,
        [appeal2] AS source_code_2,
        [appeal3] AS source_code_3,
        ''' + REPLACE(ISNULL(@phase_code, ''), '''', '''''') + ''' AS phase,
        ''' + REPLACE(ISNULL(@package_code, ''), '''', '''''') + ''' AS package,
        '''' AS source_code_4,
		''' + REPLACE(ISNULL(@adv_job_id, ''), '''', '''''') + ''' AS job_number,
		''' + REPLACE(ISNULL(@component_no, ''), '''', '''''') + ''' AS component_no,
        [list],
        ''' + REPLACE(ISNULL(@audience_code, ''), '''', '''''') + ''' AS audience_code,
        '''' AS mdl_lifecyle,
        '''' AS mdl_loyalty,
        '''' AS mdl_last_gift_years,
        '''' AS mdl_last_gift_months,
        '''' AS mdl_decile,
        '''' AS mdl_ever_dm,
        '''' AS mdl_ever_ol,
        '''' AS mdl_ever_other,
        '''' AS mdl_tier,
        '''' AS mdl_rank,
        '''' AS mdl_datetime,
        '''' AS mdl_name,
        '''' AS mdl_score,
        '''' AS prime_leads_1,
        '''' AS prime_leads_2,
        '''' AS prime_leads_3,
        [title] AS prefix_title,
        [fname] AS first_name,
        [lname] AS last_name,
        [suffix],
		''"'' + REPLACE([company], ''"'', ''""'') + ''"'' AS company_name,
		''"'' + REPLACE([address1], ''"'', ''""'') + ''"'' AS primary_address,
		''"'' + REPLACE([address2], ''"'', ''""'') + ''"'' AS secondary_address,
        [city],
        [state],
        [zip],
		''' + REPLACE(ISNULL(@job_name, ''), '''', '''''') + ''' AS campaign_name,
		''' + REPLACE(ISNULL(@job_specific_name, ''), '''', '''''') + ''' AS package_name,
        ''' + REPLACE(ISNULL(@audience_name, ''), '''', '''''') + ''' AS audience_name,
        '''' AS campaign_type,
        '''' AS test_control_volume,
		''' + REPLACE(ISNULL(@test_control_cd, ''), '''', '''''') + ''' AS test_control_volume_code,
        '''' AS panel_name,
        ''1'' AS rec_was_mailed,
		[rm],
		[parent_id],
		[child_id],
		[mailtype],
		[mailmnth],
		[mailpkg],
		''' + REPLACE(ISNULL(@vertical, ''), '''', '''''') + ''' AS vertical,
		[misc1] as misc_1,
		[misc2] as misc_2,
		[misc3] as misc_3
	FROM [' + @dbName + '].dbo.ORIGINAL
	WHERE parent_id = @parent_id;'

	EXEC sp_executesql @sql, N'@parent_id VARCHAR(100)', @parent_id;


	SET @outputPath = @outputPath + '\' + @client_code + '_' + @parent_id + '.csv'

    -- Build and execute BCP command
    DECLARE @bcpCommand VARCHAR(8000);
    SET @bcpCommand = 
        'bcp "SELECT * FROM [' + @dbName + '].dbo.PromoHarvesterExportStaging" queryout "' + @outputPath + '" -c -t, -T -S ';

    EXEC xp_cmdshell @bcpCommand;

	UPDATE ProcessLog SET PromoHarvester_FileName=@outputPath
	WHERE Parent_ID=@parent_id

	-- delete the table
	SET @sql = 'DROP TABLE [' + @dbName + '].dbo.PromoHarvesterExportStaging;'

	EXEC sp_executesql @sql;

END

