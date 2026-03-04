CREATE PROCEDURE [dbo].[CreateUpdate_EmailNotification_Default]
(
	@Client_code VARCHAR(50),
    @QCFilesCreated VARCHAR(2000),
    @LettershopCreated VARCHAR(2000),
    @NCOACreated VARCHAR(2000),
    @MergeDupCreated VARCHAR(2000),
    @AppealTrackingCreated VARCHAR(2000),
    @PromoHarvestCreated VARCHAR(2000),
    @QCReportCreated VARCHAR(2000)
)
AS

DECLARE @ID AS INT

SELECT @ID=EN_ID FROM EmailNotification WHERE Client_code=@Client_code

IF @ID > 0 BEGIN
  UPDATE EmailNotification SET
	  QCFilesCreated=@QCFilesCreated
      ,LettershopCreated=@LettershopCreated
      ,NCOACreated=@NCOACreated
      ,MergeDupCreated=@MergeDupCreated
      ,AppealTrackingCreated=@AppealTrackingCreated
      ,PromoHarvestCreated=@PromoHarvestCreated
      ,QCReportCreated=@QCReportCreated
	  ,LastModifiedDate=GETDATE()
	WHERE EN_ID=@ID 
END ELSE BEGIN
	INSERT EmailNotification ([Client_code]
      ,[QCFilesCreated]
      ,[LettershopCreated]
      ,[NCOACreated]
      ,[MergeDupCreated]
      ,[AppealTrackingCreated]
      ,[PromoHarvestCreated]
      ,[QCReportCreated])
	VALUES (@Client_code
      ,@QCFilesCreated
      ,@LettershopCreated
      ,@NCOACreated
      ,@MergeDupCreated
      ,@AppealTrackingCreated
      ,@PromoHarvestCreated
      ,@QCReportCreated)
END

