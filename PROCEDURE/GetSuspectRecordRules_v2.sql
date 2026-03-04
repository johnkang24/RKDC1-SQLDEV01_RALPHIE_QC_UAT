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
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(salutation,'') = ''
	AND mailtype<>'S'

UNION ALL

SELECT 
    'addressee1' AS check_name,
    CASE 
        --WHEN count(distinct(addressee1)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no addressee1'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(addressee1,'')='' AND COALESCE(company,'')=''

UNION ALL 

SELECT
    'address1' AS check_name,
    CASE 
        --WHEN count(distinct(address1)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN  'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no address1'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(address1,'')=''

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
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(city,'')=''

UNION ALL 

SELECT
    'state_exists' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records have no state value'
        ELSE 'All records have a state'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(state,'')=''

UNION ALL 

SELECT
    'state_length' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has a state length more/less than 2 characters'
        ELSE 'State is no more than 2 characters for all records'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND (COALESCE(state,'')<>'' AND LEN(LTRIM(RTRIM(state))) <> 2)

UNION ALL 

SELECT
    'state_valid' AS check_name,
    CASE 
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has an invalid state code'
        ELSE 'All records have an acceptable State abbreviation'
    END AS status
FROM [dbo].[ORIGINAL] A LEFT JOIN StateCode B ON B.Code=A.State
WHERE parent_id = @parent_id AND (COALESCE(A.state,'')<>'' AND LEN(LTRIM(RTRIM(A.state))) <> 2)

UNION ALL 

SELECT
    'zip_exists' AS check_name,
    CASE 
        WHEN count(distinct(zip)) > 0 THEN 'Failed'
        ELSE 'All records have a Zip'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND COALESCE(zip,'') = ''

UNION ALL 

SELECT
    'zip_length' AS check_name,
    CASE 
        --WHEN count(distinct(zip)) > 0 THEN 'Failed'
        WHEN count(*) > 0 THEN 'Failed - ' + CAST(count(*) AS VARCHAR(10)) + ' records has no zip or more than 10 characters'
        ELSE 'Zip is no more than 10 characters for all records'
    END AS status
FROM [dbo].[ORIGINAL]
--WHERE parent_id = @parent_id AND (COALESCE(zip,'') <> '' AND LEN(LTRIM(RTRIM(zip))) > 10)
WHERE parent_id = @parent_id AND (COALESCE(zip,'') = '' OR LEN(LTRIM(RTRIM(zip))) > 10)


