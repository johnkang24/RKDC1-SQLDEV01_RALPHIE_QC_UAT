
CREATE PROCEDURE [dbo].[GetDataIntegrity]
(
	@parent_ID INT,
	@donor_id VARCHAR(255) = '',
	@lastName VARCHAR(255) = ''
)
AS

SET NOCOUNT ON

DECLARE @is_acquisition BIT

--DECLARE @parent_id INT, @donor_id VARCHAR(255) = '', @lastName VARCHAR(255) = ''
--SET @parent_id = 128949
----SET @donor_id = '218594,152906,99772'
--SET @donor_id = ''
--SET @lastName = ''

--JCK:10.21.2025 --
SELECT @is_acquisition=Is_Acquisition
FROM ProcessLog
WHERE Parent_ID=@parent_id

IF OBJECT_ID('TempDB..##DataIntegrity') IS NOT NULL
BEGIN
	DROP TABLE ##DataIntegrity
END

CREATE TABLE ##DataIntegrity
(
	Sort1 int, 
	Sort2 varchar(50), 
	Criteria varchar(151), 
	client_code varchar(20), 
	list varchar(50), 
	id varchar(30), 
	serial varchar(50), 
	importid varchar(50), 
	title varchar(255), 
	fname varchar(255), 
	middle varchar(255), 
	lname varchar(255), 
	suffix varchar(255),
	salutation varchar(255), 
	addressee1 varchar(255), 
	company varchar(255), 
	addressee2 varchar(255), 
	error_code varchar(255), 
	dupedrop varchar(50), 
	email varchar(99), 
	phone varchar(50), 
	gender varchar(50), 
	address1 varchar(255), 
	address2 varchar(255), 
	city varchar(50), 
	state varchar(30), 
	zip varchar(50), 
	county varchar(50), 
	delivery_point varchar(255), 
	giftamt varchar(50), 
	giftdate varchar(50), 
	i_giftdate varchar(50), 
	totalamt varchar(50), 
	memgifamt varchar(50), 
	memgifdat varchar(12), 
	PLSR_Code varchar(50), 
	CLSR_Code varchar(50), 
	parent_ID varchar(50), 
	child_ID varchar(50), 
	appeal1 varchar(50), 
	appeal2 varchar(50), 
	appeal3 varchar(50), 
	LTRAMT varchar(50), 
	UG1 varchar(50), 
	LG varchar(50), 
	UG2 varchar(50), 
	UG3 varchar(50), 
	UG4 varchar(50), 
	UG5 varchar(50), 
	UG6 varchar(1), 
	M1 varchar(50), 
	MG varchar(50), 
	M2 varchar(50), 
	M3 varchar(50), 
	M4 varchar(50), 
	M5 varchar(50), 
	M6 varchar(50), 
	MISC1 varchar(50), 
	MISC2 varchar(50), 
	MISC3 varchar(50), 
	MISC4 varchar(50), 
	MISC5 varchar(50), 
	MISC6 varchar(50), 
	MISC7 varchar(50), 
	MISC8 varchar(50), 
	MISC9 varchar(50), 
	rm varchar(50), 
	scanline1 varchar(50), 
	scanline2 varchar(50), 
	scanline3 varchar(50), 
	BC2D1 varchar(50), 
	BC2D2 varchar(50), 
	BC2D3 varchar(50), 
	BC2D4 varchar(50), 
	BC2D5 varchar(50), 
	BC2D6 varchar(50), 
	BC3of9 varchar(50), 
	mailtype varchar(50), 
	mailmnth varchar(50), 
	mailpkg varchar(50)
)

IF @donor_id <> '' OR @lastName <> '' BEGIN
	INSERT INTO ##DataIntegrity
	SELECT 1 AS Sort1, A.id AS Sort2, 'Criteria: ID, Addressee 1, Last Name, Address 1, Phone, Last Gift Date, Gift Date, MISC1, MISC7' Criteria 
		,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
		, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
		, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
		, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
		, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
	FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
	WHERE A.parent_id=@parent_id
		AND CASE WHEN @donor_id='' THEN @donor_id ELSE A.id END IN (SELECT * FROM STRING_SPLIT(REPLACE(@donor_id,' ',''),','))
		AND CASE WHEN @lastName='' THEN @lastName ELSE A.lname END IN (SELECT * FROM STRING_SPLIT(REPLACE(@lastName,' ',''),','))
	ORDER BY CASE WHEN @donor_id='' THEN A.lname ELSE A.id END
