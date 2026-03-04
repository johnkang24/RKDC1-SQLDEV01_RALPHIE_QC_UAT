CREATE PROCEDURE [dbo].[GetInventoryData]  @deliverable_id int
as


/*
declare @deliverable_id		int
set @deliverable_id			= 50957
*/

/*
--------------------------------------------
declare @SelectString				nvarchar(max)

--************************************************************

-- Read the data for inventory
SET @SelectString = 'SELECT CONCAT(cleaned_data.appeal1, '' '', cleaned_data.rm) AS Keyline, ' +
    'COUNT(*) AS Count, cleaned_data.list AS ''List'', cleaned_data.rm AS ''RM'', ' +
    'CASE ' +
        'WHEN cleaned_data.gift_amount BETWEEN 0 AND 5 THEN ''$0 - $4.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 5 AND 10 THEN ''$5 - $9.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 10 AND 25 THEN ''$10 - $24.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 25 AND 50 THEN ''$25 - $49.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 50 AND 100 THEN ''$50 - $99.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 100 AND 250 THEN ''$100 - $249.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 250 AND 500 THEN ''$250 - $499.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 500 AND 1000 THEN ''$500 - $999.99'' ' +
        'ELSE ''Other'' ' +
    'END AS ''RM Desc'' ' +
    'FROM ' +
    '(SELECT TRY_CAST(LTRIM(RTRIM(giftamt)) AS DECIMAL(10, 2)) AS gift_amount, appeal1, rm, list, parent_id ' +
     'FROM [RALPHIE_QC].[dbo].[ORIGINAL] ' +
     'WHERE TRY_CAST(LTRIM(RTRIM(giftamt)) AS DECIMAL(10, 2)) IS NOT NULL) AS cleaned_data ' +
    'WHERE cleaned_data.parent_id = ' + CAST(@deliverable_id AS NVARCHAR(10)) + ' ' +
    'GROUP BY ' +
    'CASE ' +
        'WHEN cleaned_data.gift_amount BETWEEN 0 AND 5 THEN ''$0 - $4.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 5 AND 10 THEN ''$5 - $9.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 10 AND 25 THEN ''$10 - $24.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 25 AND 50 THEN ''$25 - $49.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 50 AND 100 THEN ''$50 - $99.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 100 AND 250 THEN ''$100 - $249.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 250 AND 500 THEN ''$250 - $499.99'' ' +
        'WHEN cleaned_data.gift_amount BETWEEN 500 AND 1000 THEN ''$500 - $999.99'' ' +
        'ELSE ''Other'' ' +
    'END, ' +
    'cleaned_data.appeal1, cleaned_data.rm, cleaned_data.list ' +
    'ORDER BY ''RM Desc'';';

EXEC sp_executesql @SelectString;
*/

SELECT CONCAT(appeal1, ' ', rm) AS Keyline,
    COUNT(*) AS Count, list AS 'List', rm, 
	CASE WHEN B.RM_Desc IS NULL THEN '(Unknown) Unknown' ELSE B.RM_Desc END RM_Desc, 
	A.IsSeed
FROM ORIGINAL A LEFT JOIN [dbo].[RM_Codes] B ON B.RM_Code=A.rm
	LEFT JOIN NCOA C ON C.ParentFileID=A.FileID AND C.id=A.id
WHERE A.parent_id=@deliverable_id 
		AND (C.dupedrop IS NULL OR C.dupedrop<>'TRUE')
		AND (C.error_code IS NULL OR C.error_code NOT IN (
		'-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220',
		'311','312','313','411','412','413','414','415','416','417','418','419','420','421',
		'422','423','491','492','493','494')
		)
GROUP BY CONCAT(appeal1, ' ', rm), list, rm, B.RM_Desc, A.IsSeed
ORDER BY A.IsSeed DESC, CONCAT(appeal1, ' ', rm), list, rm

