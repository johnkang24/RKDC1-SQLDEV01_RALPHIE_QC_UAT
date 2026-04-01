CREATE PROCEDURE [dbo].[Sync_ProcessLog_V2]
(
	@FileID INT
) AS

SET NOCOUNT ON

DECLARE @QuoteLineID VARCHAR(16), @PackageCode VARCHAR(255), @AdvJobNo INT, @JobID VARCHAR(18)
DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @DeliverableID INT
DECLARE @testing BIT = 0

--DECLARE @FileID INT
--SET @FileID = 58
--SET @testing = 1

SELECT TOP 1 @DeliverableID=parent_id
FROM ORIGINAL WHERE FileID=@FileID
--SET @QuoteLineID = 'QL-'+RIGHT('0000000'+CAST(@DeliverableID AS VARCHAR(20)),7)
SET @QuoteLineID = [dbo].udf_ConvertIDtoQuoteline(@DeliverableID)
PRINT @QuoteLineID

IF OBJECT_ID('tempdb..#tmpDeliverable') IS NOT NULL
    DROP TABLE #tmpDeliverable

CREATE TABLE #tmpDeliverable
(
	Id VARCHAR(255),
	JobId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	Vertical VARCHAR(255),
	Package_Code VARCHAR(255),
)

--/*
--STEP 1: Get all package data
SET @LinkedServer = 'COMS_UATSB'
SET @OPENQUERY = 'SELECT *
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.SBQQ__Account__r.SB_Vertical__c, CPQ_Package__c
	FROM SBQQ__QuoteLine__c WHERE Name=''''' + @QuoteLineID + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL'')' 

PRINT @OPENQUERY+@TSQL
INSERT #tmpDeliverable
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	SELECT * FROM #tmpDeliverable
END
SELECT @JobID=JobId, @AdvJobNo=Advantage_Job_Code__c, @PackageCode=Package_Code FROM #tmpDeliverable
PRINT @JobID

IF OBJECT_ID('tempdb..#tmpPkgPhases') IS NOT NULL
    DROP TABLE #tmpPkgPhases

CREATE TABLE #tmpPkgPhases
(
	Id VARCHAR(255),
	Name VARCHAR(255),
	QuoteId VARCHAR(255),
	Advantage_Job_Code__c VARCHAR(255),
	Campaign_Name VARCHAR(255),
	Job_Name__c VARCHAR(MAX),
	CPQ_Package__c NVARCHAR(MAX),
	CPQ_Phase__c NVARCHAR(MAX),
	SBQQ__Description__c NVARCHAR(MAX),
	CPQ_Job_Specific_Name__c NVARCHAR(MAX),
	SBQQ__ProductName__c NVARCHAR(MAX),
	SB_DM_Data_Selection_Criteria__c NVARCHAR(MAX),
	CPQ_Estimated_Quantity__c INT,
	SB_DM_Prelim_Quantity__c INT,
	CPQ_Mail_Ship_Date__c DATETIME,
	SB_Ask_Array_Code__c NVARCHAR(MAX),
	SB_DM_Multiplier__c DECIMAL(18,2),
	SB_RKD_Audience_Code__c NVARCHAR(MAX),
	SB_RKD_Audience__c NVARCHAR(MAX),
	SB_Creative_Name NVARCHAR(MAX),
	SB_Creative_Code__c NVARCHAR(MAX),
	SB_Abbreviation__c NVARCHAR(MAX),
	CPQ_T_C_R__c NVARCHAR(MAX),
	PackageQty INT,
)

--/*
--STEP 2: Get all package-phase data
SET @OPENQUERY = 'SELECT *, 0 PackageQty
	FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Advantage_Job_Code__c, SBQQ__Quote__r.SB_Schedule_Block__r.Name, SBQQ__Quote__r.Job_Name__c, CPQ_Package__c, CPQ_Phase__c, SBQQ__Description__c, CPQ_Job_Specific_Name__c, SBQQ__ProductName__c, SB_DM_Data_Selection_Criteria__c, CPQ_Estimated_Quantity__c, SB_DM_Prelim_Quantity__c, CPQ_Mail_Ship_Date__c, SB_Ask_Array_Code__c, SB_DM_Multiplier__c, SB_RKD_Audience_Code__c, SB_RKD_Audience__c, SB_Creative_Name__r.Name, SB_Creative_Name__r.SB_Creative_Code__c, SB_Creative_Name__r.SB_Abbreviation__c, CPQ_T_C_R__c
	FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =''''' + @JobID + '''''  AND SB_Deliverable_Category__c=''''Deliverable'''' AND CPQ_Package__c != NULL ' + ' '')' 

PRINT @OPENQUERY+@TSQL
INSERT #tmpPkgPhases
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	PRINT '@QuoteLineID='+@QuoteLineID
	SELECT * FROM #tmpPkgPhases
END

--STEP 3a: get mail totals by parentID
IF OBJECT_ID('tempdb..#tmpParentTotal') IS NOT NULL
	DROP TABLE #tmpParentTotal
SELECT A.parent_ID, COUNT(*) TotalSelected
INTO #tmpParentTotal
FROM ORIGINAL A JOIN ProcessLog B ON B.Parent_ID=A.parent_id
	AND B.QuoteID=(SELECT TOP 1 QuoteID FROM ProcessLog WHERE FileID=@FileID)
	LEFT JOIN [NCOA] C ON A.FileID=C.ParentFileID AND C.id=A.id
--JCK:12.17.2025 -- added to filter out dup and NCOA drops
WHERE (C.dupedrop IS NULL OR C.dupedrop<>'TRUE')
	AND (C.error_code IS NULL OR C.error_code NOT IN ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494'))
GROUP BY A.parent_ID

--STEP 3: get dupe and NCOA drops totals
IF OBJECT_ID('tempdb..#tmpDropTotal') IS NOT NULL
	DROP TABLE #tmpDropTotal
SELECT A.[FileID], B.parent_id
	, SUM(CASE WHEN A.dupedrop='TRUE' THEN 1 ELSE 0 END) TotalDupDrops
	, SUM(CASE WHEN A.error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494') THEN 1 ELSE 0 END) TotalNCOADrops
INTO #tmpDropTotal
FROM [NCOA] A JOIN ORIGINAL B ON B.FileID=A.ParentFileID AND B.id=A.id
WHERE A.ParentFileID=@FileID
	AND (A.dupedrop='TRUE'
	OR error_code in ('-1','111','112','113','114','211','212','213','214','215','216','217','218','219','220','311','312','313','411','412','413','414','415','416','417','418','419','420','421','422','423','491','492','493','494'))
GROUP BY A.[FileID], B.parent_id
IF @testing=1 BEGIN
	SELECT * FROM #tmpDropTotal
END

--STEP 4: get/set pkg total
IF OBJECT_ID('tempdb..#tmpLoadedDeliverables') IS NOT NULL
	DROP TABLE #tmpLoadedDeliverables

SELECT A.FileID, Parent_ID
INTO #tmpLoadedDeliverables
FROM ORIGINAL A JOIN FileLog B ON B.FileID=A.FileID
	AND B.Advantage_Job_ID=(SELECT Advantage_Job_ID FROM FileLog WHERE FileID=@FileID)
GROUP BY A.FileID, Parent_ID

IF @testing=1 BEGIN
	SELECT * FROM #tmpLoadedDeliverables


	SELECT B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, Job_Name__c, B.Name, A.CPQ_Package__c, B.CPQ_Phase__c, CPQ_Mail_Ship_Date__c, SB_DM_Data_Selection_Criteria__c, CPQ_Job_Specific_Name__c, B.SBQQ__Description__c, A.SBQQ__ProductName__c, A.SB_Ask_Array_Code__c, A.SB_DM_Multiplier__c, SB_RKD_Audience_Code__c, SB_RKD_Audience__c, SB_Creative_Name, 
		SB_Creative_Code__c, SB_Abbreviation__c, SUM(COALESCE(CPQ_Estimated_Quantity__c,0)) PackageQty, SUM(COALESCE(SB_DM_Prelim_Quantity__c,0)) PrelimQty
		FROM #tmpPkgPhases A JOIN (
			SELECT A.Id, A.Name, A.CPQ_Package__c, B.CPQ_Phase__c, A.SBQQ__Description__c
				FROM #tmpPkgPhases A JOIN (SELECT CPQ_Package__c, MIN(CPQ_Phase__c) CPQ_Phase__c FROM #tmpPkgPhases GROUP BY CPQ_Package__c) B ON B.CPQ_Package__c=A.CPQ_Package__c
					AND B.CPQ_Phase__c=A.CPQ_Phase__c
			) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c
		GROUP BY B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, Job_Name__c, B.Name, CPQ_Mail_Ship_Date__c, SB_DM_Data_Selection_Criteria__c, CPQ_Job_Specific_Name__c, A.CPQ_Package__c, B.CPQ_Phase__c, B.SBQQ__Description__c, A.SBQQ__ProductName__c, A.SB_Ask_Array_Code__c, A.SB_DM_Multiplier__c, SB_RKD_Audience_Code__c, SB_RKD_Audience__c, SB_Creative_Name, SB_Creative_Code__c, SB_Abbreviation__c
END

--STEP 5: get/set pkg total
IF OBJECT_ID('tempdb..#tmpPkgTotal') IS NOT NULL
	DROP TABLE #tmpPkgTotal

SELECT COALESCE(C.FileID,0) FileID, A.*, COALESCE(B2.TotalSelected,P.Delivered_Qty,0) TotalSelected, COALESCE(B.TotalDupDrops,P.Dups_Drop,0) TotalDupDrops, COALESCE(B.TotalNCOADrops,P.NCOA_Drop,0) TotalNCOADrops
INTO #tmpPkgTotal
FROM 
	--JCK:02.10.2026 - need to collect all child data selection criterias
	--(SELECT B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, Job_Name__c, B.Name, A.CPQ_Package__c, B.CPQ_Phase__c, CPQ_Mail_Ship_Date__c, STRING_AGG(RIGHT(B.Name,6)+':'+SB_DM_Data_Selection_Criteria__c,CHAR(13)) SB_DM_Data_Selection_Criteria__c, 
	--	CPQ_Job_Specific_Name__c, B.SBQQ__Description__c, A.SBQQ__ProductName__c, A.SB_Ask_Array_Code__c, A.SB_DM_Multiplier__c, SB_RKD_Audience_Code__c, SB_RKD_Audience__c, SB_Creative_Name, 
	--	SB_Creative_Code__c, SB_Abbreviation__c, SUM(COALESCE(CPQ_Estimated_Quantity__c,0)) PackageQty, SUM(COALESCE(SB_DM_Prelim_Quantity__c,0)) PrelimQty
	--	FROM #tmpPkgPhases A JOIN (
	--		SELECT A.Id, A.Name, A.CPQ_Package__c, B.CPQ_Phase__c, A.SBQQ__Description__c
	--		FROM #tmpPkgPhases A JOIN (SELECT CPQ_Package__c, MIN(CPQ_Phase__c) CPQ_Phase__c FROM #tmpPkgPhases GROUP BY CPQ_Package__c
	--		) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c
	--	--WHERE NOT (A.SB_RKD_Audience__c='Ship to Client' AND COALESCE(A.SB_DM_Data_Selection_Criteria__c,'')='')	--remove phases that doesn't need to be QC'd
	--	GROUP BY B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, Job_Name__c, B.Name, CPQ_Mail_Ship_Date__c, SB_DM_Data_Selection_Criteria__c, CPQ_Job_Specific_Name__c, A.CPQ_Package__c, B.CPQ_Phase__c, B.SBQQ__Description__c, A.SBQQ__ProductName__c, A.SB_Ask_Array_Code__c, 
	--		A.SB_DM_Multiplier__c, SB_RKD_Audience_Code__c, SB_RKD_Audience__c, SB_Creative_Name, SB_Creative_Code__c, SB_Abbreviation__c) A
	(SELECT B.Id, --MAX(B.Id) Id, 
		A.QuoteId,
		Advantage_Job_Code__c, 
		Campaign_Name, 
		Job_Name__c, 
		MAX(B.Name) Name, 
		A.CPQ_Package__c, 
		MIN(B.CPQ_Phase__c) CPQ_Phase__c, 
		MAX(CPQ_Mail_Ship_Date__c) CPQ_Mail_Ship_Date__c, 
		STRING_AGG(RIGHT(A.Name,6)+':'+SB_DM_Data_Selection_Criteria__c,CHAR(10)) SB_DM_Data_Selection_Criteria__c, 
		MAX(CPQ_Job_Specific_Name__c) CPQ_Job_Specific_Name__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN B.SBQQ__Description__c ELSE NULL END) SBQQ__Description__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SBQQ__ProductName__c ELSE NULL END) SBQQ__ProductName__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Ask_Array_Code__c ELSE NULL END) SB_Ask_Array_Code__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_DM_Multiplier__c ELSE NULL END) SB_DM_Multiplier__c,
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN B.SB_RKD_Audience_Code__c ELSE NULL END) SB_RKD_Audience_Code__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_RKD_Audience__c ELSE NULL END) SB_RKD_Audience__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Creative_Name ELSE NULL END) SB_Creative_Name, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Creative_Code__c ELSE NULL END) SB_Creative_Code__c, 
		MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Abbreviation__c ELSE NULL END) SB_Abbreviation__c, 
		SUM(COALESCE(CPQ_Estimated_Quantity__c,0)) PackageQty, SUM(COALESCE(SB_DM_Prelim_Quantity__c,0)) PrelimQty
		FROM #tmpPkgPhases A JOIN (
			SELECT A.Id, A.Name, A.CPQ_Package__c, B.CPQ_Phase__c, A.SBQQ__Description__c, SB_RKD_Audience_Code__c
			FROM #tmpPkgPhases A JOIN (SELECT CPQ_Package__c, MIN(CPQ_Phase__c) CPQ_Phase__c FROM #tmpPkgPhases GROUP BY CPQ_Package__c
			) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c) B ON B.CPQ_Package__c=A.CPQ_Package__c --AND B.CPQ_Phase__c=A.CPQ_Phase__c
		WHERE NOT (A.SB_RKD_Audience__c='Ship to Client' AND COALESCE(A.SB_DM_Data_Selection_Criteria__c,'')='')	--remove phases that doesn't need to be QC'd
		GROUP BY B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, A.CPQ_Package__c, A.Job_Name__c ) A
	LEFT JOIN #tmpDropTotal B ON [dbo].udf_ConvertIDtoQuoteline(B.parent_id)=A.Name
	LEFT JOIN #tmpParentTotal B2 ON [dbo].udf_ConvertIDtoQuoteline(B2.parent_id)=A.Name
	LEFT JOIN #tmpLoadedDeliverables C ON [dbo].udf_ConvertIDtoQuoteline(C.Parent_ID)=A.Name --C.Parent_ID=B.parent_id
	LEFT JOIN ProcessLog P ON [dbo].udf_ConvertIDtoQuoteline(P.Parent_ID)=A.Name
IF @testing=1 BEGIN
	SELECT * FROM #tmpPkgTotal

	--SELECT * FROM #tmpPkgPhases
	--SELECT MAX(B.Id) Id, 
	--	MAX(A.QuoteId) QuoteId, 
	--	MAX(Advantage_Job_Code__c) Advantage_Job_Code__c, 
	--	MAX(Campaign_Name) Campaign_Name, 
	--	MAX(Job_Name__c) Job_Name__c, 
	--	MAX(B.Name) Name, 
	--	A.CPQ_Package__c, 
	--	MIN(B.CPQ_Phase__c) CPQ_Phase__c, 
	--	MAX(CPQ_Mail_Ship_Date__c) CPQ_Mail_Ship_Date__c, 
	--	STRING_AGG(RIGHT(A.Name,6)+':'+SB_DM_Data_Selection_Criteria__c,CHAR(13)) SB_DM_Data_Selection_Criteria__c, 
	--	MAX(CPQ_Job_Specific_Name__c) CPQ_Job_Specific_Name__c, 
	--	MAX(B.SBQQ__Description__c) SBQQ__Description__c, 
	--	MAX(A.SBQQ__ProductName__c) SBQQ__ProductName__c, 
	--	MAX(A.SB_Ask_Array_Code__c) SB_Ask_Array_Code__c, 
	--	MAX(A.SB_DM_Multiplier__c) SB_DM_Multiplier__c,
	--	MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN B.CPQ_Phase__c ELSE NULL END) SB_RKD_Audience_Code__c, 
	--	MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_RKD_Audience__c ELSE NULL END) SB_RKD_Audience__c, 
	--	MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Creative_Name ELSE NULL END) SB_Creative_Name, 
	--	MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Creative_Code__c ELSE NULL END) SB_Creative_Code__c, 
	--	MAX(CASE WHEN B.CPQ_Phase__c=A.CPQ_Phase__c THEN A.SB_Abbreviation__c ELSE NULL END) SB_Abbreviation__c, 
	--	SUM(COALESCE(CPQ_Estimated_Quantity__c,0)) PackageQty, SUM(COALESCE(SB_DM_Prelim_Quantity__c,0)) PrelimQty
	--	FROM #tmpPkgPhases A JOIN (
	--		SELECT A.Id, A.Name, A.CPQ_Package__c, B.CPQ_Phase__c, A.SBQQ__Description__c
	--		FROM #tmpPkgPhases A JOIN (SELECT CPQ_Package__c, MIN(CPQ_Phase__c) CPQ_Phase__c FROM #tmpPkgPhases GROUP BY CPQ_Package__c
	--		) B ON B.CPQ_Package__c=A.CPQ_Package__c AND B.CPQ_Phase__c=A.CPQ_Phase__c) B ON B.CPQ_Package__c=A.CPQ_Package__c --AND B.CPQ_Phase__c=A.CPQ_Phase__c
	--	WHERE NOT (A.SB_RKD_Audience__c='Ship to Client' AND COALESCE(A.SB_DM_Data_Selection_Criteria__c,'')='')	--remove phases that doesn't need to be QC'd
	--	GROUP BY A.CPQ_Package__c 
			--B.Id, A.QuoteId, Advantage_Job_Code__c, Campaign_Name, Job_Name__c, B.Name, CPQ_Mail_Ship_Date__c, CPQ_Job_Specific_Name__c, A.CPQ_Package__c, B.SBQQ__Description__c, A.SBQQ__ProductName__c, A.SB_Ask_Array_Code__c, 
			--A.SB_DM_Multiplier__c, 
			--SB_RKD_Audience__c, SB_Creative_Name, SB_Creative_Code__c, SB_Abbreviation__c
END

--TEMPORARY until COMS field is added
--DECLARE @Vertical VARCHAR(50)
--SELECT @Vertical=Vertical
--FROM FileLog
--WHERE FileID=@FileID
--UPDATE #tmpPkgTotal SET Match_Multiplier__c=CASE WHEN @Vertical='Missions' THEN 3.49 ELSE 5.00 END

IF @testing=1 BEGIN
	SELECT * FROM #tmpPkgTotal
END ELSE BEGIN
	;
	WITH src AS (SELECT * FROM #tmpPkgTotal)
	MERGE INTO ProcessLog WITH (SERIALIZABLE) AS tgt
	USING src ON tgt.QuoteId = src.QuoteId AND tgt.Package_Code=src.CPQ_Package__c
	WHEN MATCHED AND (tgt.FileID<>src.FileID
			OR ISNULL(tgt.Campaign_name,'')<>ISNULL(src.Campaign_name,'')
			OR ISNULL(tgt.Job_Name,'')<>ISNULL(src.Job_Name__c,'')
			OR ISNULL(tgt.Job_Specific_Name,'')<>ISNULL(src.CPQ_Job_Specific_Name__c,'')
			OR ISNULL(tgt.SBQQ__ProductName__c,'')<>ISNULL(src.SBQQ__ProductName__c,'')
			OR ISNULL(tgt.Data_Selection_Criteria,'')<>ISNULL(src.SB_DM_Data_Selection_Criteria__c,'')
			OR tgt.Estimated_Qty<>src.PackageQty
			OR tgt.Prelim_Inv_Qty<>src.PrelimQty
			OR ISNULL(tgt.Mail_Date,'')<>ISNULL(src.CPQ_Mail_Ship_Date__c,'')
			OR ISNULL(tgt.QuoteLine_ID,'')<>ISNULL(src.Id,'')
			OR ISNULL(tgt.QuoteLine_Name,'')<>ISNULL(src.Name,'')
			OR ISNULL(tgt.Phase_Code,'')<>ISNULL(src.CPQ_Phase__c,'')
			OR ISNULL(tgt.AsktableCode,'')<>ISNULL(src.SB_Ask_Array_Code__c,'')
			OR tgt.Multiplier<>src.SB_DM_Multiplier__c
			OR ISNULL(tgt.AudienceName,'')<>ISNULL(src.SB_RKD_Audience__c,'')
			OR ISNULL(tgt.AudienceCode,'')<>ISNULL(src.SB_RKD_Audience_Code__c,'')
			OR ISNULL(tgt.CreativeName,'')<>ISNULL(src.SB_Creative_Name,'')
			OR ISNULL(tgt.CreativeCode,'')<>ISNULL(src.SB_Creative_Code__c,'')
			OR ISNULL(tgt.CreativeAbbreviated,'')<>ISNULL(src.SB_Abbreviation__c,'')
			OR tgt.Delivered_Qty<>src.TotalSelected
			OR tgt.Dups_Drop<>src.TotalDupDrops
			OR tgt.NCOA_Drop<>src.TotalNCOADrops)
			THEN UPDATE
		SET Estimated_Qty=src.PackageQty
			,FileID=src.FileID
			,Campaign_name=src.Campaign_name
			,Job_Specific_Name=src.CPQ_Job_Specific_Name__c
			,SBQQ__ProductName__c=src.SBQQ__ProductName__c
			,Data_Selection_Criteria=src.SB_DM_Data_Selection_Criteria__c
			,Prelim_Inv_Qty=src.PrelimQty
			,Mail_Date=src.CPQ_Mail_Ship_Date__c
	--		,QuoteID=src.QuoteID
			,QuoteLine_ID=src.Id
			,QuoteLine_Name=src.Name
			,Phase_Code=src.CPQ_Phase__c
			/*
			,Delivered_Qty=CASE WHEN tgt.FileID=src.FileID AND src.TotalSelected=0 THEN Delivered_Qty ELSE src.TotalSelected END
			,Dups_Drop=CASE WHEN tgt.FileID=src.FileID AND src.TotalDupDrops=0 THEN Dups_Drop ELSE src.TotalDupDrops END
			,NCOA_Drop=CASE WHEN tgt.FileID=src.FileID AND src.TotalNCOADrops=0 THEN NCOA_Drop ELSE src.TotalNCOADrops END
			*/
			,Delivered_Qty=src.TotalSelected
			,Dups_Drop=src.TotalDupDrops
			,NCOA_Drop=src.TotalNCOADrops
			,AsktableCode=src.SB_Ask_Array_Code__c
			,Multiplier=src.SB_DM_Multiplier__c
			,AudienceName=src.SB_RKD_Audience__c
			,AudienceCode=src.SB_RKD_Audience_Code__c
			,CreativeName=src.SB_Creative_Name
			,CreativeCode=src.SB_Creative_Code__c
			,CreativeAbbreviated=src.SB_Abbreviation__c
			--reset in case reload
			,QC_File=CASE WHEN tgt.FileID=src.FileID THEN QC_File ELSE NULL END
			,QC_Report=CASE WHEN tgt.FileID=src.FileID THEN QC_Report ELSE NULL END
			,NCOA_Link_Report=CASE WHEN tgt.FileID=src.FileID THEN NCOA_Link_Report ELSE NULL END
			,QC_Approved=CASE WHEN tgt.FileID=src.FileID THEN QC_Approved ELSE 0 END
			,Approved_Date=CASE WHEN tgt.FileID=src.FileID THEN Approved_Date ELSE NULL END
			,ApprovedBy = CASE WHEN tgt.FileID=src.FileID THEN ApprovedBy ELSE NULL END
			,Rejected_Date=CASE WHEN tgt.FileID=src.FileID THEN Rejected_Date ELSE NULL END
			,RejectedBy=CASE WHEN tgt.FileID=src.FileID THEN RejectedBy ELSE NULL END
			,Lettershop_FileName=CASE WHEN tgt.FileID=src.FileID THEN Lettershop_FileName ELSE NULL END
			,PromoHarvester_FileName=CASE WHEN tgt.FileID=src.FileID THEN PromoHarvester_FileName ELSE NULL END
			,[LastModifiedDate]=GETDATE()	
	WHEN NOT MATCHED BY SOURCE AND tgt.QuoteId IN (SELECT QuoteId FROM #tmpPkgTotal) THEN DELETE
	WHEN NOT MATCHED BY TARGET THEN INSERT(FileID, QuoteID, Campaign_Name, Job_Name, Job_Specific_Name, SBQQ__ProductName__c, QuoteLine_ID, QuoteLine_Name, Package_Code, Phase_Code, Estimated_Qty, Prelim_Inv_Qty, Delivered_Qty, Mail_Date, Data_Selection_Criteria, Dups_Drop, NCOA_Drop, AsktableCode, Multiplier, AudienceName, AudienceCode, CreativeName, CreativeCode, CreativeAbbreviated)
	VALUES(src.FileID, src.QuoteId, src.Campaign_Name, src.Job_Name__c, src.CPQ_Job_Specific_Name__c, src.SBQQ__ProductName__c, src.Id, src.Name, src.CPQ_Package__c, src.CPQ_Phase__c, src.PackageQty, src.PrelimQty, src.TotalSelected, src.CPQ_Mail_Ship_Date__c, dbo.udf_StripHTML(src.SB_DM_Data_Selection_Criteria__c), src.TotalDupDrops, src.TotalNCOADrops, src.SB_Ask_Array_Code__c, src.SB_DM_Multiplier__c, src.SB_RKD_Audience__c, src.SB_RKD_Audience_Code__c, src.SB_Creative_Name, src.SB_Creative_Code__c, src.SB_Abbreviation__c)
	;
END


