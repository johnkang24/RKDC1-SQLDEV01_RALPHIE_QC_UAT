CREATE PROCEDURE [dbo].[GenerateLettershopFileByParentID]
(
	@parentID VARCHAR(100),
	@outputFileName VARCHAR(MAX)
)
AS

----TESTING
--DECLARE @parentID VARCHAR(100)
--SET @parentID = '132082'
--DECLARE @outputFileName VARCHAR(MAX)
--SET @outputFileName = '\\rkdc1-sqldev01\tempdata\QC FILES\OUTPUT FILES\LETTERSHOP\ClientCode\MWKWI\2025_Production_Files\ReadyToUpload\D_MWKWI_25-Dec_SFTS_132082.csv'

BEGIN

	SET NOCOUNT ON;
	DECLARE @sql NVARCHAR(MAX);
	
	IF OBJECT_ID('tempdb..##LettershopExportStaging') IS NOT NULL
		DROP TABLE ##LettershopExportStaging
	
	-- Create a temp table
--	SET @sql = '
	CREATE TABLE ##LettershopExportStaging(
		[client_code] [varchar](20) NULL,
		[id] [varchar](30) NULL,
		[salutation] [varchar](255) NULL,
		[company] [varchar](255) NULL,
		[addressee1] [varchar](255) NULL,
		[addressee2] [varchar](255) NULL,
		[gender] [varchar](50) NULL,
		[title] [varchar](255) NULL,
		[fname] [varchar](255) NULL,
		[middle] [varchar](255) NULL,
		[lname] [varchar](255) NULL,
		[suffix] [varchar](255) NULL,
		[email] [varchar](99) NULL,
		[phone] [varchar](50) NULL,
		[address1] [varchar](255) NULL,
		[address2] [varchar](255) NULL,
		[city] [varchar](50) NULL,
		[state] [varchar](30) NULL,
		[zip] [varchar](50) NULL,
		[dpv] [varchar](50) NULL,
		[giftdate] [varchar](50) NULL,
		[giftamt] [varchar](50) NULL,
		[i_giftdate] [varchar](50) NULL,
		[totalamt] [varchar](50) NULL,
		[memgifamt] [varchar](50) NULL,
		[memgifdat] [varchar](12) NULL,
		[rm] [varchar](50) NULL,
		[list] [varchar](50) NULL,
		[parent_id] [varchar](50) NULL,
		[child_id] [varchar](50) NULL,
		[plsr_Code] [varchar](50) NULL,
		[clsr_Code] [varchar](50) NULL,
		[mailtype] [varchar](50) NULL,
		[mailmnth] [varchar](50) NULL,
		[mailpkg] [varchar](50) NULL,
		[ltramt] [varchar](50) NULL,
		[ug1] [varchar](50) NULL,
		[lg] [varchar](50) NULL,
		[ug2] [varchar](50) NULL,
		[ug3] [varchar](50) NULL,
		[ug4] [varchar](50) NULL,
		[ug5] [varchar](50) NULL,
		[ug6] [varchar](50) NULL,
		[m1] [varchar](50) NULL,
		[mg] [varchar](50) NULL,
		[m2] [varchar](50) NULL,
		[m3] [varchar](50) NULL,
		[m4] [varchar](50) NULL,
		[m5] [varchar](50) NULL,
		[m6] [varchar](50) NULL,
		[appeal1] [varchar](50) NULL,
		[appeal2] [varchar](50) NULL,
		[appeal3] [varchar](50) NULL,
		[scanline1] [varchar](50) NULL,
		[scanline2] [varchar](50) NULL,
		[scanline3] [varchar](50) NULL,
		[bc2d1] [varchar](50) NULL,
		[bc2d2] [varchar](50) NULL,
		[bc2d3] [varchar](50) NULL,
		[bc2d4] [varchar](50) NULL,
		[bc2d5] [varchar](50) NULL,
		[bc2d6] [varchar](50) NULL,
		[bc3of9] [varchar](50) NULL,
		[misc1] [varchar](50) NULL,
		[misc2] [varchar](50) NULL,
		[misc3] [varchar](50) NULL,
		[misc4] [varchar](50) NULL,
		[misc5] [varchar](50) NULL,
		[misc6] [varchar](50) NULL,
		[misc7] [varchar](50) NULL,
		[misc8] [varchar](50) NULL,
		[misc9] [varchar](50) NULL,
		[county] [varchar](50) NULL,
		[stitle] [varchar](255) NULL,
		[sfname] [varchar](255) NULL,
		[smiddle] [varchar](255) NULL,
		[slname] [varchar](255) NULL,
		[ssuffix] [varchar](255) NULL,
		[importid] [varchar](50) NULL,
		[solcode1] [varchar](255) NULL,
		[solcode2] [varchar](255) NULL,
		[solcode3] [varchar](255) NULL,
		[multi_flg] [varchar](50) NULL,
		[endorsement] [varchar](50) NULL,
		[ws] [varchar](50) NULL,
		[cr_sequence] [varchar](50) NULL,
		[cr_id] [varchar](50) NULL,
		[income] [varchar](50) NULL,
		[serial] [varchar](50) NULL,
		[qc_record] [varchar](50) NOT NULL
	);
