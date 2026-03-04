CREATE PROCEDURE [dbo].[GetNCOADrop]  @parent_id int
as


/*
declare @parent_id		int
set @parent_id			= 50957
*/

SELECT C.Client_Code,
    A.id,
    A.serial,
    A.fname,
    A.middle,
    A.lname,
    A.suffix,
    A.salutation,
    A.company,
    A.title,
    A.addressee1,
    A.addressee2,
	B.address1 AS OriginalAddress1,
	B.address2 AS OriginalAddress2,
	B.city AS OriginalCity,
	B.state AS OriginalState,
	B.zip AS OriginalZip,
	A.address1 AS NCOAAddress1,
	A.address2 AS NCOAAddress2,
	A.city AS NCOACity,
	A.state AS NCOAState,
	A.zip AS NCOAZip,
	A.move_type,
	A.mv_forward,
	A.mv_effdate,
	A.error_code,
	A.error_description
FROM [dbo].[NCOA] A 
	JOIN [dbo].[ORIGINAL] B ON B.FileID = A.ParentFileID AND B.id=A.id
	JOIN [dbo].[FileLog] C ON C.FileID=B.FileID
WHERE B.parent_id = @parent_id AND A.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494')

