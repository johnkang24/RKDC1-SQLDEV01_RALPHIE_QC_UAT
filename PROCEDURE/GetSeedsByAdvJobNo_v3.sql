
CREATE PROCEDURE [dbo].[GetSeedsByAdvJobNo]
(
	@AdvJobNo VARCHAR(50),
	@DelivrableId VARCHAR(50),
	@ResetSeeds BIT = 1
)
AS

DECLARE @testing BIT = 0

SET NOCOUNT ON;
	
--TESTING
--DECLARE @AdvJobNo VARCHAR(50), @DelivrableId VARCHAR(50), @ResetSeeds BIT
--SET @AdvJobNo = '98045'
--SET @DelivrableId = '132148'	--50963 50957
--SET @ResetSeeds = 1
--SET @testing = 1


DECLARE @FILE_ID VARCHAR(50)
DECLARE @ACC_ID VARCHAR(50)

DECLARE @CLIENT_CODE VARCHAR(50)
DECLARE @VERTICAL VARCHAR(50)

SELECT @FILE_ID = A.FileID, @ACC_ID = A.AccountId, @CLIENT_CODE = A.Client_Code, @VERTICAL = A.Vertical 
FROM dbo.FileLog A JOIN ProcessLog B ON B.FileID=A.FileID AND B.Parent_ID=@DelivrableId
WHERE Advantage_Job_ID = @AdvJobNo 
	AND FileType = 'ORIGINAL' 
	AND FileLoaded = 1;

IF @testing=1 BEGIN
	PRINT @FILE_ID
	PRINT @ACC_ID
	PRINT @CLIENT_CODE
	PRINT @VERTICAL
END

