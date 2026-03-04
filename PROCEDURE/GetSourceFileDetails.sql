CREATE PROCEDURE [dbo].[GetSourceFileDetails]
	(@FileToLoad VARCHAR(255))
AS
SELECT TOP 1 *
FROM [FileLog]
WHERE [FileNamePath]=@FileToLoad
ORDER BY FileID DESC

