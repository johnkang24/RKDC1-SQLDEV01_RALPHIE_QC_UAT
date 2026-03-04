CREATE PROCEDURE [dbo].[GetDeliverablesByFileID]
(
	@fileID INT
)
AS

DECLARE @deliverables VARCHAR(8000) 

--TESTING
--DECLARE @fileID INT
--SET @fileID = 50

DECLARE @is_acquisition BIT = 0
--SELECT @is_acquisition=MAX(Is_Acquisition)
--FROM ProcessLog
--WHERE FileID=@FileID
--	AND QC_Approved=1
--	AND Is_Acquisition=0

SELECT @deliverables = COALESCE(@deliverables + '_','') + parent_id
FROM (
	SELECT A.parent_id
	FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.parent_id AND B.Is_Acquisition=@is_acquisition
		JOIN FileLog C ON C.FileID=A.FileID AND Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	UNION 
	SELECT child_id
	FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.parent_id AND B.Is_Acquisition=@is_acquisition
		JOIN FileLog C ON C.FileID=A.FileID AND Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	WHERE child_id IS NOT NULL) A
ORDER BY parent_id

--SELECT @deliverables

SELECT Client_Name, ScheduleBlock_Name, Advantage_Job_ID, Client_Code
	,Deliverables=@deliverables, MIN(B.mail_date) Mail_Date
FROM FileLog A JOIN ProcessLog B ON B.FileID=A.FileID AND B.Is_Acquisition=@is_acquisition
WHERE Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
	AND FileType='ORIGINAL'
GROUP BY Client_Name, ScheduleBlock_Name, Advantage_Job_ID, Client_Code

