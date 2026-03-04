
CREATE PROCEDURE [dbo].[Update_FileLog_Filename]  
(
	@AdvJobNo VARCHAR(50),
	@outputFileType VARCHAR(100),
	@outputFilename VARCHAR(MAX)
)
AS

--testing
--DECLARE	@AdvJobNo VARCHAR(50),
--	@outputFileType VARCHAR(100),
--	@outputFilename VARCHAR(MAX)
--SET @AdvJobNo = '91090'
--SET @outputFileType = 'AppealTracking'
--SET @outputFilename = '\\Rkdc1-SQLDEV01\tempdata\RALPHIE\staging\READY TO QC\OUTPUT FILES\APPEALTRACKING\Food Banks\AFBAR\Analytics + Reports\Tracking Sheets\2025\AFBAR_2025_Letter From the CEO_91090.xlsx'

UPDATE FileLog
	SET AppealTracking_FileName = CASE WHEN @outputFileType='AppealTracking' THEN @outputFilename ELSE AppealTracking_FileName END,
		MergeDupe_FileName = CASE WHEN @outputFileType='Dups' THEN @outputFilename ELSE MergeDupe_FileName END,
		NCOA_FileName = CASE WHEN @outputFileType='NCOA' THEN @outputFilename ELSE NCOA_FileName END,
		NCOA_Error_FileName = CASE WHEN @outputFileType='NCOAError' THEN @outputFilename ELSE NCOA_Error_FileName END,
		PromoHarvester_FileName = CASE WHEN @outputFileType='PromoHarvester' THEN @outputFilename ELSE PromoHarvester_FileName END
WHERE Advantage_Job_ID=@AdvJobNo

