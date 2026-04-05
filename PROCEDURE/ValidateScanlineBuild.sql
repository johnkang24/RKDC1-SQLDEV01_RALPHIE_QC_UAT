
CREATE PROCEDURE [dbo].[ValidateScanlineBuild]
(
	@FileID INT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT *
	FROM ProcessLog
	WHERE FileID=@FileiD
		AND COALESCE(Scanline_Error,'') > ''

END

