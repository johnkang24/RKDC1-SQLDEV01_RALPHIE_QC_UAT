--USE [RALPHIE_QC]
--GO
--/****** Object:  StoredProcedure [dbo].[stp_CommaBulkInsert]    Script Date: 9/18/2025 3:00:31 PM ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO

CREATE PROCEDURE [dbo].[stp_CommaBulkInsert]
	@FileID INT,
	@file NVARCHAR(250), 
	@table NVARCHAR(250),
	@ParentFileID INT=0
AS

DECLARE @testing BIT = 0

--/* TESTING!
--DECLARE @file NVARCHAR(250), @table NVARCHAR(250), @FileID INT, @ParentFileID INT
--SET @file = '\\Rkdc1-SQLDEV01\tempdata\RALPHIE\staging\READY TO QC\TEST FILES\ASK ARRAY RESEARCH\TBMNY\NOV25\TBMNYNOV25V2_COMS_POSORIGINAL.CSV'
--SET @table = 'ORIGINAL'
--SET @FileID = 39
--SET @ParentFileID = 0
--SET @testing = 0

BEGIN
	 DECLARE @f NVARCHAR(250), @t NVARCHAR(250), @bcpString NVARCHAR(MAX)
	 DECLARE @errMesage nvarchar(max)
	 DECLARE @SQL NVARCHAR(max)

	IF OBJECT_ID('TempDB..##BulkInsert') IS NOT NULL
	BEGIN
		DROP TABLE ##BulkInsert
	END

	--create temp table
	SET @SQL = 'SELECT TOP 0 * INTO ##BulkInsert FROM '+@table
	EXECUTE sp_executesql @SQL 

	--remove FileID column
	SET @SQL = 'ALTER TABLE ##BulkInsert DROP COLUMN FileID'
	EXECUTE sp_executesql @SQL

	IF @table='ORIGINAL' BEGIN
		--remove columns
		SET @SQL = 'ALTER TABLE ##BulkInsert DROP COLUMN Original_ID, dpv, ug5, ug6, m5, m6, qc_record, IsSeed, Sourcecode1, Sourcecode2, Sourcecode3, Sourcecode4, Scanline_Processed, AskOptionID'
		EXECUTE sp_executesql @SQL
		--CREATE TABLE ##BulkInsert (
		--	[client_code] [varchar](20) NULL,
		--	[id] [varchar](30) NULL,
		--	[salutation] [varchar](255) NULL,
		--	[company] [varchar](255) NULL,
		--	[addressee1] [varchar](255) NULL,
		--	[addressee2] [varchar](255) NULL,
		--	[gender] [varchar](50) NULL,
		--	[title] [varchar](255) NULL,
		--	[fname] [varchar](255) NULL,
		--	[middle] [varchar](255) NULL,
		--	[lname] [varchar](255) NULL,
		--	[suffix] [varchar](255) NULL,
		--	[email] [varchar](99) NULL,
		--	[phone] [varchar](50) NULL,
		--	[address1] [varchar](255) NULL,
		--	[address2] [varchar](255) NULL,
		--	[city] [varchar](50) NULL,
		--	[state] [varchar](30) NULL,
		--	[zip] [varchar](50) NULL,
		--	[dpv] [varchar](50) NULL,
		--	[giftdate] [varchar](50) NULL,
		--	[giftamt] [varchar](50) NULL,
		--	[i_giftdate] [varchar](50) NULL,
		--	[totalamt] [varchar](50) NULL,
		--	[memgifamt] [varchar](50) NULL,
		--	[memgifdat] [varchar](12) NULL,
		--	[rm] [varchar](50) NULL,
		--	[list] [varchar](50) NULL,
		--	[parent_id] [varchar](50) NULL,
		--	[child_id] [varchar](50) NULL,
		--	[PLSR_Code] [varchar](50) NULL,
		--	[CLSR_Code] [varchar](50) NULL,
		--	[mailtype] [varchar](50) NULL,
		--	[mailmnth] [varchar](50) NULL,
		--	[mailpkg] [varchar](50) NULL,
		--	[ltramt] [varchar](50) NULL,
		--	[ug1] [varchar](50) NULL,
		--	[lg] [varchar](50) NULL,
		--	[ug2] [varchar](50) NULL,
		--	[ug3] [varchar](50) NULL,
		--	[ug4] [varchar](50) NULL,
		--	[ug5] [varchar](50) NULL,
		--	[ug6] [varchar](50) NULL,
		--	[m1] [varchar](50) NULL,
		--	[mg] [varchar](50) NULL,
		--	[m2] [varchar](50) NULL,
		--	[m3] [varchar](50) NULL,
		--	[m4] [varchar](50) NULL,
		--	[m5] [varchar](50) NULL,
		--	[m6] [varchar](50) NULL,
		--	[appeal1] [varchar](50) NULL,
		--	[appeal2] [varchar](50) NULL,
		--	[appeal3] [varchar](50) NULL,
		--	[scanline1] [varchar](50) NULL,
		--	[scanline2] [varchar](50) NULL,
		--	[scanline3] [varchar](50) NULL,
		--	[bc2d1] [varchar](50) NULL,
		--	[bc2d2] [varchar](50) NULL,
		--	[bc2d3] [varchar](50) NULL,
		--	[bc2d4] [varchar](50) NULL,
		--	[bc2d5] [varchar](50) NULL,
		--	[bc2d6] [varchar](50) NULL,
		--	[bc3of9] [varchar](50) NULL,
		--	[misc1] [varchar](50) NULL,
		--	[misc2] [varchar](50) NULL,
		--	[misc3] [varchar](50) NULL,
		--	[misc4] [varchar](50) NULL,
		--	[misc5] [varchar](50) NULL,
		--	[misc6] [varchar](50) NULL,
		--	[misc7] [varchar](50) NULL,
		--	[misc8] [varchar](50) NULL,
		--	[misc9] [varchar](50) NULL,
		--	[county] [varchar](50) NULL,
		--	[stitle] [varchar](255) NULL,
		--	[sfname] [varchar](255) NULL,
		--	[smiddle] [varchar](255) NULL,
		--	[slname] [varchar](255) NULL,
		--	[ssuffix] [varchar](255) NULL,
		--	[importid] [varchar](50) NULL,
		--	[solcode1] [varchar](255) NULL,
		--	[solcode2] [varchar](255) NULL,
		--	[solcode3] [varchar](255) NULL,
		--	[multi_flg] [varchar](50) NULL,
		--	[filetype] [varchar](50) NULL,
		--	[endorsement] [varchar](50) NULL,
		--	[ws] [varchar](50) NULL,
		--	[cr_sequence] [varchar](50) NULL,
		--	[cr_id] [varchar](50) NULL,
		--	[income] [varchar](50) NULL,
		--	[dupedrop] [varchar](20) NULL,
		--	[serial] [varchar](50) NULL,
		--	[last_giftamt] [varchar](50) NULL,
		--	[largest_giftamt] [varchar](50) NULL
		--	)
	END
	IF @table='NCOA' BEGIN
		--remove ParentFileID column
		SET @SQL = 'ALTER TABLE ##BulkInsert DROP COLUMN ParentFileID'
		EXECUTE sp_executesql @SQL 
	END

	SET @errMesage = ''
	SET @f = @file
	SET @t = @table
 
	IF @testing=1 BEGIN
		SELECT * FROM ##BulkInsert
	END

	 SET @bcpString = N'BULK INSERT ##BulkInsert
	  FROM ''' + @f + '''
	  WITH (
	   FIELDTERMINATOR = '',''
	   ,ROWTERMINATOR = ''0x0a''
	   ,FIRSTROW=2
	   ,FORMAT=''CSV''
	  )'
 
	SELECT @bcpString
 	BEGIN TRY
		EXEC sp_executesql @bcpString
	END TRY
	BEGIN CATCH
		PRINT @bcpString
	    SET @errMesage  = ERROR_MESSAGE()
		RAISERROR(@errMesage, 16, 0)
	END CATCH

	IF @table='ORIGINAL' BEGIN
		--clear any $ character
		UPDATE ##BulkInsert
			SET LTRAMT=REPLACE(LTRAMT,'$','')
				,UG1=REPLACE(UG1,'$','')
				,LG=REPLACE(LG,'$','')
				,UG2=REPLACE(UG2,'$','')
				,UG3=REPLACE(UG3,'$','')
				,UG4=REPLACE(UG4,'$','')
				,M1=REPLACE(M1,'$','')
				,MG=REPLACE(MG,'$','')
				,M2=REPLACE(M2,'$','')
				,M3=REPLACE(M3,'$','')
				,M4=REPLACE(M4,'$','')

		--JCK:11.03.2025 - remove any previous data loaded for the same parent_Id
		DELETE ORIGINAL
		WHERE parent_id IN (SELECT DISTINCT parent_id FROM ##BulkInsert)
			AND FileID<>@FileID
	END

	IF @testing = 1 BEGIN
		SELECT * FROM ##BulkInsert
	END ELSE BEGIN
		--delete any matching prior loads if any
		SET @SQL = 'DELETE ' + @table + ' WHERE FileID=' + CONVERT(VARCHAR(100),@FileID)
		EXECUTE sp_executesql @SQL 

		--copy data into respective table
		IF @table='NCOA' BEGIN
			SET @SQL = 'INSERT INTO ' + @table + ' SELECT ' + CONVERT(VARCHAR(100),@FileID) + ' FileID, '  + CONVERT(VARCHAR(100),@ParentFileID) + ' ParentFileID, * FROM ##BulkInsert'
		END ELSE BEGIN
			--SET @SQL = @SQL + 'INSERT INTO ' + @table + ' SELECT ' + CONVERT(VARCHAR(100),@FileID) + ' FileID, *, 0 IsSeed  FROM ##BulkInsert'
			SET @SQL = 'INSERT INTO ' + @table + '(FileID,
					Client_Code,ID,salutation,Company,Addressee1,Addressee2,Gender,title,fname,MIDDLE,lname,suffix,EMAIL,PHONE,Address1,address2,City,State,Zip,GiftDate,GiftAmt,I_GiftDate,
					TotalAmt,MemGifAmt,MemGifDat,RM,LIST,Parent_ID,Child_ID,PLSR_Code,CLSR_Code,MAILTYPE,MAILMNTH,MAILPKG,LTRAMT,UG1,LG,UG2,UG3,UG4,M1,MG,M2,M3,M4,
					APPEAL1,APPEAL2,APPEAL3,SCANLINE1,SCANLINE2,SCANLINE3,BC2D1,BC2D2,BC2D3,BC2D4,BC2D5,BC2D6,BC3OF9,MISC1,MISC2,MISC3,MISC4,MISC5,MISC6,MISC7,MISC8,MISC9,
					county,STITLE,SFNAME,SMIDDLE,SLNAME,SSUFFIX,IMPORTID,SOLCODE1,SOLCODE2,SOLCODE3,MULTI_FLG,filetype,Endorsement,WS,cr_sequence,CR_ID,Income,dupedrop,serial,
					last_giftamt, largest_giftamt,
					IsSeed) SELECT ' + CONVERT(VARCHAR(100),@FileID) + ' FileID,
					Client_Code,ID,salutation,Company,Addressee1,Addressee2,Gender,title,fname,MIDDLE,lname,suffix,EMAIL,PHONE,Address1,address2,City,State,Zip,GiftDate,GiftAmt,I_GiftDate,
					TotalAmt,MemGifAmt,MemGifDat,RM,LIST,Parent_ID,Child_ID,PLSR_Code,CLSR_Code,MAILTYPE,MAILMNTH,MAILPKG,LTRAMT,UG1,LG,UG2,UG3,UG4,M1,MG,M2,M3,M4,
					APPEAL1,APPEAL2,APPEAL3,SCANLINE1,SCANLINE2,SCANLINE3,BC2D1,BC2D2,BC2D3,BC2D4,BC2D5,BC2D6,BC3OF9,MISC1,MISC2,MISC3,MISC4,MISC5,MISC6,MISC7,MISC8,MISC9,
					county,STITLE,SFNAME,SMIDDLE,SLNAME,SSUFFIX,IMPORTID,SOLCODE1,SOLCODE2,SOLCODE3,MULTI_FLG,filetype,Endorsement,WS,cr_sequence,CR_ID,Income,dupedrop,serial,
					last_giftamt, largest_giftamt,
					0 IsSeed
					FROM ##BulkInsert'
		END
		print @sql
		EXECUTE sp_executesql @SQL 
	END
END


