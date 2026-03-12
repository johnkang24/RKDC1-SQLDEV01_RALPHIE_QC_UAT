CREATE PROCEDURE [dbo].[AppendSeedsByFileID]
(
	@FileID INT
)
AS

DECLARE @AdvJobNo VARCHAR(50), @DelivrableId VARCHAR(50)
DECLARE @testing BIT = 0

DECLARE db_appendseeds CURSOR FOR 
SELECT B.Advantage_Job_ID, Parent_ID
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
WHERE A.FileID=@FileID

OPEN db_appendseeds  
FETCH NEXT FROM db_appendseeds INTO @AdvJobNo, @DelivrableId

WHILE @@FETCH_STATUS = 0  
BEGIN
	--JCK:03.11.2026 - passing 0 for new @RefreshAskArray param to not execute running ask array since that will be called afterwards from MFB
	--EXECUTE [GetSeedsByAdvJobNo] @AdvJobNo, @DelivrableId, 1
	EXECUTE [GetSeedsByAdvJobNo] @AdvJobNo, @DelivrableId, 1, 0

	FETCH NEXT FROM db_appendseeds INTO  @AdvJobNo, @DelivrableId
END

CLOSE db_appendseeds  
DEALLOCATE db_appendseeds



