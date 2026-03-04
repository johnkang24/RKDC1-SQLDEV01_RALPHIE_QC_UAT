
CREATE PROCEDURE [dbo].[GetLastGiftDate]
(
	@FileID INT,
	@LastGiftDate DATE OUTPUT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @LastGiftDate=MAX(B.fb0_LastGiftDate)
	FROM [FileLog] A LEFT JOIN RALPHIE_COMS_UAT.dbo.[fb0_Jobs] B ON B.fb0_ServiceAgreementNbr=CAST(A.Advantage_Job_ID AS VARCHAR(50))
	WHERE A.FileID=@FileID

	IF @LastGiftDate IS NOT NULL BEGIN
		UPDATE FileLog SET LastGiftDate=@LastGiftDate WHERE FileID=@FileID
	END

END

