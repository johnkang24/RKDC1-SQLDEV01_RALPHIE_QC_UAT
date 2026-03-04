CREATE PROCEDURE [dbo].[GeneratePromoHarvesterFiles]
(
	@AdvJobNo INT,
	@outputPath VARCHAR(500)
)
AS

DECLARE @parentID VARCHAR(50)
DECLARE @testing BIT = 0

DECLARE db_cursor CURSOR FOR 
SELECT Parent_ID
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=@AdvJobNo

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @parentID

WHILE @@FETCH_STATUS = 0  
BEGIN
	EXECUTE [GeneratePromoHarvesterFile] @parentID, @outputPath

	FETCH NEXT FROM db_cursor INTO  @parentID
END

CLOSE db_cursor  
DEALLOCATE db_cursor



