CREATE PROCEDURE [dbo].[GetSuspectRecordData]  @parent_id int
AS

/*
declare @parent_id		int
set @parent_id			= 50963
*/

	SELECT TOP 50
		id,  -- or any unique identifier column from ORIGINAL
		'salutation is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(salutation, '') = ''
		AND mailtype<>'S'

	UNION ALL

	SELECT TOP 50
		id,
		'addressee1 is empty and company is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(addressee1, '') = '' AND COALESCE(company, '') = ''

	UNION ALL

	SELECT TOP 50
		id,
		'address1 is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(address1, '') = ''

	UNION ALL

	SELECT TOP 50
		id,
		'city is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(city, '') = ''

	UNION ALL

	SELECT TOP 50
		id,
		'state is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(state, '') = ''

	UNION ALL

	SELECT 
		id,
		'state length is not 2 characters' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(state, '') <> '' AND LEN(LTRIM(RTRIM(state))) <> 2

	UNION ALL

	SELECT TOP 50
		A.id,
		'state code is invalid' AS error,
		salutation,
		addressee1,
		address1,
		city,
		A.state,
		zip, A.Original_ID
	FROM [dbo].[ORIGINAL] A
	LEFT JOIN StateCode B ON B.Code = A.State
	WHERE parent_id = @parent_id 
	  AND COALESCE(A.state, '') <> '' 
	  AND LEN(LTRIM(RTRIM(A.state))) = 2
	  AND B.Code IS NULL  -- not found in StateCode

	UNION ALL

	SELECT TOP 50
		id,
		'zip is empty' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND COALESCE(zip, '') = ''

	UNION ALL

	SELECT TOP 50
		 id,
		'zip is longer than 10 characters' AS error,
		salutation,
		addressee1,
		address1,
		city,
		state,
		zip, Original_ID
	FROM [dbo].[ORIGINAL]
	WHERE parent_id = @parent_id AND LEN(zip) > 10

