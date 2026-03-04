CREATE PROCEDURE [dbo].[GetNCOAChangesByFileID]  @fileID int
as

--declare  @fileID int
--set  @fileID = 50

--DECLARE @is_acquisition BIT
--SELECT @is_acquisition=MAX(Is_Acquisition)
--FROM ProcessLog
--WHERE FileID=@fileID
--	AND QC_Approved=1
--	AND Is_Acquisition=0
--print @is_acquisition

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

--IF @is_acquisition=0 BEGIN
	SELECT 
		distinct f.client_code client_id,
		(n.id) donor_id,
	 --   n.serial,
	 --   n.fname,
	 --   n.middle,
	 --   n.lname,
	 --   n.suffix,
	 --   n.salutation,
	 --   n.company,
	 --   n.title,
	 --   n.addressee1,
	 --   n.addressee2,
		--o.address1,
		--o.address2,
		--o.city,
		--o.state,
		--o.zip,
		--n.address1 AS new_address_1,
		--n.address2 AS new_address_2,
		--n.city AS new_city,
		--n.state AS new_state,
		--n.zip AS new_zip,
		--n.move_type,
		--n.mv_forward,
		--n.mv_effdate,
		--CASE mv_forward
		--	WHEN 'A' THEN 'DONOR MOVED, CHANGE ADDRESS'
		--	WHEN '19' THEN 'NO FORWARD, RECOMMEND VERIFY OR DELETE'
		--	WHEN '91' THEN 'DONOR MOVED, CHANGE ADDRESS'
		--	WHEN '92' THEN 'DONOR MOVED, CHANGE ADDRESS'
		--END AS recommendation,
		--n.error_code,
		--n.error_description
		[dbo].udf_QuoteString(n.serial) serial,
		[dbo].udf_QuoteString(n.fname) fname,
		[dbo].udf_QuoteString(n.middle) middle,
		[dbo].udf_QuoteString(n.lname) lname,
		[dbo].udf_QuoteString(n.suffix) suffix,
		[dbo].udf_QuoteString(n.salutation) salutation,
		[dbo].udf_QuoteString(n.company) company,
		[dbo].udf_QuoteString(n.title) title,
		[dbo].udf_QuoteString(n.addressee1) addressee1,
		[dbo].udf_QuoteString(n.addressee2) addressee2,
		[dbo].udf_QuoteString(o.address1) address1,
		[dbo].udf_QuoteString(o.address2) address2,
		[dbo].udf_QuoteString(o.city) city,
		[dbo].udf_QuoteString(o.state) state,
		[dbo].udf_QuoteString(o.zip) zip,
		[dbo].udf_QuoteString(n.address1) AS new_address_1,
		[dbo].udf_QuoteString(n.address2) AS new_address_2,
		[dbo].udf_QuoteString(n.city) AS new_city,
		[dbo].udf_QuoteString(n.state) AS new_state,
		[dbo].udf_QuoteString(n.zip) AS new_zip,
		[dbo].udf_QuoteString(n.move_type) move_type,
		[dbo].udf_QuoteString(n.mv_forward) mv_forward,
		[dbo].udf_QuoteString(n.mv_effdate) mv_effdate,
		[dbo].udf_QuoteString(CASE mv_forward
			WHEN 'A' THEN 'DONOR MOVED, CHANGE ADDRESS'
			WHEN '19' THEN 'NO FORWARD, RECOMMEND VERIFY OR DELETE'
			WHEN '91' THEN 'DONOR MOVED, CHANGE ADDRESS'
			WHEN '92' THEN 'DONOR MOVED, CHANGE ADDRESS'
		END) AS recommendation,
		[dbo].udf_QuoteString(n.error_code) error_code, 
		[dbo].udf_QuoteString(n.error_description) error_description
	FROM [dbo].[ORIGINAL] o 
		JOIN [dbo].[NCOA] n ON o.FileID = n.ParentFileID AND o.id=n.id
		JOIN [dbo].[FileLog] f ON f.FileID=o.FileID
	--WHERE o.FileID = @fileID
	WHERE o.FileID IN (SELECT FileID FROM FileLog WHERE Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@fileID))
		AND mv_forward IN ('A','91','92','19')
	ORDER BY n.id
--END

