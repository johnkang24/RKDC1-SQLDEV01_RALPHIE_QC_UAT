CREATE PROCEDURE [dbo].[GetSuspectFileData]  @parent_id int
as

/*
declare @parent_id		int
set @parent_id			= 50959
*/

SELECT 
    'unique_serials' AS check_name,
    CASE 
        WHEN MAX(serial_count) > 1 THEN 'Failed'
        ELSE 'Passed'
    END AS status
FROM (
    SELECT 
        serial, 
        COUNT(*) AS serial_count
    FROM [dbo].[ORIGINAL]
    WHERE parent_id = @parent_id
    GROUP BY serial
) AS serial_counts

UNION ALL

SELECT 
    'client_code',
    CASE 
        WHEN COUNT(client_code) = 0 THEN 'Failed'
        ELSE 'Passed'
    END AS status
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND client_code IS NOT NULL

UNION ALL
SELECT *
FROM (
SELECT TOP 100 check_name, status
FROM (
	SELECT parent_id, child_id,
		'appeal_codes' check_name,
		--append parent/child in the UI
		--appeal1 + ' ' + CASE WHEN child_id IS NULL THEN parent_id ELSE child_id END + ', ' + appeal1 + ' ' + CASE WHEN child_id IS NULL THEN 'Parent' ELSE 'Child' END status
		appeal1 + ' ' + CASE WHEN child_id IS NULL THEN parent_id ELSE child_id END + ', ' + appeal1 status
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id 
	GROUP BY appeal1, parent_id, child_id
	) A
ORDER BY parent_id, child_id) A

UNION ALL

SELECT 
	'mail_month',
    mailmnth
FROM [dbo].[ORIGINAL] 
WHERE parent_id = @parent_id 
GROUP BY mailmnth

UNION ALL

SELECT 
    'mailtype',
	mailtype
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id 
GROUP BY mailtype

UNION ALL

SELECT 
    'mailpkg',
    STUFF((
        SELECT DISTINCT ', ' + mailpkg
        FROM [dbo].[ORIGINAL]
        WHERE parent_id = @parent_id AND mailpkg IS NOT NULL
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '')

UNION ALL

--static for now but will pull from COMS later
--SELECT 'scanline_sample', 'cc(5)-sp(2)-id(full)-sp(2)-ac(full)-sp(2)-rm(2)'
SELECT 'scanline_sample', Sample_Scanline
FROM FileLog A JOIN ProcessLog B ON B.FileID=A.FileID
	AND B.Parent_ID=@parent_id

UNION ALL

-- scanline
SELECT 'scanline',
    max(scanline1)
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id --AND child_id IS NULL
UNION ALL
-- child: scanline
SELECT check_name, status
FROM (
	SELECT child_id,
		'scanline' check_name,
		max(scanline1) status
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND child_id IS NOT NULL
	GROUP BY child_id
	) A

UNION ALL

--static for now but will pull from COMS later
--SELECT 'bc2d1_sample', 'cc(5)-sp(2)-id(full)-sp(2)-ac(full)-sp(2)-rm(2)'
SELECT 'bc2d1_sample', Sample_BC2D1
FROM FileLog A JOIN ProcessLog B ON B.FileID=A.FileID
	AND B.Parent_ID=@parent_id

UNION ALL

-- parent: bc2d1
SELECT 'bc2d1',
    max(bc2d1)
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id AND child_id IS NULL
UNION ALL
-- child: bc2d1
SELECT check_name, status
FROM (
	SELECT child_id,
		'bc2d1' check_name,
		max(bc2d1) status
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND child_id IS NOT NULL
	GROUP BY child_id
	) A

UNION ALL

-- parent: bc2d2
SELECT 'bc2d2',
	max(bc2d2)
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id 
	AND COALESCE(bc2d2,'')<>''
	AND child_id IS NULL
UNION ALL
-- child: bc2d2
SELECT check_name, status
FROM (
	SELECT child_id,
		'bc2d2' check_name,
		max(bc2d2) status
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id 
		AND COALESCE(bc2d2,'')<>''
		AND child_id IS NOT NULL
	GROUP BY child_id
	) A


UNION ALL

-- parent: bc3of9
SELECT 'bc3of9',
	max(bc3of9)
FROM [dbo].[ORIGINAL]
WHERE parent_id = @parent_id 
	AND COALESCE(bc3of9,'')<>''
	AND child_id IS NULL
UNION ALL
-- child: bc3of9
SELECT check_name, status
FROM (
	SELECT child_id,
		'bc3of9' check_name,
		max(bc3of9) status
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id 
		AND COALESCE(bc3of9,'')<>''
		AND child_id IS NOT NULL
	GROUP BY child_id
	) A

