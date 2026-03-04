CREATE PROCEDURE [dbo].[GetSuspectRecordData]  @parent_id int
AS

-------------------------------------------------------------------------------------------------------------
-- MODIFICATION HISTORY
-------------------------------------------------------------------------------------------------------------
-- JCK:11.14.2025 - compare data from NCOA as the primary source
-------------------------------------------------------------------------------------------------------------

--TESTING
--declare @parent_id int
--set @parent_id = 132148

	SELECT TOP 50
		COALESCE(B.id,A.id) id,  -- or any unique identifier column from ORIGINAL
		'salutation is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.salutation,A.salutation) = ''
		AND mailtype<>'S'
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'addressee1 is empty and company is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.addressee1, A.addressee1, '') = '' AND COALESCE(B.company, A.company, '') = ''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'address1 is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.address1, A.address1, '') = ''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'
	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'city is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.city, A.city, '') = ''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'state is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.state, A.state, '') = ''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT 
		COALESCE(B.id,A.id) id, 
		'state length is not 2 characters' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.state, '') <> '' AND LEN(LTRIM(RTRIM(B.state))) <> 2
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'state code is invalid' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
		LEFT JOIN StateCode C ON C.Code = COALESCE(B.state,A.state)
	WHERE parent_id = @parent_id 
	  AND COALESCE(B.state, A.state, '') <> '' 
	  AND LEN(LTRIM(RTRIM(COALESCE(B.state,A.state)))) = 2
	  AND C.Code IS NULL  -- not found in StateCode
	  AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	  AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'zip is empty' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND COALESCE(B.zip, A.zip, '') = ''
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

	UNION ALL

	SELECT TOP 50
		COALESCE(B.id,A.id) id, 
		'zip is longer than 10 characters' AS error,
		COALESCE(B.salutation,A.salutation) salutation,
		COALESCE(B.addressee1,A.addressee1) addressee1,
		COALESCE(B.address1, A.address1) address1,
		COALESCE(B.city,A.city) city,
		COALESCE(B.state,A.state) state,
		COALESCE(B.zip, A.zip) zip, Original_ID
	FROM [dbo].[ORIGINAL] A 
		LEFT JOIN NCOA B ON B.ParentFileID=A.FileID AND B.id=A.id 
	WHERE parent_id = @parent_id AND LEN(COALESCE(B.zip, A.zip)) > 10
		AND COALESCE(B.error_code,'') NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
		AND COALESCE(B.dupedrop,'')<>'TRUE'

