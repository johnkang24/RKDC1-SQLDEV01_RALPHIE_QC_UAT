CREATE PROCEDURE [dbo].[GetProcessLogByParentID]
(
	@ParentID INT
) AS

--DECLARE @ParentID INT
--SET @ParentID = 73709

SELECT B.Vertical, B.client_code, B.Advantage_Job_ID, A.Delivered_Qty TotalCnt, A.*
FROM ProcessLog A 
	JOIN FileLog B ON B.FileID=A.FileID
	JOIN (SELECT parent_ID, COUNT(*) TotalCnt FROM ORIGINAL WHERE parent_id=@ParentID GROUP BY parent_ID) C ON C.parent_id=A.Parent_ID
WHERE A.Parent_ID=@ParentID

