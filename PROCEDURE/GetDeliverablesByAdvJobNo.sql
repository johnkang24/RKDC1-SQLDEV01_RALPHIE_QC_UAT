CREATE PROCEDURE [dbo].[GetDeliverablesByAdvJobNo]
(
	@AdvJobNo VARCHAR(50)
)
AS

DECLARE @deliverables VARCHAR(8000) 

--TESTING
--DECLARE @fileID INT
--SET @fileID = 34

SELECT @deliverables = COALESCE(@deliverables + '_','') + parent_id
FROM (
	SELECT A.parent_id
	FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
		JOIN FileLog C ON C.FileID=A.FileID AND C.Advantage_Job_ID=@AdvJobNo
	UNION 
	SELECT child_id
	FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
		JOIN FileLog C ON C.FileID=A.FileID AND C.Advantage_Job_ID=@AdvJobNo
	WHERE child_id IS NOT NULL) A
ORDER BY parent_id

SELECT Client_Name, ScheduleBlock_Name, Advantage_Job_ID, Client_Code
	,Deliverables=@deliverables, MIN(B.mail_date) Mail_Date
FROM FileLog A JOIN ProcessLog B ON B.FileID=A.FileID
WHERE Advantage_Job_ID=@AdvJobNo
	AND FileType='ORIGINAL'
GROUP BY Client_Name, ScheduleBlock_Name, Advantage_Job_ID, Client_Code

