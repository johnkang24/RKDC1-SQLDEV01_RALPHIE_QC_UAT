
CREATE PROCEDURE [dbo].[SendNotificationEmail_Outputfile]  
(
	@AdvJobNo VARCHAR(50),
	@outputFileType VARCHAR(100),
	--@msg_to VARCHAR(255),
	@msg_subject VARCHAR(255),
	@msg_body VARCHAR(MAX)
)
AS

--testing
--DECLARE	@AdvJobNo VARCHAR(50),
--	@outputFileType VARCHAR(100),
--	@msg_subject VARCHAR(255),
--	@msg_body VARCHAR(MAX)
--SET @AdvJobNo = '91090'
--SET @outputFileType = 'AppealTracking'
--SET @msg_subject = 'Mail File Builder - Appeal Tracking sheet file created'
--SET @msg_body = '<b><a HREF=''\\Rkdc1-SQLDEV01\tempdata\RALPHIE\staging\READY TO QC\OUTPUT FILES\APPEALTRACKING\Food Banks\AFBAR\Analytics + Reports\Tracking Sheets\2025\AFBAR_2025_Letter From the CEO_91090.xlsx''>AFBAR_2025_Letter From the CEO_91090.xlsx</a></br>'

DECLARE @msg_to VARCHAR(MAX)

SELECT TOP 1 @msg_to=CASE @outputFileType
	WHEN 'QCReport' THEN A.Notify_QCOutput_Created
	WHEN 'AppealTracking' THEN A.Notify_AppealTracking_Created
	WHEN 'NCOA' THEN A.Notify_NCOA_Created
	WHEN 'Dups' THEN A.Notify_MergeDup_Created
	WHEN 'PromoHarvest' THEN A.Notify_PromoHarvest_Created
	WHEN 'Lettershop' THEN A.Notify_Lettershop_Created
	END
FROM ProcessLog A JOIN FileLog B ON B.FileID=A.FileID AND B.Advantage_Job_ID=@AdvJobNo
ORDER BY B.CreatedDate DESC

IF @msg_to>'' AND @msg_subject>'' BEGIN
	PRINT @msg_to
	exec msdb.dbo.sp_send_dbmail
			@profile_name = NULL
		,@recipients = @msg_to
		,@subject = @msg_subject
		,@body_format = 'HTML'
		,@body = @msg_body
END

