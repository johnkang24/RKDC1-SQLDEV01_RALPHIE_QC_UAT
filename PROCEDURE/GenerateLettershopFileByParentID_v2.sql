CREATE PROCEDURE [dbo].[GenerateLettershopFileByParentID_v2]
(
	@parentID VARCHAR(100),
	@outputFileName VARCHAR(MAX)
)
AS

DECLARE @testing BIT = 0

--TESTING
--DECLARE @parentID VARCHAR(100)
--SET @parentID = '132104'
--DECLARE @outputFileName VARCHAR(MAX)
--SET @outputFileName = '\\rkdc1-sqldev01\tempdata\QC FILES\OUTPUT FILES\LETTERSHOP\ClientCode\MWKWI\2025_Production_Files\ReadyToUpload\D_MWKWI_25-Dec_SFTS_131426_V2.csv'
--SET @testing = 1

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
		[qc_record] [varchar](50) NOT NULL,
		IsSeed varchar(1) NULL
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
	''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record'',''-1''
	';
	--INSERT ##LettershopExportStaging
	--EXEC sp_executesql @sql;

	--JCK:11.13.2025 - put seeds at the bottom
	-- Insert actual data
--	INSERT INTO ##LettershopExportStaging
	SET @sql = 'SELECT ''client_code'',''id'',''salutation'',''company'',''addressee1'',''addressee2'',''gender'',''title'',''fname'',''middle'',''lname'',''suffix'',''email'',''phone'',''address1'',''address2'',''city'',''state'',''zip'',''dpv'',''giftdate'',''giftamt'',''i_giftdate'',''totalamt'',''memgifamt'',''memgifdat'',''rm'',''list'',''parent_id'',''child_id'',''plsr_code'',''clsr_code'',''mailtype'',''mailmnth'',''mailpkg'',''ltramt'',''ug1'',''lg'',''ug2'',''ug3'',''ug4'',''ug5'',''ug6'',''m1'',''mg'',''m2'',''m3'',''m4'',''m5'',''m6'',''appeal1'',''appeal2'',''appeal3'',''scanline1'',''scanline2'',''scanline3'',''bc2d1'',''bc2d2'',''bc2d3'',''bc2d4'',''bc2d5'',''bc2d6'',''b30f9'',''misc1'',''misc2'',''misc3'',''misc4'',''misc5'',''misc6'',''misc7'',''misc8'',''misc9'',''county'',''stitle'',''sfname'',''smiddle'',''slname'',''ssuffix'',''importid'',''solcode1'',''solcode2'',''solcode3'',''multi_flg'',''endorsement'',''ws'',''cr_sequence'',''cr_id'',''income'',''serial'',''qc_record'',NULL
	UNION ALL
	SELECT
		client_code,
		A.id,
		CASE WHEN CHARINDEX('','',A.salutation)>0 THEN ''"'' + A.salutation + ''"'' ELSE A.salutation END,
		CASE WHEN CHARINDEX('','',A.company)>0 THEN ''"'' + A.company + ''"'' ELSE A.company END,
		CASE WHEN CHARINDEX('','',A.addressee1)>0 THEN ''"'' + A.addressee1 + ''"'' ELSE A.addressee1 END,
		CASE WHEN CHARINDEX('','',A.addressee2)>0 THEN ''"'' + A.addressee2 + ''"'' ELSE A.addressee2 END,
		CASE WHEN CHARINDEX('','',A.gender)>0 THEN ''"'' + A.gender + ''"'' ELSE A.gender END,
		CASE WHEN CHARINDEX('','',A.title)>0 THEN ''"'' + A.title + ''"'' ELSE A.title END,
		CASE WHEN CHARINDEX('','',A.fname)>0 THEN ''"'' + A.fname + ''"'' ELSE A.fname END,
		CASE WHEN CHARINDEX('','',A.middle)>0 THEN ''"'' + A.middle + ''"'' ELSE A.middle END,
		CASE WHEN CHARINDEX('','',A.lname)>0 THEN ''"'' + A.lname + ''"'' ELSE A.lname END,
		CASE WHEN CHARINDEX('','',A.suffix)>0 THEN ''"'' + A.suffix + ''"'' ELSE A.suffix END,
		CASE WHEN CHARINDEX('','',A.email)>0 THEN ''"'' + A.email + ''"'' ELSE A.email END,
		CASE WHEN CHARINDEX('','',A.phone)>0 THEN ''"'' + A.phone + ''"'' ELSE A.phone END,
		CASE WHEN B.id IS NULL THEN 
			CASE WHEN CHARINDEX('','',A.address1)>0 THEN ''"'' + A.address1 + ''"'' ELSE A.address1 END
			ELSE CASE WHEN CHARINDEX('','',B.address1)>0 THEN ''"'' + B.address1 + ''"'' ELSE B.address1 END END,
		CASE WHEN B.id IS NULL THEN
			CASE WHEN CHARINDEX('','',A.address2)>0 THEN ''"'' + A.address2 + ''"'' ELSE A.address2 END
			ELSE CASE WHEN CHARINDEX('','',B.address2)>0 THEN ''"'' + B. address2 + ''"'' ELSE B.address2 END END,
		CASE WHEN B.id IS NULL THEN
			CASE WHEN CHARINDEX('','',A.city)>0 THEN ''"'' + A.city + ''"'' ELSE A.city END
			ELSE CASE WHEN CHARINDEX('','',B.city)>0 THEN ''"'' + B.city + ''"'' ELSE B.city END END,
		CASE WHEN B.id IS NULL THEN
			CASE WHEN CHARINDEX('','',A.state)>0 THEN ''"'' + A.state + ''"'' ELSE A.state END
			ELSE CASE WHEN CHARINDEX('','',B.state)>0 THEN ''"'' + B.state + ''"'' ELSE B.state END END,
		CASE WHEN B.id IS NULL THEN
			CASE WHEN CHARINDEX('','',A.zip)>0 THEN ''"'' + A.zip + ''"'' ELSE A.zip END
			ELSE CASE WHEN CHARINDEX('','',B.zip)>0 THEN ''"'' + B.zip + ''"'' ELSE B.zip END END,
		CASE WHEN B.id IS NULL THEN
			CASE WHEN CHARINDEX('','',A.dpv)>0 THEN ''"'' + A.dpv + ''"'' ELSE A.dpv END
			ELSE CASE WHEN CHARINDEX('','',B.delivery_point)>0 THEN ''"'' + REPLACE(B.delivery_point,CHAR(13),'''') + ''"'' ELSE REPLACE(B.delivery_point,CHAR(13),'''') END END,
		giftdate,
		giftamt,
		i_giftdate,
		totalamt,
		memgifamt,
		memgifdat,
		CASE WHEN CHARINDEX('','',A.rm)>0 THEN ''"'' + A.rm + ''"'' ELSE A.rm END,
		CASE WHEN CHARINDEX('','',A.list)>0 THEN ''"'' + A.list + ''"'' ELSE A.list END,
		parent_id,
		child_id,
		CASE WHEN CHARINDEX('','',A.plsr_code)>0 THEN ''"'' + A.plsr_code + ''"'' ELSE A.plsr_code END,
		CASE WHEN CHARINDEX('','',A.clsr_code)>0 THEN ''"'' + A.clsr_code + ''"'' ELSE A.clsr_code END,
		CASE WHEN CHARINDEX('','',A.mailtype)>0 THEN ''"'' + A.mailtype + ''"'' ELSE A.mailtype END,
		CASE WHEN CHARINDEX('','',A.mailmnth)>0 THEN ''"'' + A.mailmnth + ''"'' ELSE A.mailmnth END,
		CASE WHEN CHARINDEX('','',A.mailpkg)>0 THEN ''"'' + A.mailpkg + ''"'' ELSE A.mailpkg END,
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
		CASE WHEN CHARINDEX('','',A.appeal1)>0 THEN ''"'' + A.appeal1 + ''"'' ELSE A.appeal1 END,
		CASE WHEN CHARINDEX('','',A.appeal2)>0 THEN ''"'' + A.appeal2 + ''"'' ELSE A.appeal2 END,
		CASE WHEN CHARINDEX('','',A.appeal3)>0 THEN ''"'' + A.appeal3 + ''"'' ELSE A.appeal3 END,
		CASE WHEN CHARINDEX('','',A.scanline1)>0 THEN ''"'' + A.scanline1 + ''"'' ELSE A.scanline1 END,
		CASE WHEN CHARINDEX('','',A.scanline2)>0 THEN ''"'' + A.scanline2 + ''"'' ELSE A.scanline2 END,
		CASE WHEN CHARINDEX('','',A.scanline3)>0 THEN ''"'' + A.scanline3 + ''"'' ELSE A.scanline3 END,
		bc2d1,
		bc2d2,
		bc2d3,
		bc2d4,
		bc2d5,
		bc2d6,
		bc3of9,
		CASE WHEN CHARINDEX('','',A.misc1)>0 THEN ''"'' + A.misc1 + ''"'' ELSE A.misc1 END,
		CASE WHEN CHARINDEX('','',A.misc2)>0 THEN ''"'' + A.misc2 + ''"'' ELSE A.misc2 END,
		CASE WHEN CHARINDEX('','',A.misc3)>0 THEN ''"'' + A.misc3 + ''"'' ELSE A.misc3 END,
		CASE WHEN CHARINDEX('','',A.misc4)>0 THEN ''"'' + A.misc4 + ''"'' ELSE A.misc4 END,
		CASE WHEN CHARINDEX('','',A.misc5)>0 THEN ''"'' + A.misc5 + ''"'' ELSE A.misc5 END,
		CASE WHEN CHARINDEX('','',A.misc6)>0 THEN ''"'' + A.misc6 + ''"'' ELSE A.misc6 END,
		CASE WHEN CHARINDEX('','',A.misc7)>0 THEN ''"'' + A.misc7 + ''"'' ELSE A.misc7 END,
		CASE WHEN CHARINDEX('','',A.misc8)>0 THEN ''"'' + A.misc8 + ''"'' ELSE A.misc8 END,
		CASE WHEN CHARINDEX('','',A.misc9)>0 THEN ''"'' + A.misc9 + ''"'' ELSE A.misc9 END,
		CASE WHEN CHARINDEX('','',A.county)>0 THEN ''"'' + A.county + ''"'' ELSE A.county END,
		CASE WHEN CHARINDEX('','',A.stitle)>0 THEN ''"'' + A.stitle + ''"'' ELSE A.stitle END,
		CASE WHEN CHARINDEX('','',A.sfname)>0 THEN ''"'' + A.sfname + ''"'' ELSE A.sfname END,
		CASE WHEN CHARINDEX('','',A.smiddle)>0 THEN ''"'' + A.smiddle + ''"'' ELSE A.smiddle END,
		CASE WHEN CHARINDEX('','',A.slname)>0 THEN ''"'' + A.slname + ''"'' ELSE A.slname END,
		CASE WHEN CHARINDEX('','',A.ssuffix)>0 THEN ''"'' + A.ssuffix + ''"'' ELSE A.ssuffix END,
		CASE WHEN CHARINDEX('','',A.importid)>0 THEN ''"'' + A.importid + ''"'' ELSE A.importid END,
		CASE WHEN CHARINDEX('','',A.solcode1)>0 THEN ''"'' + A.solcode1 + ''"'' ELSE A.solcode1 END,
		CASE WHEN CHARINDEX('','',A.solcode2)>0 THEN ''"'' + A.solcode2 + ''"'' ELSE A.solcode2 END,
		CASE WHEN CHARINDEX('','',A.solcode3)>0 THEN ''"'' + A.solcode3 + ''"'' ELSE A.solcode3 END,
		CASE WHEN CHARINDEX('','',A.multi_flg)>0 THEN ''"'' + A.multi_flg + ''"'' ELSE A.multi_flg END,
		CASE WHEN CHARINDEX('','',A.endorsement)>0 THEN ''"'' + A.endorsement + ''"'' ELSE A.endorsement END,
		CASE WHEN CHARINDEX('','',A.ws)>0 THEN ''"'' + A.ws + ''"'' ELSE A.ws END,
		CASE WHEN CHARINDEX('','',A.cr_sequence)>0 THEN ''"'' + A.cr_sequence + ''"'' ELSE A.cr_sequence END,
		CASE WHEN CHARINDEX('','',A.cr_id)>0 THEN ''"'' + A.cr_id + ''"'' ELSE A.cr_id END,
		CASE WHEN CHARINDEX('','',A.income)>0 THEN ''"'' + A.income + ''"'' ELSE A.income END,
		CASE WHEN CHARINDEX('','',A.serial)>0 THEN ''"'' + TRIM(REPLACE(REPLACE(A.serial, CHAR(13), ''''''''), CHAR(10), '''''''')) + ''"'' ELSE TRIM(REPLACE(REPLACE(A.serial, CHAR(13), ''''''''), CHAR(10), '''''''')) END,
		CAST(qc_record AS VARCHAR(1)),
		CAST(IsSeed AS VARCHAR(1))
	FROM dbo.ORIGINAL A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id
	WHERE parent_id = @parentID
		AND (B.dupedrop IS NULL OR B.dupedrop<>''TRUE'')
		AND (B.error_code IS NULL OR B.error_code NOT IN (
		''-1'',''111'',''112'',''113'',''114'',''211'',''212'',''213'',''214'',''215'',''216'',''217'',''218'',''219'',''220'',
		''311'',''312'',''313'',''411'',''412'',''413'',''414'',''415'',''416'',''417'',''418'',''419'',''420'',''421'',
		''422'',''423'',''491'',''492'',''493'',''494'')
		)
	ORDER BY 91'

	--	SELECT
	--	client_code,
	--	id,
	--	CASE WHEN CHARINDEX('','',salutation)>0 THEN ''"'' + salutation + ''"'' ELSE salutation END,
	--	CASE WHEN CHARINDEX('','',company)>0 THEN ''"'' + company + ''"'' ELSE company END,
	--	CASE WHEN CHARINDEX('','',addressee1)>0 THEN ''"'' + addressee1 + ''"'' ELSE addressee1 END,
	--	CASE WHEN CHARINDEX('','',addressee2)>0 THEN ''"'' + addressee2 + ''"'' ELSE addressee2 END,
	--	CASE WHEN CHARINDEX('','',gender)>0 THEN ''"'' +  gender + ''"'' ELSE gender END,
	--	CASE WHEN CHARINDEX('','',title)>0 THEN ''"'' + title + ''"'' ELSE title END,
	--	CASE WHEN CHARINDEX('','',fname)>0 THEN ''"'' + fname + ''"'' ELSE fname END,
	--	CASE WHEN CHARINDEX('','',middle)>0 THEN ''"'' + middle + ''"'' ELSE middle END,
	--	CASE WHEN CHARINDEX('','',lname)>0 THEN ''"'' + lname + ''"'' ELSE lname END,
	--	CASE WHEN CHARINDEX('','',suffix)>0 THEN ''"'' + suffix + ''"'' ELSE suffix END,
	--	CASE WHEN CHARINDEX('','',email)>0 THEN ''"'' + email + ''"'' ELSE email END,
	--	CASE WHEN CHARINDEX('','',phone)>0 THEN ''"'' + phone + ''"'' ELSE phone END,
	--	CASE WHEN CHARINDEX('','',address1)>0 THEN ''"'' + address1 + ''"'' ELSE address1 END,
	--	CASE WHEN CHARINDEX('','',address2)>0 THEN ''"'' +  address2 + ''"'' ELSE address2 END,
	--	CASE WHEN CHARINDEX('','',city)>0 THEN ''"'' +  city + ''"'' ELSE city END,
	--	CASE WHEN CHARINDEX('','',state)>0 THEN ''"'' +  state + ''"'' ELSE state END,
	--	CASE WHEN CHARINDEX('','',zip)>0 THEN ''"'' +  zip + ''"'' ELSE zip END,
	--	CASE WHEN CHARINDEX('','',dpv)>0 THEN ''"'' +  dpv + ''"'' ELSE dpv END,
	--	giftdate,
	--	giftamt,
	--	i_giftdate,
	--	totalamt,
	--	memgifamt,
	--	memgifdat,
	--	CASE WHEN CHARINDEX('','',rm)>0 THEN ''"'' +  rm + ''"'' ELSE rm END,
	--	CASE WHEN CHARINDEX('','',list)>0 THEN ''"'' +  list + ''"'' ELSE list END,
	--	parent_id,
	--	child_id,
	--	CASE WHEN CHARINDEX('','',plsr_code)>0 THEN ''"'' +  plsr_code + ''"'' ELSE plsr_code END,
	--	CASE WHEN CHARINDEX('','',clsr_code)>0 THEN ''"'' +  clsr_code + ''"'' ELSE clsr_code END,
	--	CASE WHEN CHARINDEX('','',mailtype)>0 THEN ''"'' +  mailtype + ''"'' ELSE mailtype END,
	--	CASE WHEN CHARINDEX('','',mailmnth)>0 THEN ''"'' +  mailmnth + ''"'' ELSE mailmnth END,
	--	CASE WHEN CHARINDEX('','',mailpkg)>0 THEN ''"'' +  mailpkg + ''"'' ELSE mailpkg END,
	--	ltramt,
	--	ug1,
	--	lg,
	--	ug2,
	--	ug3,
	--	ug4,
	--	ug5,
	--	ug6,
	--	m1,
	--	mg,
	--	m2,
	--	m3,
	--	m4,
	--	m5,
	--	m6,
	--	CASE WHEN CHARINDEX('','',appeal1)>0 THEN ''"'' +  appeal1 + ''"'' ELSE appeal1 END,
	--	CASE WHEN CHARINDEX('','',appeal2)>0 THEN ''"'' +  appeal2 + ''"'' ELSE appeal2 END,
	--	CASE WHEN CHARINDEX('','',appeal3)>0 THEN ''"'' +  appeal3 + ''"'' ELSE appeal3 END,
	--	CASE WHEN CHARINDEX('','',scanline1)>0 THEN ''"'' +  scanline1 + ''"'' ELSE scanline1 END,
	--	CASE WHEN CHARINDEX('','',scanline2)>0 THEN ''"'' +  scanline2 + ''"'' ELSE scanline2 END,
	--	CASE WHEN CHARINDEX('','',scanline3)>0 THEN ''"'' +  scanline3 + ''"'' ELSE scanline3 END,
	--	bc2d1,
	--	bc2d2,
	--	bc2d3,
	--	bc2d4,
	--	bc2d5,
	--	bc2d6,
	--	bc3of9,
	--	CASE WHEN CHARINDEX('','',misc1)>0 THEN ''"'' +  misc1 + ''"'' ELSE misc1 END,
	--	CASE WHEN CHARINDEX('','',misc2)>0 THEN ''"'' +  misc2 + ''"'' ELSE misc2 END,
	--	CASE WHEN CHARINDEX('','',misc3)>0 THEN ''"'' +  misc3 + ''"'' ELSE misc3 END,
	--	CASE WHEN CHARINDEX('','',misc4)>0 THEN ''"'' +  misc4 + ''"'' ELSE misc4 END,
	--	CASE WHEN CHARINDEX('','',misc5)>0 THEN ''"'' +  misc5 + ''"'' ELSE misc5 END,
	--	CASE WHEN CHARINDEX('','',misc6)>0 THEN ''"'' +  misc6 + ''"'' ELSE misc6 END,
	--	CASE WHEN CHARINDEX('','',misc7)>0 THEN ''"'' +  misc7 + ''"'' ELSE misc7 END,
	--	CASE WHEN CHARINDEX('','',misc8)>0 THEN ''"'' +  misc8 + ''"'' ELSE misc8 END,
	--	CASE WHEN CHARINDEX('','',misc9)>0 THEN ''"'' +  misc9 + ''"'' ELSE misc9 END,
	--	CASE WHEN CHARINDEX('','',county)>0 THEN ''"'' +  county + ''"'' ELSE county END,
	--	CASE WHEN CHARINDEX('','',stitle)>0 THEN ''"'' +  stitle + ''"'' ELSE stitle END,
	--	CASE WHEN CHARINDEX('','',sfname)>0 THEN ''"'' +  sfname + ''"'' ELSE sfname END,
	--	CASE WHEN CHARINDEX('','',smiddle)>0 THEN ''"'' +  smiddle + ''"'' ELSE smiddle END,
	--	CASE WHEN CHARINDEX('','',slname)>0 THEN ''"'' +  slname + ''"'' ELSE slname END,
	--	CASE WHEN CHARINDEX('','',ssuffix)>0 THEN ''"'' +  ssuffix + ''"'' ELSE ssuffix END,
	--	CASE WHEN CHARINDEX('','',importid)>0 THEN ''"'' +  importid + ''"'' ELSE importid END,
	--	CASE WHEN CHARINDEX('','',solcode1)>0 THEN ''"'' +  solcode1 + ''"'' ELSE solcode1 END,
	--	CASE WHEN CHARINDEX('','',solcode2)>0 THEN ''"'' +  solcode2 + ''"'' ELSE solcode2 END,
	--	CASE WHEN CHARINDEX('','',solcode3)>0 THEN ''"'' +  solcode3 + ''"'' ELSE solcode3 END,
	--	CASE WHEN CHARINDEX('','',multi_flg)>0 THEN ''"'' +  multi_flg + ''"'' ELSE multi_flg END,
	--	CASE WHEN CHARINDEX('','',endorsement)>0 THEN ''"'' +  endorsement + ''"'' ELSE endorsement END,
	--	CASE WHEN CHARINDEX('','',ws)>0 THEN ''"'' +  ws + ''"'' ELSE ws END,
	--	CASE WHEN CHARINDEX('','',cr_sequence)>0 THEN ''"'' +  cr_sequence + ''"'' ELSE cr_sequence END,
	--	CASE WHEN CHARINDEX('','',cr_id)>0 THEN ''"'' +  cr_id + ''"'' ELSE cr_id END,
	--	CASE WHEN CHARINDEX('','',income)>0 THEN ''"'' +  income + ''"'' ELSE income END,
	--	CASE WHEN CHARINDEX('','',serial)>0 THEN ''"'' +  TRIM(REPLACE(REPLACE(serial, CHAR(13), ''''), CHAR(10), '''')) + ''"'' ELSE TRIM(REPLACE(REPLACE(serial, CHAR(13), ''''), CHAR(10), '''')) END,
	--	CAST(qc_record AS VARCHAR(1)),
	--	CAST(IsSeed AS VARCHAR(1))
	--FROM dbo.ORIGINAL
	--WHERE parent_id = @parentID
	--ORDER BY 91

	PRINT @sql
	INSERT ##LettershopExportStaging
	EXEC sp_executesql @sql, N'@parentID VARCHAR(100)', @parentID;

	--SELECT  top 1 * FROM ##LettershopExportStaging
	--where isseed='1'

    -- Build and execute BCP command
	IF @testing=1 BEGIN
		SELECT * FROM ##LettershopExportStaging
	END ELSE BEGIN
		DECLARE @bcpCommand VARCHAR(8000);
		SET @bcpCommand = 
			'bcp "SELECT client_code,id,salutation,company,addressee1,addressee2,gender,title,fname,middle,lname,suffix,email,phone,address1,address2,city,state,zip,dpv,giftdate,giftamt,i_giftdate,totalamt,memgifamt,memgifdat,rm,list,parent_id,child_id,plsr_Code,clsr_Code,mailtype,mailmnth,mailpkg,ltramt,ug1,lg,ug2,ug3,ug4,ug5,ug6,m1,mg,m2,m3,m4,m5,m6,appeal1,appeal2,appeal3,scanline1,scanline2,scanline3,bc2d1,bc2d2,bc2d3,bc2d4,bc2d5,bc2d6,bc3of9,misc1,misc2,misc3,misc4,misc5,misc6,misc7,misc8,misc9,county,stitle,sfname,smiddle,slname,ssuffix,importid,solcode1,solcode2,solcode3,multi_flg,endorsement,ws,cr_sequence,cr_id,income,serial,qc_record FROM ##LettershopExportStaging ORDER BY IsSeed" queryout "' + @outputFileName + '" -c -t, -T -S ';

		PRINT @bcpCommand
		EXEC xp_cmdshell @bcpCommand;
	END

	IF @testing=0 BEGIN
		UPDATE ProcessLog SET Lettershop_FileName=@outputFilename
		WHERE Parent_ID=@parentID
	END ELSE BEGIN
		-- delete the table
		SET @sql = 'DROP TABLE ##LettershopExportStaging;'
		EXEC sp_executesql @sql;
	END
END


