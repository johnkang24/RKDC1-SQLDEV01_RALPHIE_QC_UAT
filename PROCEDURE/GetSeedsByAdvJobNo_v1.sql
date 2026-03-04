CREATE PROCEDURE [dbo].[GetSeedsByAdvJobNo_v1]
(
	@AdvJobNo VARCHAR(50),
	@DelivrableId VARCHAR(50)
)
AS

--TESTING
--DECLARE @AdvJobNo VARCHAR(50)
--SET @AdvJobNo = 78809
--DECLARE @DelivrableId VARCHAR(50)
--SET @DelivrableId = 50963

DECLARE @FILE_ID VARCHAR(50)

-- Ensure the Seeds table exists
IF NOT EXISTS (
    SELECT * FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.Seeds') AND type = 'U'
)
BEGIN
    CREATE TABLE dbo.Seeds (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        AccountId NVARCHAR(50),
		FileId NVARCHAR(50),
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
		Addressee1 NVARCHAR(100),
		Addressee2 NVARCHAR(100),
		Company NVARCHAR(100),
		Appeal1 NVARCHAR(100),
		RM_code NVARCHAR(50),
		scanline1 NVARCHAR(100),
		scanline2 NVARCHAR(100),
		scanline3 NVARCHAR(100),
		bc2d1 NVARCHAR(100),
		bc2d2 NVARCHAR(100),
		bc2d3 NVARCHAR(100),
		bc2d4 NVARCHAR(100),
		bc2d5 NVARCHAR(100),
		bc2d6 NVARCHAR(100),
		bc3of9 NVARCHAR(100),
		address1 NVARCHAR(100),
		address2 NVARCHAR(100),
        Contact_type__c NVARCHAR(100),
        Applicable_Products__c NVARCHAR(MAX),
        Donor_ID__c NVARCHAR(100),
        Number_of_Seeds__c INT,
        Seed__c NVARCHAR(100),
        isSelected BIT
    );
END

DECLARE @SQL NVARCHAR(MAX)
DECLARE @OPENQUERY NVARCHAR(MAX), @TSQL NVARCHAR(MAX), @LinkedServer nvarchar(4000)

SET @LinkedServer = 'COMS_UATSB'

BEGIN

	SET NOCOUNT ON;

    IF OBJECT_ID('tempdb..#AccountIds') IS NOT NULL DROP TABLE #AccountIds;
    IF OBJECT_ID('tempdb..#Contacts') IS NOT NULL DROP TABLE #Contacts;
    IF OBJECT_ID('tempdb..#AccConRel') IS NOT NULL DROP TABLE #AccConRel;

	CREATE TABLE #AccountIds (SBQQ__Account__c NVARCHAR(50));
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

    CREATE TABLE #AccConRel (
        ContactId NVARCHAR(50),
        AccountId NVARCHAR(50),
        Applicable_Products__c NVARCHAR(MAX),
        Donor_ID__c NVARCHAR(100),
        Number_of_Seeds__c INT,
        Seed__c NVARCHAR(100)
    );

    SET @SQL = '
        SELECT SBQQ__Account__c
        FROM OPENQUERY(['+@LinkedServer+'], 
            ''SELECT SBQQ__Account__c 
                FROM SBQQ__Quote__c 
                WHERE Advantage_Job_Code__c = ' + @AdvJobNo + '''
        )';

    INSERT INTO #AccountIds EXEC(@SQL);

    SET @SQL = '
        SELECT Id, AccountId, Salutation, FirstName, MiddleName, LastName, Suffix, Title,
                Email, HasOptedOutOfEmail, Phone, MailingStreet, MailingCity, MailingState,
                MailingPostalCode, MailingCountry, Contact_type__c
        FROM OPENQUERY(['+@LinkedServer+'], 
            ''SELECT Id, AccountId, Salutation, FirstName, MiddleName, LastName, Suffix, Title,
                        Email, HasOptedOutOfEmail, Phone, MailingStreet, MailingCity, MailingState,
                        MailingPostalCode, MailingCountry, Contact_type__c
                FROM Contact''
        )';

    INSERT INTO #Contacts EXEC(@SQL);

    SET @SQL = '
        SELECT ContactId, AccountId, Applicable_Products__c, Donor_ID__c, Number_of_Seeds__c, Seed__c
        FROM OPENQUERY(['+@LinkedServer+'], 
            ''SELECT ContactId, AccountId, Applicable_Products__c, Donor_ID__c, Number_of_Seeds__c, Seed__c
                FROM AccountContactRelation
                WHERE Applicable_Products__c = ''''All'''' ''
        )';

    INSERT INTO #AccConRel EXEC(@SQL);

	DELETE s FROM dbo.Seeds s INNER JOIN #Contacts c ON s.AccountId = c.AccountId;

	select @FILE_ID = FileID from dbo.FileLog where Advantage_Job_ID = @AdvJobNo AND FileType = 'ORIGINAL' AND FileLoaded = 1

    INSERT INTO dbo.Seeds (
		AccountId, FileId, Salutation, FirstName, MiddleName, LastName, Suffix, Title, Email, HasOptedOutOfEmail,
		Phone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
		Addressee1, Addressee2, Company, Appeal1, RM_code,
		scanline1, scanline2, scanline3, bc2d1, bc2d2, bc2d3, bc2d4, bc2d5, bc2d6, bc3of9, address1, address2,
		Contact_type__c, Applicable_Products__c, Donor_ID__c, Number_of_Seeds__c, Seed__c, isSelected
	)
	SELECT 
		c.AccountId, orgn.FileId, c.Salutation, c.FirstName, c.MiddleName, c.LastName, c.Suffix, c.Title, c.Email, 
		c.HasOptedOutOfEmail, c.Phone, c.MailingStreet, c.MailingCity, c.MailingState, 
		c.MailingPostalCode, c.MailingCountry,
		orgn.Addressee1, orgn.Addressee2, orgn.Company, orgn.Appeal1, 'UU',
		orgn.scanline1, orgn.scanline2, orgn.scanline3,
		orgn.bc2d1, orgn.bc2d2, orgn.bc2d3, orgn.bc2d4, orgn.bc2d5, orgn.bc2d6,
		orgn.bc3of9, orgn.address1, orgn.address2,
		c.Contact_type__c, acr.Applicable_Products__c, acr.Donor_ID__c, acr.Number_of_Seeds__c, acr.Seed__c,
		0 AS isSelected
	FROM #Contacts c
	INNER JOIN #AccConRel acr 
		ON c.Id = acr.ContactId AND c.AccountId = acr.AccountId
	INNER JOIN #AccountIds a 
		ON c.AccountId = a.SBQQ__Account__c
	INNER JOIN dbo.original orgn 
		ON c.Email = orgn.Email
	WHERE 1=1
	AND orgn.FileId = @FILE_ID
	AND orgn.parent_id = @DelivrableId
	AND orgn.email IS NOT NULL;

    DROP TABLE #AccountIds;
    DROP TABLE #Contacts;
    DROP TABLE #AccConRel;

	SELECT * FROM dbo.Seeds

END


