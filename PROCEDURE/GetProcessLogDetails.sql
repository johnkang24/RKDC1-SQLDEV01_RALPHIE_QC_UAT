CREATE PROCEDURE [dbo].[GetProcessLogDetails]
(
	@Parent_ID INT
)
AS

--DECLARE @Parent_ID INT
--SET @Parent_ID = 50957


SELECT B.[Client_Code], B.Advantage_Job_ID, A.*
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
WHERE A.Parent_ID=@Parent_ID

