CREATE PROCEDURE [dbo].[GetClientNotifications]
(
	@ClientCode VARCHAR(50)
)
AS
SET NOCOUNT ON

SELECT *
  FROM [EmailNotification]
  WHERE Client_code=@ClientCode

