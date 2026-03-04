CREATE PROCEDURE [dbo].[Refresh_DropTotals]
(
	@FileID INT
) AS

SET NOCOUNT ON

DECLARE @testing BIT=0

--DECLARE @FileID INT
--SET @FileID = 62
--SET @testing=1

--STEP 3a: get mail totals by parentID
--JCK:12.09.2025 - added filter to exclude dupedrop and NCOA errors from NCOA table
IF OBJECT_ID('tempdb..#tmpParentTotal') IS NOT NULL
	DROP TABLE #tmpParentTotal
SELECT parent_ID, COUNT(*) TotalSelected
INTO #tmpParentTotal
FROM ORIGINAL A
	LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id
WHERE A.FileID=@FileID 
	AND (B.dupedrop IS NULL OR B.dupedrop<>'TRUE')
	AND ( B.error_code IS NULL OR B.error_code NOT IN (
	'-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220',
	'311','312','313','411','412','413','414','415','416','417','418','419','420','421',
	'422','423','491','492','493','494'
	))
GROUP BY parent_ID

IF @testing=1 BEGIN
	SELECT * FROM #tmpParentTotal

	SELECT A.[FileID], B.parent_id
		,D.TotalSelected
		,TotalDupDrops
		,TotalNCOADrops
	FROM ProcessLog A JOIN (SELECT B.parent_id, SUM(CASE WHEN C.dupedrop='TRUE' THEN 1 ELSE 0 END) TotalDupDrops
			,SUM(CASE WHEN C.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494') THEN 1 ELSE 0 END) TotalNCOADrops
			FROM ProcessLog A
				JOIN ORIGINAL B ON B.FileID=A.FileID AND B.parent_id=A.Parent_ID
				JOIN NCOA C ON C.ParentFileID=A.FileID AND C.id=B.id
			WHERE 
				A.FileID=@FileID
				AND (C.dupedrop='TRUE'
				OR error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494'))
			GROUP BY B.parent_id) B ON B.parent_ID=A.Parent_ID
		LEFT JOIN #tmpParentTotal D ON D.parent_id=A.Parent_ID
END ELSE BEGIN
	--update dupe and NCOA drops totals
	--SELECT A.[FileID], B.parent_id
	--	, SUM(CASE WHEN C.dupedrop='TRUE' THEN 1 ELSE 0 END) TotalDupDrops
	--	, SUM(CASE WHEN C.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494') THEN 1 ELSE 0 END) TotalNCOADrops
	UPDATE A
		SET Delivered_Qty=D.TotalSelected, Dups_Drop=TotalDupDrops, NCOA_Drop=TotalNCOADrops
	FROM ProcessLog A JOIN (SELECT B.parent_id, SUM(CASE WHEN C.dupedrop='TRUE' THEN 1 ELSE 0 END) TotalDupDrops
		,SUM(CASE WHEN C.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494') THEN 1 ELSE 0 END) TotalNCOADrops
		FROM ProcessLog A
			JOIN ORIGINAL B ON B.FileID=A.FileID AND B.parent_id=A.Parent_ID
			JOIN NCOA C ON C.ParentFileID=A.FileID AND C.id=B.id
		WHERE 
			A.FileID=@FileID
			AND (C.dupedrop='TRUE'
			OR error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494'))
		GROUP BY B.parent_id) B ON B.parent_ID=A.Parent_ID
		LEFT JOIN #tmpParentTotal D ON D.parent_id=A.Parent_ID
END