--	';

--	EXEC sp_executesql @sql;

	-- Add column headers
	--SET @sql = '
	--INSERT INTO ##LettershopExportStaging
	--SELECT 
	--''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record'';
	--';
	--EXEC sp_executesql @sql;
	
--	''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record''
	SET @sql = '
	SELECT 
	''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record''
	';
	--INSERT ##LettershopExportStaging
	--EXEC sp_executesql @sql;

	-- Insert actual data
--	INSERT INTO ##LettershopExportStaging
	SET @sql = 'SELECT ''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record''
	UNION ALL
	SELECT
		client_code,
		id,
		CASE WHEN CHARINDEX('','',salutation)>1 THEN ''"'' + salutation + ''"'' ELSE salutation END,
		CASE WHEN CHARINDEX('','',company)>1 THEN ''"'' + company + ''"'' ELSE company END,
		CASE WHEN CHARINDEX('','',addressee1)>1 THEN ''"'' + addressee1 + ''"'' ELSE addressee1 END,
		CASE WHEN CHARINDEX('','',addressee2)>1 THEN ''"'' + addressee2 + ''"'' ELSE addressee2 END,
		CASE WHEN CHARINDEX('','',gender)>1 THEN ''"'' +  gender + ''"'' ELSE gender END,
		CASE WHEN CHARINDEX('','',title)>1 THEN ''"'' + title + ''"'' ELSE title END,
		CASE WHEN CHARINDEX('','',fname)>1 THEN ''"'' + fname + ''"'' ELSE fname END,
		CASE WHEN CHARINDEX('','',middle)>1 THEN ''"'' + middle + ''"'' ELSE middle END,
		CASE WHEN CHARINDEX('','',lname)>1 THEN ''"'' + lname + ''"'' ELSE lname END,
		CASE WHEN CHARINDEX('','',suffix)>1 THEN ''"'' + suffix + ''"'' ELSE suffix END,
		CASE WHEN CHARINDEX('','',email)>1 THEN ''"'' + email + ''"'' ELSE email END,
		CASE WHEN CHARINDEX('','',phone)>1 THEN ''"'' + phone + ''"'' ELSE phone END,
		CASE WHEN CHARINDEX('','',address1)>1 THEN ''"'' + address1 + ''"'' ELSE address1 END,
		CASE WHEN CHARINDEX('','',address2)>1 THEN ''"'' +  address2 + ''"'' ELSE address2 END,
		CASE WHEN CHARINDEX('','',city)>1 THEN ''"'' +  city + ''"'' ELSE city END,
		CASE WHEN CHARINDEX('','',state)>1 THEN ''"'' +  state + ''"'' ELSE state END,
		CASE WHEN CHARINDEX('','',zip)>1 THEN ''"'' +  zip + ''"'' ELSE zip END,
		CASE WHEN CHARINDEX('','',dpv)>1 THEN ''"'' +  dpv + ''"'' ELSE dpv END,
		giftdate,
		giftamt,
		i_giftdate,
		totalamt,
		memgifamt,
		memgifdat,
		CASE WHEN CHARINDEX('','',rm)>1 THEN ''"'' +  rm + ''"'' ELSE rm END,
		CASE WHEN CHARINDEX('','',list)>1 THEN ''"'' +  list + ''"'' ELSE list END,
		parent_id,
		child_id,
		CASE WHEN CHARINDEX('','',plsr_code)>1 THEN ''"'' +  plsr_code + ''"'' ELSE plsr_code END,
		CASE WHEN CHARINDEX('','',clsr_code)>1 THEN ''"'' +  clsr_code + ''"'' ELSE clsr_code END,
		CASE WHEN CHARINDEX('','',mailtype)>1 THEN ''"'' +  mailtype + ''"'' ELSE mailtype END,
		CASE WHEN CHARINDEX('','',mailmnth)>1 THEN ''"'' +  mailmnth + ''"'' ELSE mailmnth END,
		CASE WHEN CHARINDEX('','',mailpkg)>1 THEN ''"'' +  mailpkg + ''"'' ELSE mailpkg END,
		ltramt,
		ug1,
		lg,
		ug2,
		ug3,
		ug4,
		ug5,
		ug6,
		m1,
		mg,
		m2,
		m3,
		m4,
		m5,
		m6,
		CASE WHEN CHARINDEX('','',appeal1)>1 THEN ''"'' +  appeal1 + ''"'' ELSE appeal1 END,
		CASE WHEN CHARINDEX('','',appeal2)>1 THEN ''"'' +  appeal2 + ''"'' ELSE appeal2 END,
		CASE WHEN CHARINDEX('','',appeal3)>1 THEN ''"'' +  appeal3 + ''"'' ELSE appeal3 END,
		CASE WHEN CHARINDEX('','',scanline1)>1 THEN ''"'' +  scanline1 + ''"'' ELSE scanline1 END,
		CASE WHEN CHARINDEX('','',scanline2)>1 THEN ''"'' +  scanline2 + ''"'' ELSE scanline2 END,
		CASE WHEN CHARINDEX('','',scanline3)>1 THEN ''"'' +  scanline3 + ''"'' ELSE scanline3 END,
		bc2d1,
		bc2d2,
		bc2d3,
		bc2d4,
		bc2d5,
		bc2d6,
		bc3of9,
		CASE WHEN CHARINDEX('','',misc1)>1 THEN ''"'' +  misc1 + ''"'' ELSE misc1 END,
		CASE WHEN CHARINDEX('','',misc2)>1 THEN ''"'' +  misc2 + ''"'' ELSE misc2 END,
		CASE WHEN CHARINDEX('','',misc3)>1 THEN ''"'' +  misc3 + ''"'' ELSE misc3 END,
		CASE WHEN CHARINDEX('','',misc4)>1 THEN ''"'' +  misc4 + ''"'' ELSE misc4 END,
		CASE WHEN CHARINDEX('','',misc5)>1 THEN ''"'' +  misc5 + ''"'' ELSE misc5 END,
		CASE WHEN CHARINDEX('','',misc6)>1 THEN ''"'' +  misc6 + ''"'' ELSE misc6 END,
		CASE WHEN CHARINDEX('','',misc7)>1 THEN ''"'' +  misc7 + ''"'' ELSE misc7 END,
		CASE WHEN CHARINDEX('','',misc8)>1 THEN ''"'' +  misc8 + ''"'' ELSE misc8 END,
		CASE WHEN CHARINDEX('','',misc9)>1 THEN ''"'' +  misc9 + ''"'' ELSE misc9 END,
		CASE WHEN CHARINDEX('','',county)>1 THEN ''"'' +  county + ''"'' ELSE county END,
		CASE WHEN CHARINDEX('','',stitle)>1 THEN ''"'' +  stitle + ''"'' ELSE stitle END,
		CASE WHEN CHARINDEX('','',sfname)>1 THEN ''"'' +  sfname + ''"'' ELSE sfname END,
		CASE WHEN CHARINDEX('','',smiddle)>1 THEN ''"'' +  smiddle + ''"'' ELSE smiddle END,
		CASE WHEN CHARINDEX('','',slname)>1 THEN ''"'' +  slname + ''"'' ELSE slname END,
		CASE WHEN CHARINDEX('','',ssuffix)>1 THEN ''"'' +  ssuffix + ''"'' ELSE ssuffix END,
		CASE WHEN CHARINDEX('','',importid)>1 THEN ''"'' +  importid + ''"'' ELSE importid END,
		CASE WHEN CHARINDEX('','',solcode1)>1 THEN ''"'' +  solcode1 + ''"'' ELSE solcode1 END,
		CASE WHEN CHARINDEX('','',solcode2)>1 THEN ''"'' +  solcode2 + ''"'' ELSE solcode2 END,
		CASE WHEN CHARINDEX('','',solcode3)>1 THEN ''"'' +  solcode3 + ''"'' ELSE solcode3 END,
		CASE WHEN CHARINDEX('','',multi_flg)>1 THEN ''"'' +  multi_flg + ''"'' ELSE multi_flg END,
		CASE WHEN CHARINDEX('','',endorsement)>1 THEN ''"'' +  endorsement + ''"'' ELSE endorsement END,
		CASE WHEN CHARINDEX('','',ws)>1 THEN ''"'' +  ws + ''"'' ELSE ws END,
		CASE WHEN CHARINDEX('','',cr_sequence)>1 THEN ''"'' +  cr_sequence + ''"'' ELSE cr_sequence END,
		CASE WHEN CHARINDEX('','',cr_id)>1 THEN ''"'' +  cr_id + ''"'' ELSE cr_id END,
		CASE WHEN CHARINDEX('','',income)>1 THEN ''"'' +  income + ''"'' ELSE income END,
		CASE WHEN CHARINDEX('','',serial)>1 THEN ''"'' +  TRIM(REPLACE(REPLACE(serial, CHAR(13), ''''), CHAR(10), '''')) + ''"'' ELSE TRIM(REPLACE(REPLACE(serial, CHAR(13), ''''), CHAR(10), '''')) END,
		CAST(qc_record AS VARCHAR(1))
	FROM dbo.ORIGINAL
	WHERE parent_id = @parentID;'


	INSERT ##LettershopExportStaging
	EXEC sp_executesql @sql, N'@parentID VARCHAR(100)', @parentID;

	--SELECT  * FROM ##LettershopExportStaging

    -- Build and execute BCP command
    DECLARE @bcpCommand VARCHAR(8000);
    SET @bcpCommand = 
        'bcp "SELECT * FROM ##LettershopExportStaging" queryout "' + @outputFileName + '" -c -t, -T -S ';

	PRINT @bcpCommand
    EXEC xp_cmdshell @bcpCommand;

	UPDATE ProcessLog SET Lettershop_FileName=@outputFilename
	WHERE Parent_ID=@parentID

	-- delete the table
	SET @sql = 'DROP TABLE ##LettershopExportStaging;'

	EXEC sp_executesql @sql;

END


