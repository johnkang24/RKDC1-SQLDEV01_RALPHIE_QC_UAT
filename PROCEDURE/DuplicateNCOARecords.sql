CREATE PROCEDURE DuplicateNCOARecords
(
	@FileID INT, 
	@Files VARCHAR(255)
)
AS

DECLARE @val NVARCHAR(100);

--TESTING
--DECLARE @FileID INT, @Files VARCHAR(100);
--SET @FileID = 154
--SET @Files = '154;155'

DECLARE cur CURSOR FOR
SELECT CAST(value AS INT)
FROM STRING_SPLIT(@Files, ';');

OPEN cur;
FETCH NEXT FROM cur INTO @val;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @val <> @FileID BEGIN
		SELECT @val
		PRINT 'Creating new NCOA records...'
		--UPDATE NCOA SET ParentFileID=@val
		--WHERE ParentFileID=@FileID
		--	AND ID IN (SELECT id FROM ORIGINAL WHERE FileID=@val)
		INSERT INTO NCOA ([FileID]
			,[ParentFileID]
			,[area]
			,[salutation]
			,[company]
			,[addressee1]
			,[addressee2]
			,[address1]
			,[address2]
			,[city]
			,[state]
			,[zip]
			,[id]
			,[title]
			,[fname]
			,[middle]
			,[lname]
			,[suffix]
			,[filetype]
			,[dupedrop]
			,[serial]
			,[move_type]
			,[mv_forward]
			,[mv_effdate]
			,[error_code]
			,[error_description]
			,[duplication_code]
			,[delivery_point])
		SELECT [FileID]
		  ,@val
		  ,[area]
		  ,[salutation]
		  ,[company]
		  ,[addressee1]
		  ,[addressee2]
		  ,[address1]
		  ,[address2]
		  ,[city]
		  ,[state]
		  ,[zip]
		  ,[id]
		  ,[title]
		  ,[fname]
		  ,[middle]
		  ,[lname]
		  ,[suffix]
		  ,[filetype]
		  ,[dupedrop]
		  ,[serial]
		  ,[move_type]
		  ,[mv_forward]
		  ,[mv_effdate]
		  ,[error_code]
		  ,[error_description]
		  ,[duplication_code]
		  ,[delivery_point]
		FROM NCOA
		WHERE ParentFileID=@FileID
			AND id IN (SELECT id FROM ORIGINAL WHERE FileID=@val)
	END
    FETCH NEXT FROM cur INTO @val;
END

CLOSE cur;
DEALLOCATE cur;