END ELSE BEGIN
	IF @is_acquisition=0 BEGIN
		--STEP 1: Criteria: Unique RM Code, ID, Addressee 1, Last Name, Address 1, Address 2, Last Gift Date, Gift Date, MISC7
		INSERT INTO ##DataIntegrity
		SELECT  t.*
		FROM (
			SELECT DISTINCT rm FROM ORIGINAL 
			WHERE parent_id=@parent_id) RM
		CROSS APPLY
			(SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Unique RM Code (' + A.rm + '), ID, Addressee 1, Last Name, Address 1, Address 2, Last Gift Date, Gift Date, MISC7' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND A.rm = RM.rm 
			) t
		--ORDER BY t.rm
		UNION ALL
		--STEP 2: Longest Addressee1
		SELECT TOP 1 2 AS Sort1, '' Sort2, 'Longest Addressee1, ID, Addressee 1, Last Name, Address 1, Last Gift Date, Gift Date, MISC7' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND LEN(A.addressee1)=(SELECT MAX(LEN(addressee1)) FROM ORIGINAL WHERE parent_id=@parent_id)
		UNION ALL
		--STEP 3: Shortest Addressee1
		SELECT TOP 1 3 AS Sort1, '' Sort2, 'Shortest Addressee1' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND LEN(A.addressee1)=(SELECT MIN(LEN(addressee1)) FROM ORIGINAL WHERE parent_id=@parent_id)
		UNION ALL
		--STEP 4: Longest Salutation
		SELECT TOP 1 4 AS Sort1, '' Sort2, 'Longest Salutation' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND LEN(A.salutation)=(SELECT MAX(LEN(salutation)) FROM ORIGINAL WHERE parent_id=@parent_id)
		UNION ALL
		--STEP 5: 1 record with Addressee 2 populated
		SELECT TOP 1 5 AS Sort1, '' Sort2, 'Addressee 2 populated' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND A.addressee2 > ''
		UNION ALL
		--STEP 6: 1 record with Company populated
		SELECT TOP 1 6 AS Sort1, '' Sort2, 'Company populated' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND A.company > ''
		UNION ALL
		--STEP 7: Address 1 populated
		SELECT TOP 1 7 AS Sort1, '' Sort2, 'Address 1 populated' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND A.address1 > ''
		UNION ALL
		--STEP 8: Address 2 populated
		SELECT TOP 1 8 AS Sort1, '' Sort2, 'Address 2 populated' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND A.address2 > ''
		UNION ALL
		--STEP 10: every variable of MISC2
		SELECT  t.*
		FROM (
			SELECT DISTINCT misc2 FROM ORIGINAL WHERE parent_id=@parent_id) misc
		CROSS APPLY
			(SELECT TOP 1 10 AS Sort1, A.misc2 Sort2, 'Unique MISC2' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				 AND A.misc2 = misc.misc2
				) t
		UNION ALL
		--STEP 11: every variable of MISC3
		SELECT  t.*
		FROM (
			SELECT DISTINCT misc3 FROM ORIGINAL WHERE parent_id=@parent_id) misc
		CROSS APPLY
			(SELECT TOP 1 11 AS Sort1, A.misc3 Sort2, 'Unique MISC3' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				 AND A.misc3 = misc.misc3
				) t
		UNION ALL
		--STEP 12: Any record that was identified as suspect
		SELECT 12 AS Sort1, '' Sort2, 'Suspect Records' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id
			WHERE A.parent_id=@parent_id
				AND (A.salutation = '' OR A.addressee1='' OR A.address1='' OR A.city='' OR A.state='' OR A.zip='')
		--ORDER BY Sort1, Sort2
	END ELSE BEGIN
		--STEP 1: Criteria: Shortest Addressee1, ID, Addressee 1, Last Name, Address 1, MISC1 
		INSERT INTO ##DataIntegrity
		SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Shortest Addressee1, ID, Addressee 1, Last Name, Address 1, MISC1 ' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND LEN(A.addressee1)=(SELECT MIN(LEN(addressee1)) FROM ORIGINAL WHERE parent_id=@parent_id)
		UNION ALL
		--STEP 2: Criteria: Unique RM Code (MV), Unique Appeal, ID, Addressee 1, Last Name, Address 1, MISC1 
		SELECT  t.*
		FROM (
			SELECT DISTINCT rm FROM ORIGINAL 
			WHERE parent_id=@parent_id) RM
		CROSS APPLY
			(SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Unique RM Code (' + A.rm + '), ID, Addressee 1, Last Name, Address 1, Address 2, Last Gift Date, Gift Date, MISC7' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND A.rm = RM.rm 
			) t
		UNION ALL
		--STEP 3: Criteria: Longest Addressee1, ID, Addressee 1, Last Name, Address 1, MISC1
		SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Criteria: Longest Addressee1, ID, Addressee 1, Last Name, Address 1, MISC1 ' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND LEN(A.addressee1)=(SELECT MAX(LEN(addressee1)) FROM ORIGINAL WHERE parent_id=@parent_id)
		UNION ALL
		--STEP 4: Criteria: ID, Addressee 1, Last Name, Address 1, MISC1 
		SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Criteria: ID, Addressee 1, Last Name, Address 1, MISC1 ' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND A.Id > '' AND A.addressee1 > '' AND A.lname > '' AND A.address1 > '' AND A.misc1 > ''
		UNION ALL
		--STEP 5: Criteria: ID, Addressee 1, Last Name, Address 1, Address 2, MISC1 
		SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Criteria: ID, Addressee 1, Last Name, Address 1, Address 2, MISC1 ' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND A.Id>'' AND A.addressee1>'' AND A.lname>'' AND A.address1>'' AND A.address2>'' AND A.misc1>''
		UNION ALL
		--STEP 6: Criteria: ID, Addressee 1, Last Name, Company, Address 1, email, Phone, MISC1 
		SELECT TOP 1 1 AS Sort1, A.rm AS Sort2, 'Criteria: ID, Addressee 1, Last Name, Company, Address 1, email, Phone, MISC1 ' Criteria 
				,A.client_code, A.list, A.id, A.serial, A.importid, A.title, A.fname, A.middle, A.lname, A.suffix, A.salutation, A.addressee1, A.company, A.addressee2
				, B.error_code, B.dupedrop, A.email, A.phone, A.gender, A.address1, A.address2, A.city, A.state, A.zip, A.county, B.delivery_point, A.giftamt, A.giftdate, A.i_giftdate
				, A.totalamt, A.memgifamt, A.memgifdat, A.PLSR_Code, A.CLSR_Code, A.parent_ID, A.child_ID, A.appeal1, A.appeal2, A.appeal3, A.LTRAMT, A.UG1, A.LG
				, A.UG2, A.UG3, A.UG4, '' UG5, '' UG6, A.M1, A.MG, A.M2, A.M3, A.M4, '' M5, '' M6, A.MISC1, A.MISC2, A.MISC3, A.MISC4, A.MISC5, A.MISC6, A.MISC7, A.MISC8, A.MISC9
				, A.rm, A.scanline1, A.scanline2, A.scanline3, A.BC2D1, A.BC2D2, A.BC2D3, A.BC2D4, A.BC2D5, A.BC2D6, A.BC3of9, A.mailtype, A.mailmnth, A.mailpkg
			FROM ORIGINAL A LEFT JOIN NCOA B ON B.FileID=A.FileID AND B.id=A.id 
			WHERE A.parent_id=@parent_id
				AND A.Id>'' AND A.addressee1>'' AND A.lname>'' AND A.company>'' AND A.address1>'' AND A.email>'' AND A.phone>'' AND A.misc1>''
	END

	--reset all
	UPDATE A SET qc_record=CASE WHEN B.id IS NULL THEN 0  ELSE 1 END
	FROM ORIGINAL A LEFT JOIN ##DataIntegrity B ON B.id=A.id
	WHERE A.parent_id=@parent_id
END

SELECT * FROM ##DataIntegrity
ORDER BY Sort1, Sort2

