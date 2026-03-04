CREATE PROCEDURE [dbo].[GetSuspectRecordRules]  @parent_id int
AS

/*
declare @parent_id		int
set @parent_id			= 50959
*/

SELECT 
    'salutation' AS check_name,
    CASE 
        --WHEN count(distinct(salutation)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no salutation'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.salutation,A.salutation,'')=''
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'
	AND mailtype<>'S'

UNION ALL

SELECT 
    'addressee1' AS check_name,
    CASE 
        --WHEN count(distinct(addressee1)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no addressee1'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.addressee1,A.addressee1,'')='' AND COALESCE(B.company,A.company,'')=''
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'address1' AS check_name,
    CASE 
        --WHEN count(distinct(address1)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no address1'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.address1,A.address1,'')=''
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

--SELECT
--    'city' AS check_name,
--    CASE 
--        WHEN count(distinct(city)) > 0 THEN 'Failed'
--        ELSE 'Passed'
--    END AS status
--FROM [dbo].[ORIGINAL]
--WHERE parent_id = @parent_id AND COALESCE(city,'')=''
SELECT
    'city' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no city value'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.city,A.city,'')=''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'state_exists' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no state value'
        ELSE 'All records have a state'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.state,A.state,'')=''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'state_length' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has a state length more/less than 2 characters'
        ELSE 'State is no more than 2 characters for all records'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id IN (132104,132148) --AND (COALESCE(B.state,A.state,'')<>'' 
	AND LEN(TRIM(COALESCE(B.state,A.state,''))) <> 2
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'state_valid' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has an invalid state code'
        ELSE 'All records have an acceptable State abbreviation'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id
	LEFT JOIN StateCode C ON C.Code=COALESCE(B.State,A.State)
WHERE parent_id IN (132104,132148) --AND (COALESCE(B.state,A.state,'')<>'' 
	AND LEN(LTRIM(RTRIM(COALESCE(B.state,A.state,'')))) <> 2
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'zip_exists' AS check_name,
    CASE 
        WHEN count(distinct(COALESCE(B.zip,A.zip,''))) > 0 THEN 'Failed - ' + CAST(count(distinct(COALESCE(B.zip,A.zip,''))) AS VARCHAR(10)) + ' records have no zip code'
        ELSE 'All records have a Zip'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id AND COALESCE(B.zip,A.zip,'') = ''
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'

UNION ALL 

SELECT
    'zip_length' AS check_name,
    CASE 
        --WHEN count(distinct(zip)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has no zip or more than 10 characters'
        ELSE 'Zip is no more than 10 characters for all records'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
WHERE parent_id = @parent_id  AND (COALESCE(B.zip,A.zip,'') = '' OR LEN(LTRIM(RTRIM(COALESCE(B.zip,A.zip)))) > 10)
	AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	AND COALESCE(B.dupedrop,'')<>'TRUE'


