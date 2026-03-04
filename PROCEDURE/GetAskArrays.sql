CREATE PROCEDURE [dbo].[GetAskArrays]
(
	@parent_id INT
)
AS

--TESTING
--DECLARE @parent_id INT
--SET @parent_id = 135942

SET NOCOUNT ON

DECLARE @Vertical VARCHAR(50)
SELECT @Vertical=Vertical
FROM FileLog A JOIN ProcessLog B ON B.FileID=a.FileID
	AND B.Parent_ID=@parent_id
PRINT @Vertical

SELECT 
	--giftamt
	CASE WHEN @Vertical='Missions' THEN ROUND([last_giftamt],2) ELSE ROUND([giftamt],2) END giftamt
	,rm 
	, dbo.udf_GetDonorType(rm) Donor_Type
      ,MAX([ug1]) [ug1]
      ,MAX([lg]) [lg]
      ,MAX([ug2]) [ug2]
      ,MAX([ug3]) [ug3]
      ,MAX([ug4]) [ug4]
      ,MAX([ug5]) [ug5]
	  ,MAX([ltramt]) [ltramt]
	  ,MAX(m1) m1
	  ,MAX(mg) mg
	  ,MAX(m2) m2
	  ,MAX(m3) m3
	  ,MAX(m4) m4
	  ,MAX(m5) m5
FROM [ORIGINAL]
WHERE parent_id=@parent_id
GROUP BY 
	--giftamt
	CASE WHEN @Vertical='Missions' THEN ROUND([last_giftamt],2) ELSE ROUND([giftamt],2) END
	,rm
ORDER BY 
	--CAST(REPLACE(REPLACE(giftamt,'$',''),',','') AS float)
	CAST(REPLACE(REPLACE(CASE WHEN @Vertical='Missions' THEN ROUND([last_giftamt],2) ELSE ROUND([giftamt],2) END,'$',''),',','') AS float)
	,rm

