CREATE PROCEDURE [dbo].[GetMergeDupsByFileID]
(
	@FileID VARCHAR(50)
)
AS

SET NOCOUNT ON

--TESTING
--DECLARE @FileID VARCHAR(50)
--SET @FileID = 50

DECLARE @is_acquisition BIT
SELECT @is_acquisition=MAX(Is_Acquisition)
FROM ProcessLog
WHERE FileID=@FileID
	AND QC_Approved=1
	AND Is_Acquisition=0
PRINT @is_acquisition

IF @is_acquisition=0 BEGIN
	SELECT A.Duplication_Code, 
		area Client_Code,
		MIN(B.[mailtype]) Mail_Type,
		A.ID,
		B.[giftdate] Gift_Date,
		B.[giftamt] Gift_Amount,
		A.[lname] Last_Name,
		A.Salutation,
		A.Company,
		A.Addressee1,
		A.Addressee2,
		A.Address1,
		A.Address2,
		A.City,
		A.State,
		A.Zip
	FROM NCOA A
		JOIN ORIGINAL B ON B.id=A.id
		JOIN FileLog C ON C.FileID=A.FileID AND C.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	WHERE A.[duplication_code] IN (
		SELECT [duplication_code]
		FROM (SELECT id, [duplication_code], COUNT(*) CNT
			FROM NCOA A
				JOIN FileLog C ON C.FileID=A.FileID AND C.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
			GROUP BY Id, [duplication_code]) A
		GROUP BY [duplication_code]
		HAVING COUNT(*)>1)
	GROUP BY A.Duplication_Code, 
		area,
		A.ID,
		B.[giftdate],
		B.[giftamt],
		A.[lname],
		A.Salutation,
		A.Company,
		A.Addressee1,
		A.Addressee2,
		A.Address1,
		A.Address2,
		A.City,
		A.State,
		A.Zip
	ORDER BY A.[duplication_code]
END ELSE BEGIN
	SELECT TOP 0 *
	FROM NCOA
END

