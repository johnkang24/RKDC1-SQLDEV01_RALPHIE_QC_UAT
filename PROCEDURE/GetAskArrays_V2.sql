CREATE PROCEDURE [dbo].[GetAskArrays_V2]
(
	@parent_id INT
)
AS

--TESTING
--DECLARE @parent_id INT
--SET @parent_id = 132082

EXECUTE GetAskArrays @parent_id

--SELECT giftamt
--	,rm 
--	, dbo.udf_GetDonorType(rm) Donor_Type
--      ,MAX([ug1]) [ug1]
--      ,MAX([lg]) [lg]
--      ,MAX([ug2]) [ug2]
--      ,MAX([ug3]) [ug3]
--      ,MAX([ug4]) [ug4]
--      ,MAX([ug5]) [ug5]
--	  ,MAX([ltramt]) [ltramt]
--	  ,MAX(m1) m1
--	  ,MAX(mg) mg
--	  ,MAX(m2) m2
--	  ,MAX(m3) m3
--	  ,MAX(m4) m4
--	  ,MAX(m5) m5
--FROM [ORIGINAL]
--WHERE parent_id=@parent_id
--GROUP BY giftamt
--		,rm
--ORDER BY  CAST(REPLACE(REPLACE(giftamt,'$',''),',','') AS float)
--		,rm

SELECT CASE WHEN COALESCE(C.GiftAmountType,'')='Last' THEN A.last_giftamt ELSE A.giftamt END giftamt
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
FROM [ORIGINAL] A JOIN FileLog B ON B.FileID=A.FileID
	LEFT JOIN Verticals C ON C.Vertical=B.Vertical
WHERE A.parent_id=@parent_id
GROUP BY CASE WHEN COALESCE(C.GiftAmountType,'')='Last' THEN A.last_giftamt ELSE A.giftamt END, rm
ORDER BY  CAST(REPLACE(REPLACE(CASE WHEN COALESCE(C.GiftAmountType,'')='Last' THEN A.last_giftamt ELSE A.giftamt END,'$',''),',','') AS float), rm

