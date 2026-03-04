CREATE PROCEDURE [dbo].[GetSeeds]
(
	@ParentID INT
)
AS

	SELECT TOP 0 *
	FROM dbo.ORIGINAL o
	WHERE o.parent_id = @ParentID 
	AND o.IsSeed = 1;

