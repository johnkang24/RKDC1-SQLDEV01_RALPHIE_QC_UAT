CREATE PROCEDURE [dbo].[RejectQCFile]
(
	@FileID INT,
	@Username VARCHAR(255)
)
AS

--DECLARE @Parent_ID INT
--SET @Parent_ID = 50957


UPDATE [ProcessLog]
	SET QC_Approved=0, Rejected_Date=GETDATE(), RejectedBy=@Username
WHERE FileID=@FileID

