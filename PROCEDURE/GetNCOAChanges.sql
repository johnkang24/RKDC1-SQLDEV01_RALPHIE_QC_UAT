CREATE PROCEDURE [dbo].[GetNCOAChanges]  @parent_id int
as

/*
declare @parent_id		int
set @parent_id = 50957
*/

/*
SELECT 
    distinct(n.id),
    n.serial,
    n.fname,
    n.middle,
    n.lname,
    n.suffix,
    n.salutation,
    n.company,
    n.title,
    n.addressee1,
    n.addressee2,
	o.address1 AS OriginalAddress1,
	o.address2 AS OriginalAddress2,
	o.city AS OriginalCity,
	o.state AS OriginalState,
	o.zip AS OriginalZip,
	n.address1 AS NCOAAddress1,
	n.address2 AS NCOAAddress2,
	n.city AS NCOACity,
	n.state AS NCOAState,
	n.zip AS NCOAZip,
	n.move_type,
	n.mv_forward,
	n.mv_effdate,
	n.error_code,
	n.error_description
FROM 
    [dbo].[ORIGINAL] o 
JOIN 
    [dbo].[NCOA] n 
    ON o.FileID = n.ParentFileID
WHERE 
	o.id = n.id
	AND o.FileID = @file_id
    AND (
		o.address1 != n.address1
		OR o.address2 != n.address2
		OR o.city != n.city
		OR o.state != n.state
		OR o.zip != n.zip
	)
	AND n.id not in (
		select id from [dbo].NCOA n where n.error_description like '%invalid%' 
		)
*/

SELECT 
    distinct(n.id),
    n.serial,
    n.fname,
    n.middle,
    n.lname,
    n.suffix,
    n.salutation,
    n.company,
    n.title,
    n.addressee1,
    n.addressee2,
	o.address1 AS OriginalAddress1,
	o.address2 AS OriginalAddress2,
	o.city AS OriginalCity,
	o.state AS OriginalState,
	o.zip AS OriginalZip,
	n.address1 AS NCOAAddress1,
	n.address2 AS NCOAAddress2,
	n.city AS NCOACity,
	n.state AS NCOAState,
	n.zip AS NCOAZip,
	n.move_type,
	n.mv_forward,
	n.mv_effdate,
	CASE mv_forward
		WHEN 'A' THEN 'DONOR MOVED, CHANGE ADDRESS'
		WHEN '19' THEN 'NO FORWARD, RECOMMEND VERIFY OR DELETE'
		WHEN '91' THEN 'DONOR MOVED, CHANGE ADDRESS'
		WHEN '92' THEN 'DONOR MOVED, CHANGE ADDRESS'
	END AS recommendation,
	n.error_code,
	n.error_description
FROM [dbo].[ORIGINAL] o 
	JOIN [dbo].[NCOA] n ON o.FileID = n.ParentFileID AND o.id=n.id
WHERE o.parent_id = @parent_id
	AND mv_forward IN ('A','91','92','19')

