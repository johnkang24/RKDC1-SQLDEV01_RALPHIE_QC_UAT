
CREATE PROCEDURE [dbo].[SetLastGiftDate]
(
	@FileID INT,
	@LastGiftDate DATE
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @LastGiftDate IS NOT NULL BEGIN
		UPDATE FileLog SET LastGiftDate=@LastGiftDate WHERE FileID=@FileID
	END

END

