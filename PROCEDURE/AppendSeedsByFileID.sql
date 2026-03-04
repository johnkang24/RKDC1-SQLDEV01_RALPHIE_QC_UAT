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
	EXECUTE [GetSeedsByAdvJobNo] @AdvJobNo, @DelivrableId

	FETCH NEXT FROM db_appendseeds INTO  @AdvJobNo, @DelivrableId
END

CLOSE db_appendseeds  
DEALLOCATE db_appendseeds



