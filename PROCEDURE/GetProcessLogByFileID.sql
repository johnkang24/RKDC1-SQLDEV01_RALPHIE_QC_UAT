CREATE PROCEDURE [dbo].[GetProcessLogByFileID]
(
	@FileID INT
) AS

--DECLARE @FileID INT
--SET @FileID = 63

DECLARE @is_acquisition BIT
SELECT @is_acquisition=MAX(Is_Acquisition)
FROM ProcessLog
WHERE FileID=@FileID

SELECT B.Advantage_Job_ID, B.Vertical, B.client_code, C.TotalCnt, A.*
FROM ProcessLog A 
	JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	CROSS APPLY
		(
			SELECT parent_ID, COUNT(*) TotalCnt 
			FROM ORIGINAL 
			WHERE FileID=B.FileID
				AND parent_id=A.Parent_ID
			GROUP BY parent_ID
		) C
WHERE A.Is_Acquisition=@is_acquisition

