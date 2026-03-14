CREATE PROCEDURE [dbo].[GetScanlineAskArrayErrors]
(
	@fileID INT
)
AS

--DECLARE @fileID INT
--SET @fileID = 82

SELECT A.*, B.Scanline_Error, C.AskTableCode, C.Recency, C.Frequency, C.Monetary, C.Multiplier, C.Status, C.Message
FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.Parent_ID
	AND CHARINDEX('acquisition',B.AudienceName)=0
	JOIN FileLog F ON F.FileID=A.FileID
	LEFT JOIN AskArray.dbo.AskRuntime C ON C.Id=CAST(A.Original_ID AS VARCHAR(100)) AND C.AskRunId=F.AskRunID
WHERE A.FileID=@fileID
--	AND (COALESCE(AskOptionID,0) = 0
	AND (A.AskOptionID IS NULL OR A.Scanline_Processed=0)

