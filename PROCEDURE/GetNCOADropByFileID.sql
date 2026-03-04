CREATE PROCEDURE [dbo].[GetNCOADropByFileID]  @fileID int
as

--declare @fileID		int
--set @fileID	= 50

--DECLARE @is_acquisition BIT
--SELECT @is_acquisition=MAX(Is_Acquisition)
--FROM ProcessLog
--WHERE FileID=@FileID

--IF @is_acquisition=0 BEGIN
	SELECT C.Client_Code client_id,
	 --   A.id donor_id,
	 --   A.serial,
	 --   A.fname,
	 --   A.middle,
	 --   A.lname,
	 --   A.suffix,
	 --   A.salutation,
	 --   A.company,
	 --   A.title,
	 --   A.addressee1,
	 --   A.addressee2,
		--B.address1,
		--B.address2,
		--B.city,
		--B.state,
		--B.zip,
		--A.address1 AS new_address_1,
		--A.address2 AS new_address_2,
		--A.city AS new_city,
		--A.state AS new_state,
		--A.zip AS new_zip,
		--'\N' recommendation,
		--A.move_type,
		--A.mv_forward,
		--A.mv_effdate,
		--A.error_code,
		--A.error_description
		dbo.udf_QuoteString(A.id) donor_id,
		A.serial,
		dbo.udf_QuoteString(A.fname) fname,
		dbo.udf_QuoteString(A.middle) middle,
		dbo.udf_QuoteString(A.lname) lname,
		dbo.udf_QuoteString(A.suffix) suffix,
		dbo.udf_QuoteString(A.salutation) salutation,
		dbo.udf_QuoteString(A.company) company,
		dbo.udf_QuoteString(A.title) title,
		dbo.udf_QuoteString(A.addressee1) addressee1,
		dbo.udf_QuoteString(A.addressee2) addressee2,
		dbo.udf_QuoteString(B.address1) address1,
		dbo.udf_QuoteString(B.address2) address2,
		dbo.udf_QuoteString(B.city) city,
		B.state,
		B.zip,
		dbo.udf_QuoteString(A.address1) new_address_1,
		dbo.udf_QuoteString(A.address2) new_address_2,
		dbo.udf_QuoteString(A.city) new_city,
		dbo.udf_QuoteString(A.state) new_state,
		dbo.udf_QuoteString(A.zip) new_zip,
		'\N' recommendation,
		A.move_type,
		A.mv_forward,
		A.mv_effdate,
		dbo.udf_QuoteString(A.error_code) error_code,
		dbo.udf_QuoteString(A.error_description) error_description
	FROM [dbo].[NCOA] A 
		JOIN [dbo].[ORIGINAL] B ON B.FileID = A.ParentFileID AND B.id=A.id
		JOIN [dbo].[FileLog] C ON C.FileID=B.FileID
	WHERE C.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID) --B.FileID = @fileID 
		AND A.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')
	ORDER BY A.id
--END

