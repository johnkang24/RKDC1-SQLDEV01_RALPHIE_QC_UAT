CREATE PROCEDURE [dbo].[SendUpdatesToWorkfront]
(
	@Parent_ID VARCHAR(50),
	@TaskName VARCHAR(100),
	@TaskStatus VARCHAR(50),
	@TaskCompletionPercent INT=100
)
AS


DECLARE @CALL_TYPE VARCHAR(100), @OUTSTATUS VARCHAR(MAX),@OUTRESPONSE VARCHAR(MAX), @TASKUPDATE VARCHAR(MAX) , @WEBHOOK_ADDR VARCHAR(MAX)

--SET @CALL_TYPE = 'Create WF project from ADV job component'
SET @WEBHOOK_ADDR = 'https://hook.app.workfrontfusion.com/2vjvqieyh2r8usc35038gow2178mprpm'	--UAT

SET @TASKUPDATE = (SELECT QuoteID, QuoteLine_ID, Package_code, @TaskName TaskName, @TaskCompletionPercent CompletionPercent
	FROM ProcessLog
	WHERE Parent_ID=@Parent_ID
	FOR JSON PATH) 

EXEC SPX_MAKE_API_REQUEST 'POST','XXX',@TASKUPDATE,@WEBHOOK_ADDR,@OUTSTATUS OUTPUT,@OUTRESPONSE OUTPUT

--only if the webhook call was returned successful add the new emp code so we don't recent again
IF @OUTSTATUS <> 'Status: 200 (OK)' BEGIN
	PRINT @OUTSTATUS
	--LOG ERROR
END

