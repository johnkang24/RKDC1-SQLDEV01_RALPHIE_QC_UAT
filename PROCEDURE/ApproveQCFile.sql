CREATE PROCEDURE [dbo].[ApproveQCFile]
(
	@Parent_ID INT,
	@Username VARCHAR(255)
)
AS

--DECLARE @Parent_ID INT
--SET @Parent_ID = 50957

--STEP 1: update approved fields
UPDATE [ProcessLog]
	SET QC_Approved=1, Approved_Date=GETDATE(), ApprovedBy=@Username
WHERE Parent_ID=@Parent_ID

--STEP 3: check if all QC files for job are approved
DECLARE @fileID INT, @openQC INT

SELECT @fileID=MAX(FileID), @openQC=COUNT(*)
FROM ProcessLog
WHERE QuoteID = (SELECT QuoteID FROM ProcessLog WHERE Parent_ID=@Parent_ID)
	AND FileID IS NOT NULL
	AND QC_Approved<>1

IF @openQC = 0 BEGIN
	--Update WF "Data File QC Complete" task as 100% complete
	EXECUTE [SendUpdatesToWorkfront] @Parent_ID, 'Data File QC Complete', 100

	--call to update all COMS deliverables with delivered qty
	EXECUTE [dbo].[UpdateCOMS_DeliveredQty] @fileID

	--make any other calls here for example calls to create final output files
END