IF @ResetSeeds=1 BEGIN
	-- Ensure the SeedsSelection table exists
	IF NOT EXISTS (
		SELECT * FROM sys.objects
		WHERE object_id = OBJECT_ID(N'dbo.SeedsSelection') AND type = 'U'
	)
	BEGIN
		CREATE TABLE dbo.SeedsSelection (
			Id INT IDENTITY(1,1) PRIMARY KEY,
			AccountId NVARCHAR(50),
			FileId NVARCHAR(50),
			Original_ID INT,
			Contact_type__c NVARCHAR(100),
			Products NVARCHAR(MAX),
			SB_Seed_List__c NVARCHAR(MAX),
			SB_Replicate__c NVARCHAR(10),
			country NVARCHAR(100),
			HasOptedOutOfEmail BIT,
			isSelected BIT DEFAULT 1
		);
	END

	DECLARE @SQL NVARCHAR(MAX)
	DECLARE @OPENQUERY NVARCHAR(MAX), @TSQL NVARCHAR(MAX), @LinkedServer nvarchar(4000)

	SET @LinkedServer = 'COMS_UATSB'

	BEGIN

		SET NOCOUNT ON;

		IF OBJECT_ID('tempdb..#Contacts') IS NOT NULL DROP TABLE #Contacts;
		IF OBJECT_ID('tempdb..#SeedObj') IS NOT NULL DROP TABLE #SeedObj;

		CREATE TABLE #Contacts (
			Id NVARCHAR(50),
			AccountId NVARCHAR(50),
			Salutation NVARCHAR(20),
			FirstName NVARCHAR(100),
			MiddleName NVARCHAR(100),
			LastName NVARCHAR(100),
			Suffix NVARCHAR(20),
			Title NVARCHAR(100),
			Email NVARCHAR(255),
			HasOptedOutOfEmail BIT,
			Phone NVARCHAR(50),
			MailingStreet NVARCHAR(255),
			MailingCity NVARCHAR(100),
			MailingState NVARCHAR(100),
			MailingPostalCode NVARCHAR(20),
			MailingCountry NVARCHAR(100),
			Contact_type__c NVARCHAR(100)
		);

		CREATE TABLE #SeedObj (
			SB_Contact__c NVARCHAR(50),
			SB_Account__c NVARCHAR(50),
			SB_Seed_Type__c NVARCHAR(MAX),
			SB_Donor_Id__c NVARCHAR(100),
			SB_Replicate__c NVARCHAR(10),
			SB_Seed_List__c NVARCHAR(100),
			SB_Salutation__c NVARCHAR(100),
			SB_First_Pseudonym__c NVARCHAR(100),
			SB_Last_Pseudonym__c NVARCHAR(100),
			SB_RM_Code__c NVARCHAR(100)
		);


		SET @SQL = '
			SELECT Id, AccountId, Salutation, FirstName, MiddleName, LastName, Suffix, Title,
					Email, HasOptedOutOfEmail, Phone, MailingStreet, MailingCity, MailingState,
					MailingPostalCode, MailingCountry, Contact_type__c
			FROM OPENQUERY([' + @LinkedServer + '], 
				''' + 
				'SELECT Id, AccountId, Salutation, FirstName, MiddleName, LastName, Suffix, Title, ' +
				'Email, HasOptedOutOfEmail, Phone, MailingStreet, MailingCity, MailingState, ' +
				'MailingPostalCode, MailingCountry, Contact_type__c ' +
				'FROM Contact where SB_Seed_Eligible__c = true AND AccountId = ''''' + @ACC_ID + '''''' +
				''')';

		INSERT INTO #Contacts EXEC(@SQL);
		IF @testing=1 BEGIN
			PRINT @SQL
			SELECT * FROM #Contacts
		END

		SET @SQL = '
			SELECT SB_Contact__c, SB_Account__c, SB_Seed_Type__c, SB_Donor_Id__c, SB_Replicate__c, SB_Seed_List__c, SB_Salutation__c, SB_First_Pseudonym__c, SB_Last_Pseudonym__c, SB_RM_Code__c
			FROM OPENQUERY([' + @LinkedServer + '], 
				''SELECT SB_Contact__c, SB_Account__c, SB_Seed_Type__c, SB_Donor_Id__c, SB_Replicate__c, SB_Seed_List__c, SB_Salutation__c, SB_First_Pseudonym__c, SB_Last_Pseudonym__c, SB_RM_Code__c
				FROM Seed__c
				WHERE SB_Active__c = true AND (SB_VERTICAL__c = ''''' + REPLACE(@VERTICAL, '''', '''''') + ''''' OR SB_Account__c = ''''' + REPLACE(@ACC_ID, '''', '''''') + ''''')'')';


		INSERT INTO #SeedObj EXEC(@SQL);
		IF @testing=1 BEGIN
			PRINT @SQL
			SELECT * FROM #SeedObj
		END

		DECLARE @appeal1 AS VARCHAR(50)
		SELECT TOP 1 @appeal1=appeal1 FROM ORIGINAL
		WHERE parent_id=@DelivrableId AND child_id IS NULL

		-- -- Delete from dbo.original
		IF @testing=0 BEGIN
			DELETE s FROM dbo.ORIGINAL s INNER JOIN #SeedObj c ON s.id = c.SB_Donor_Id__c
			WHERE parent_id=@DelivrableId;
		END

		--JCK:11.07.2025 - need to make serial unique
		DECLARE @max_serial INT
		SELECT @max_serial=COALESCE(MAX(serial),0) FROM ORIGINAL WHERE FileID=@FILE_ID AND IsSeed=0

		IF @testing=1 BEGIN
			PRINT @max_serial
			SELECT 
				@FILE_ID, @CLIENT_CODE, acr.SB_Donor_Id__c, acr.SB_Salutation__c, NULL, acr.SB_First_Pseudonym__c, acr.SB_Last_Pseudonym__c, NULL, NULL, 
					--CASE 
					--	WHEN acr.SB_First_Pseudonym__c IS NULL OR LTRIM(RTRIM(acr.SB_First_Pseudonym__c)) = '' 
					--		THEN c.FirstName 
					--	ELSE acr.SB_First_Pseudonym__c 
					--END,
				c.FirstName,
				c.MiddleName as middle,
				--CASE 
				--	WHEN acr.SB_Last_Pseudonym__c IS NULL OR LTRIM(RTRIM(acr.SB_Last_Pseudonym__c)) = '' 
				--		THEN c.LastName 
				--	ELSE acr.SB_Last_Pseudonym__c 
				--END,
				c.LastName,
				c.Suffix, c.Email, c.Phone, c.MailingStreet, NULL, c.MailingCity, c.MailingState, c.MailingPostalCode, NULL, NULL, NULL, NULL, NULL, NULL, COALESCE(acr.SB_RM_Code__c,'UU'), NULL, @DelivrableId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @appeal1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'S_'+CAST(@max_serial+ROW_NUMBER() OVER (ORDER BY acr.SB_Donor_Id__c) AS VARCHAR(1000))+'_'+@DelivrableId, 1
			FROM #Contacts c
			INNER JOIN #SeedObj acr 
				ON c.Id = acr.SB_Contact__c AND c.AccountId = acr.SB_Account__c
			WHERE c.AccountId = @ACC_ID;
		END ELSE BEGIN
			-- Insert into dbo.ORIGINAL table
			INSERT INTO dbo.ORIGINAL(
				[FileID], [client_code], [id], [salutation], [company], [addressee1], [addressee2], [gender], [title], [fname], [middle], [lname], [suffix], [email], [phone], [address1], [address2], [city], [state], [zip], [giftdate], [giftamt], [i_giftdate], [totalamt], [memgifamt], [memgifdat], [rm], [list], [parent_id], [child_id], [PLSR_Code], [CLSR_Code], [mailtype], [mailmnth], [mailpkg], [ltramt], [ug1], [lg], [ug2], [ug3], [ug4], [m1], [mg], [m2], [m3], [m4], [appeal1], [appeal2], [appeal3], [scanline1], [scanline2], [scanline3], [bc2d1], [bc2d2], [bc2d3], [bc2d4], [bc2d5], [bc2d6], [bc3of9], [misc1], [misc2], [misc3], [misc4], [misc5], [misc6], [misc7], [misc8], [misc9], [county], [stitle], [sfname], [smiddle], [slname], [ssuffix], [importid], [solcode1], [solcode2], [solcode3], [multi_flg], [filetype], [endorsement], [ws], [cr_sequence], [cr_id], [income], [dupedrop], [serial], [IsSeed]
			)
			SELECT
				--JCK:02.25.2026
				--@FILE_ID, @CLIENT_CODE, acr.SB_Donor_Id__c, c.Salutation, NULL, COALESCE(c.Salutation,'')+' '+c.LastName, NULL, NULL, NULL, 
				@FILE_ID, @CLIENT_CODE, acr.SB_Donor_Id__c, acr.SB_Salutation__c, NULL, acr.SB_First_Pseudonym__c, acr.SB_Last_Pseudonym__c, NULL, NULL, 
					--CASE 
					--	WHEN acr.SB_First_Pseudonym__c IS NULL OR LTRIM(RTRIM(acr.SB_First_Pseudonym__c)) = '' 
					--		THEN c.FirstName 
					--	ELSE acr.SB_First_Pseudonym__c 
					--END,
					c.FirstName,
				c.MiddleName as middle,
				--CASE 
				--	WHEN acr.SB_Last_Pseudonym__c IS NULL OR LTRIM(RTRIM(acr.SB_Last_Pseudonym__c)) = '' 
				--		THEN c.LastName 
				--	ELSE acr.SB_Last_Pseudonym__c 
				--END,
				c.LastName,
				c.Suffix, c.Email, c.Phone, c.MailingStreet, NULL, c.MailingCity, c.MailingState, c.MailingPostalCode, NULL, NULL, NULL, NULL, NULL, NULL, COALESCE(acr.SB_RM_Code__c,'UU'), NULL, @DelivrableId, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, @appeal1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'S_'+CAST(@max_serial+ROW_NUMBER() OVER (ORDER BY acr.SB_Donor_Id__c) AS VARCHAR(1000))+'_'+@DelivrableId, 1
			FROM #Contacts c
			INNER JOIN #SeedObj acr 
				ON c.Id = acr.SB_Contact__c AND c.AccountId = acr.SB_Account__c
			WHERE c.AccountId = @ACC_ID;

			--JCK: 11:07.2025 - build scanline for new seeds (or any others with Scanline_Processed=0)
			EXEC BuildScanline @FILE_ID, 1
			DECLARE @status BIT
			EXEC RefreshAskArrayByFile @FILE_ID, 0, 1, @status OUTPUT

			--DELETE s FROM dbo.SeedsSelection s INNER JOIN dbo.ORIGINAL o ON s.AccountId = o.id AND o.parent_id=@DelivrableId;
			DELETE s FROM dbo.SeedsSelection s INNER JOIN dbo.ORIGINAL o ON s.Original_ID=o.Original_ID AND o.FileID=@FILE_ID AND o.parent_id = @DelivrableId

			INSERT INTO dbo.SeedsSelection (AccountId, FileId, Original_ID, Contact_type__c, Products, SB_Seed_List__c, SB_Replicate__c, country, HasOptedOutOfEmail, isSelected)
				SELECT o.id, @FILE_ID, o.Original_ID, c.Contact_type__c, acr.SB_Seed_Type__c, acr.SB_Seed_List__c, acr.SB_Replicate__c, c.MailingCountry, c.HasOptedOutOfEmail, 1
				FROM dbo.ORIGINAL o
				JOIN #SeedObj acr ON o.id = acr.SB_Donor_Id__c
				JOIN #Contacts c ON c.Id = acr.SB_Contact__c AND c.AccountId = acr.SB_Account__c
				WHERE o.FileID = @FILE_ID AND o.parent_id = @DelivrableId AND o.IsSeed = 1;

			DROP TABLE #Contacts;
			DROP TABLE #SeedObj;
			-- DROP TABLE dbo.SeedsSelection;

			--09.18.2025 --update new field
			UPDATE ProcessLog
				SET Seed_Processed=1
			WHERE FileID=@FILE_ID AND Parent_ID=@DelivrableId
		END

		IF @testing=1 BEGIN
			--PRINT @SQL
			SELECT * FROM dbo.SeedsSelection
			WHERE AccountId=@ACC_ID
		END
	END

END

IF @testing=1 BEGIN
	PRINT @FILE_ID
	PRINT @DelivrableId
END ELSE BEGIN
	SELECT *
	FROM dbo.ORIGINAL o
	JOIN dbo.SeedsSelection ss ON o.Original_ID = ss.Original_ID
	--WHERE o.FileID = @FILE_ID AND o.parent_id = @AdvJobNo AND o.child_id = @DelivrableId AND o.IsSeed = 1;
	WHERE o.FileID = @FILE_ID 
	AND o.parent_id = @DelivrableId 
	--AND o.child_id = @DelivrableId 
	AND o.IsSeed = 1;
END
