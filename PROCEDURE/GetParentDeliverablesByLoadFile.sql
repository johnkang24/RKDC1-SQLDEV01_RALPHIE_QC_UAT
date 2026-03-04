CREATE PROCEDURE [dbo].[GetParentDeliverablesByLoadFile]
(
	@SourceLoadFile VARCHAR(255)
)
AS


SET NOCOUNT ON
--TESTING
--DECLARE @SourceLoadFile VARCHAR(255)
--SET @SourceLoadFile = 'LASPCNOV25_POSORIGINAL.CSV'

DECLARE @FileID INT

SELECT @FileID=MAX(FileID) FROM FileLog
WHERE [FileNamePath] LIKE '%'+@SourceLoadFile+'%'

PRINT @FileID
IF @FileID > 0 BEGIN
	SELECT B.Vertical, B.Client_Code, B.Advantage_Job_ID, C.ProcessLog_Id, C.Mail_Date, A.FileId, A.parent_id
	FROM ORIGINAL A 
		JOIN FileLog B ON B.FileID=A.FileID
		JOIN ProcessLog C ON C.Parent_ID=A.Parent_ID
	WHERE A.FileID=@FileID
	GROUP BY B.Vertical, B.Client_Code, C.ProcessLog_Id, B.Advantage_Job_ID, C.Mail_Date, A.FileId, A.parent_id
	ORDER BY A.FileId, A.parent_id
END

