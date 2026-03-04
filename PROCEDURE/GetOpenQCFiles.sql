CREATE PROCEDURE [dbo].[GetOpenQCFiles]
(
	@process_ID INT
)
AS

SET NOCOUNT ON

DECLARE @is_acquisition BIT, @FileID INT

--TESTING
--DECLARE @process_ID INT
--SET @process_ID = 132105

--JCK:12.10.2025 - adding this so we can correctly distinguish only cult or acq approval
SELECT @FileID=FileID, @is_acquisition=Is_Acquisition FROM ProcessLog WHERE parent_id=@process_ID
PRINT @FileID
PRINT @is_acquisition

--JCK:10.23.2025 - added so if no matching FileID exists it doesn't return no open files (false positive)
DECLARE @match_check INT
SELECT @match_check=COUNT(*)
FROM ProcessLog
WHERE FileID=(SELECT FileID FROM ProcessLog WHERE parent_id=@process_ID)
PRINT @match_check

IF @match_check = 0 BEGIN
	SELECT TOP 1 1 GetOpenQCFiles
	FROM ProcessLog
END ELSE BEGIN

	--SELECT @is_acquisition=MAX(Is_Acquisition)
	--FROM ProcessLog
	--WHERE FileID=@FileID

	SELECT COUNT(*) GetOpenQCFiles
	FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
		AND QC_Approved=0
		AND Is_Acquisition=@is_acquisition
END

