
CREATE PROCEDURE [dbo].[SendNotificationEmail]  
(
	@msg_to VARCHAR(255),
	@msg_subject VARCHAR(255),
	@msg_body VARCHAR(MAX)
)
AS

exec msdb.dbo.sp_send_dbmail
		@profile_name = NULL
	,@recipients = @msg_to
	,@subject = @msg_subject
	,@body_format = 'HTML'
	,@body = @msg_body


