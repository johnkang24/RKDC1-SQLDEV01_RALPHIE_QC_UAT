CREATE PROCEDURE [dbo].[GetAppealTracking]
(
	--@AdvanJobNum INT
	@FileID INT
)
AS

SET NOCOUNT ON;

--TESTING
--DECLARE @FileID INT
--SET @FileID = 50

--DECLARE @is_acquisition BIT
--SELECT @is_acquisition=MAX(Is_Acquisition)
--FROM ProcessLog
--WHERE FileID=@FileID

--JCK:11.03.2025 - create only one file regardless of cult or acq packages within the same job
DECLARE @tot_open INT
SELECT @tot_open=COUNT(*)
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
WHERE B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	AND A.QC_Approved=0
PRINT @tot_open

IF @tot_open=0 BEGIN
	SELECT B.Client_Name, B.ScheduleBlock_Name, A.Job_Name, A.Mail_Date, B.Advantage_Job_ID
		,B.Client_Code, A.AudienceName, A.CreativeName, A.Parent_ID
		,dbo.[udf_GetRMDescription](C.RM) RM_Description
		,C.appeal1, C.RM, C.appeal1+' '+C.rm Keyline 
		,C.TotalCount
	FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID
		JOIN (SELECT Parent_ID, APPEAL1, RM, COUNT(*) TotalCount
			FROM ORIGINAL A JOIN FileLog B ON B.FileID=A.FileID
			WHERE B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
			GROUP BY Parent_ID, APPEAL1, RM) C ON C.parent_id=A.Parent_ID
	WHERE B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
		--AND Is_Acquisition=@is_acquisition
	ORDER BY A.Parent_ID, C.RM, C.appeal1
END ELSE BEGIN
	SELECT TOP 0 * FROM ProcessLog
END

