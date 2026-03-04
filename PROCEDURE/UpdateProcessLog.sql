CREATE PROCEDURE [dbo].[UpdateProcessLog]
(
	@FileID INT,
	@notify_qcfile VARCHAR(MAX),
	@notify_lettershop VARCHAR(MAX),
	@notify_ncoa VARCHAR(MAX),
	@notify_mergedup VARCHAR(MAX),
	@notify_appealtracking VARCHAR(MAX),
	@notify_promoharvest VARCHAR(MAX),
	@notify_qcoutput VARCHAR(MAX),
	@ncoa_link_report VARCHAR(MAX),
	@data_loader VARCHAR(100)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE ProcessLog SET Notify_QCFile_Created = @notify_qcfile
        ,Notify_Lettershop_Created = @notify_lettershop
        ,Notify_NCOA_Created = @notify_ncoa
        ,Notify_MergeDup_Created = @notify_mergedup
        ,Notify_AppealTracking_Created = @notify_appealtracking
        ,Notify_PromoHarvest_Created = @notify_promoharvest
        ,Notify_QCOutput_Created = @notify_qcoutput
        ,NCOA_Link_Report = @ncoa_link_report
        ,Data_Loader = @data_loader
        ,Approved_Date = null
        ,ApprovedBy = null
        ,Rejected_Date = null
        ,RejectedBy = null
	WHERE FileID=@FileID
END

