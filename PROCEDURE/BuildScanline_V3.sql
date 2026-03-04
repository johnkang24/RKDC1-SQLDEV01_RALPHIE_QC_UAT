
CREATE PROCEDURE [dbo].[BuildScanline_V3]
	@FileID INT,
	@partial BIT = 0
AS

DECLARE @testing BIT = 0
--TESTING
--DECLARE @FileID INT, @partial BIT = 0
--SET @FileID = 44
--SET @testing = 1

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000), @TSQL2 nvarchar(4000), @LinkedServer nvarchar(4000)
DECLARE @AccountID VARCHAR(50), @QuoteID VARCHAR(50), @PkgCode VARCHAR(10)
DECLARE @sb_category__c VARCHAR(MAX), @sb_type__c VARCHAR(MAX), @sb_field_content__c VARCHAR(MAX), @sb_position_length__c INT, @sb_default_text__c VARCHAR(MAX)
DECLARE @sb_sequence__c INT, @sourcename VARCHAR(MAX), @abbreviation VARCHAR(MAX), @sourceenvironment VARCHAR(MAX), @sourceobject VARCHAR(MAX), @sourcefield VARCHAR(MAX)
DECLARE @scanline VARCHAR(1000), @scanline1 VARCHAR(1000), @scanline2 VARCHAR(1000), @scanline3 VARCHAR(1000)
DECLARE @bc2d VARCHAR(1000), @bc2d1 VARCHAR(1000), @bc2d2 VARCHAR(1000), @bc2d2tmp VARCHAR(1000), @bc2d3 VARCHAR(1000)
DECLARE @bc3of9tmp VARCHAR(1000), @bc3of9 VARCHAR(1000), @tmpVar AS VARCHAR(1000)
DECLARE @errMesage nvarchar(max)
DECLARE @scanline1override BIT=1, @bc2d1override BIT=1, @bc2d2override BIT=1
DECLARE @sample_scanline VARCHAR(1000), @sample_bc2d1 VARCHAR(1000), @default_scanline VARCHAR(1000)

SET @errMesage = ''
SET @LinkedServer = 'COMS_UATSB'
SET @default_scanline = 'cc(full)-sp(2)-id(full)-sp(2)-ac(full)-sp(2)-rm(2)'

-------------------------------------------------------------------------------------
----STEP 1: check if data exists and if so make a backup
-------------------------------------------------------------------------------------
--IF OBJECT_ID('tempdb..#tmpOriginalBackup') IS NOT NULL
--    DROP TABLE #tmpOriginalBackup

--CREATE TABLE #tmpOriginalBackup
--(
--	Original_ID INT,
--	Scanline1 VARCHAR(50),
--	Scanline2 VARCHAR(50),
--	Scanline3 VARCHAR(50),
--	bc2d1 VARCHAR(50),
--	bc2d2 VARCHAR(50),
--	bc2d3 VARCHAR(50),
--	bc3of9 VARCHAR(50),
--)

--IF EXISTS ( SELECT TOP 1 parent_id
--FROM ORIGINAL
--WHERE parent_id=@FileID)
--BEGIN
--	INSERT #tmpOriginalBackup
--	SELECT Original_ID, scanline1, scanline2, scanline3, bc2d1, bc2d2, bc2d3, bc3of9
--	FROM ORIGINAL
--	WHERE parent_id=@FileID
--END

-----------------------------------------------------------------------------------
--STEP 1: fetch Adv Job # to use to pull detail data from COMS
-----------------------------------------------------------------------------------
SELECT @AccountID=B.AccountId, @QuoteID=QuoteID, @PkgCode=Package_Code
	FROM ProcessLog A JOIN Filelog B ON B.FileID=A.FileID
	WHERE B.FileID=@FileID

IF @testing=1 BEGIN
	PRINT '@AccountID='+@AccountID
	PRINT '@QuoteID='+@QuoteID
	PRINT '@PkgCode='+@PkgCode
END

-----------------------------------------------------------------------------------
--STEP 2: Get Deliveralbe details from COMS
-----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#tmpDeliverables') IS NOT NULL
    DROP TABLE #tmpDeliverables

CREATE TABLE #tmpDeliverables
(
	Id NVARCHAR(50),
	SB_Appeal_ID__c NVARCHAR(MAX),
	SB_RKD_Audience_Code__c NVARCHAR(MAX),
	CPQ_Package__c NVARCHAR(MAX),
	Scanline_Text_1 NVARCHAR(MAX),
	Scanline_Text_2 NVARCHAR(MAX),
)

SET @OPENQUERY = 'SELECT *, '''' Scanline_Text_1, '''' Scanline_Text_2
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, SB_Appeal_ID__c, SB_RKD_Audience_Code__c, CPQ_Package__c
	FROM SBQQ__QuoteLine__c
	WHERE SBQQ__Quote__c=''''' + CAST(@QuoteID AS VARCHAR(20)) + ''''' 
	AND SB_Deliverable_Category__c=''''Deliverable''''
	AND	CPQ_Package__c=''''' + @PkgCode + ''''' '')' 

IF @testing=1 BEGIN
	PRINT @OPENQUERY+@TSQL
END
INSERT #tmpDeliverables
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	SELECT * FROM #tmpDeliverables --ORDER BY SB_Category__c, SB_Type__c, SB_Sequence__c
END

-----------------------------------------------------------------------------------
--STEP 3: Get scanline text instructions from COMS	
-----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#tmpAllInstructions') IS NOT NULL
    DROP TABLE #tmpAllInstructions

CREATE TABLE #tmpAllInstructions
(
	Id VARCHAR(255),
	Deliverable_Element__c  NVARCHAR(MAX),
	Deliverable_Name NVARCHAR(MAX),
	Name NVARCHAR(255),
	Instruction_Value__c NVARCHAR(MAX),
)

SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT Id, Deliverable_Element__c, Deliverable_Element__r.Name,  Name, Instruction_Value__c
	FROM Deliverable_Element_Instruction__c 
	WHERE Name in (''''Scanline Text 1'''',''''Scanline Text 2'''')
	AND Deliverable_Element__r.SBQQ__Quote__c=''''' + @QuoteID + ''''' '')' 

INSERT #tmpAllInstructions
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	PRINT @OPENQUERY+@TSQL
	--SELECT A.*, B.*
	SELECT *
	FROM #tmpAllInstructions
END

--pivot to create columns instead of rows
IF OBJECT_ID('tempdb..#tmpInstructions') IS NOT NULL
    DROP TABLE #tmpInstructions
SELECT Deliverable_Element__c, CAST(RIGHT([Deliverable_Name],7) AS INT) Quote_ID, MAX([Scanline Text 1]) Scanline_Text_1, MAX([Scanline Text 2]) Scanline_Text_2
INTO #tmpInstructions
	FROM (SELECT Deliverable_Element__c, Deliverable_Name, [Scanline Text 1], [Scanline Text 2]
	FROM 
	(SELECT Deliverable_Element__c, Deliverable_Name, [Name], Instruction_Value__c
		FROM #tmpAllInstructions
		--WHERE Instruction_Value__c IS NOT NULL
		) AS SourceQuery
	PIVOT (
		MAX(Instruction_Value__c)
		FOR [Name] IN ([Scanline Text 1], [Scanline Text 2])
	) AS #PivotTable) A
GROUP BY Deliverable_Element__c, CAST(RIGHT([Deliverable_Name],7) AS INT)
IF @testing=1 BEGIN
	SELECT *
	FROM #tmpInstructions
END

-----------------------------------------------------------------------------------
--STEP 4A: Get scanline setting from COMS
-----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#tmpScanlines') IS NOT NULL
    DROP TABLE #tmpScanlines

CREATE TABLE #tmpScanlines
(
	SB_Category__c VARCHAR(MAX),
	SB_Type__c VARCHAR(MAX),
	Name NVARCHAR(MAX),
	SB_Scanline_Code__c NVARCHAR(MAX),
)

SET @OPENQUERY = 'SELECT *
	FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT SB_Category__c, SB_Type__c, Name, SB_Scanline_Code__c
  FROM SB_Scanline__c 
WHERE SB_Account__c  =''''' + CAST(@AccountID AS VARCHAR(20)) + ''''' '')' 

IF @testing=1 BEGIN
	PRINT @OPENQUERY+@TSQL
END
INSERT #tmpScanlines
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	SELECT *
	FROM #tmpScanlines

	IF NOT EXISTS (SELECT 1 FROM #tmpScanlines WHERE SB_Category__c='2D Barcode (BC2D1)' AND SB_Type__c='Built in Ralphie')
		BEGIN
			PRINT 'Blanking out bc2d1!'
		END
END ELSE BEGIN
	--clear scanline values before assigning
	IF NOT EXISTS (SELECT 1 FROM #tmpScanlines WHERE SB_Category__c='Keyline/Scanline' AND SB_Type__c='Built in Ralphie')
		BEGIN
			UPDATE ORIGINAL SET scanline1='', scanline2='', scanline3=''
			WHERE FileID=@FileID
		END
	ELSE
		BEGIN
			SET @scanline1override = 0
			SET @sample_scanline = @default_scanline
		END
	IF NOT EXISTS (SELECT 1 FROM #tmpScanlines WHERE SB_Category__c='2D Barcode (BC2D1)' AND SB_Type__c='Built in Ralphie')
		BEGIN
			UPDATE ORIGINAL SET bc2d1=''
			WHERE FileID=@FileID
		END
	ELSE
		BEGIN
			SET @bc2d1override = 0
			SET @sample_bc2d1 = @default_scanline
		END
	IF NOT EXISTS (SELECT 1 FROM #tmpScanlines WHERE SB_Category__c='Alt 2D Barcode (BC2D2)' AND SB_Type__c='Built in Ralphie')
		BEGIN
			UPDATE ORIGINAL SET bc2d2=''
			WHERE FileID=@FileID
		END
	ELSE
		BEGIN
			SET @bc2d2override = 0
		END
END

-----------------------------------------------------------------------------------
--STEP 4B: Get scanline definitions from COMS
-----------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#tmpScanlineDefinition') IS NOT NULL
    DROP TABLE #tmpScanlineDefinition

CREATE TABLE #tmpScanlineDefinition
(
	SB_Category__c VARCHAR(MAX),
	SB_Type__c VARCHAR(MAX),
	SB_Field_Content__c NVARCHAR(MAX),
	SB_Position_Length__c INT,
	SB_Default_Text__c NVARCHAR(MAX),
	SB_Sequence__c INT,
)

SET @OPENQUERY = 'SELECT *
	FROM OPENQUERY('+ @LinkedServer + ','''
--SET @OPENQUERY = 'SELECT * FROM OPENQUERY('+ @LinkedServer + ','''
SET @TSQL = 'SELECT SB_Scanline__r.SB_Category__c, SB_Scanline__r.SB_Type__c, 
       SB_Field_Content__c
      ,SB_Position_Length__c
      ,SB_Default_Text__c
      ,SB_Sequence__c
  FROM SB_Scanline_Item__c
WHERE SB_Scanline__r.SB_Account__c =''''' + CAST(@AccountID AS VARCHAR(20)) + ''''' 
	AND SB_Scanline__r.SB_Type__c != ''''Built in Ralphie'''' '')' 

IF @testing=1 BEGIN
	PRINT @OPENQUERY+@TSQL
END
INSERT #tmpScanlineDefinition
EXEC (@OPENQUERY+@TSQL)
IF @testing=1 BEGIN
	SELECT SB_Category__c, SB_Type__c, SB_Field_Content__c, SB_Position_Length__c, SB_Default_Text__c, SB_Sequence__c, SourceName, Abbreviation, SourceEnvironment, SourceObject, SourceField
	FROM #tmpScanlineDefinition A LEFT JOIN [dbo].[Scanline_Mapping] B ON B.SourceName=A.SB_Field_Content__c
	ORDER BY A.SB_Category__c, SB_Sequence__c
END


-----------------------------------------------------------------------------------
--STEP 5: Check for blank scanline text values if referenced in definition
--01.13.2026 UPDATED: also include checking default text missing 
-----------------------------------------------------------------------------------
IF EXISTS(SELECT SB_Category__c, SB_Type__c, SB_Field_Content__c, SB_Position_Length__c, SB_Default_Text__c, SB_Sequence__c, SourceName, Abbreviation, SourceEnvironment, SourceObject, SourceField
	FROM #tmpScanlineDefinition A JOIN [dbo].[Scanline_Mapping] B ON B.SourceName=A.SB_Field_Content__c
	WHERE B.SourceField = 'Scanline_Text_1' AND SB_Default_Text__c='') AND EXISTS(SELECT * FROM #tmpInstructions WHERE COALESCE(Scanline_Text_1,'')='') BEGIN
	UPDATE A SET Scanline_Error='Scanline not set due to missing scanline text 1'
	FROM ProcessLog A JOIN #tmpInstructions B ON B.Deliverable_Element__c=A.QuoteLine_ID 
		AND COALESCE(Scanline_Text_1,'')=''
	PRINT 'Exiting w/o updating scanline due to missing scanline text 1'
	RETURN
END
IF EXISTS(SELECT SB_Category__c, SB_Type__c, SB_Field_Content__c, SB_Position_Length__c, SB_Default_Text__c, SB_Sequence__c, SourceName, Abbreviation, SourceEnvironment, SourceObject, SourceField
	FROM #tmpScanlineDefinition A JOIN [dbo].[Scanline_Mapping] B ON B.SourceName=A.SB_Field_Content__c
	WHERE B.SourceField = 'Scanline_Text_2' AND SB_Default_Text__c='') AND EXISTS(SELECT * FROM #tmpInstructions WHERE COALESCE(Scanline_Text_2,'')='') BEGIN
	UPDATE A SET Scanline_Error='Scanline not set due to missing scanline text 2'
	FROM ProcessLog A JOIN #tmpInstructions B ON B.Deliverable_Element__c=A.QuoteLine_ID 
		AND COALESCE(Scanline_Text_2,'')=''
	PRINT 'Exiting w/o updating scanline due to missing scanline text 2'
	RETURN
END

-----------------------------------------------------------------------------------
--STEP 6: Query to build the scanline
-----------------------------------------------------------------------------------
DECLARE db_buildscanline CURSOR FOR 
SELECT SB_Category__c, SB_Type__c, SB_Field_Content__c, SB_Position_Length__c, SB_Default_Text__c, SB_Sequence__c, SourceName, Abbreviation, SourceEnvironment, SourceObject, SourceField
FROM #tmpScanlineDefinition A LEFT JOIN [dbo].[Scanline_Mapping] B ON B.SourceName=A.SB_Field_Content__c
--WHERE A.SB_Category__c='Keyline/Scanline'
ORDER BY A.SB_Category__c, SB_Sequence__c

OPEN db_buildscanline  
FETCH NEXT FROM db_buildscanline INTO @sb_category__c, @sb_type__c, @sb_field_content__c, @sb_position_length__c, @sb_default_text__c, @sb_sequence__c, @sourcename, @abbreviation, @sourceenvironment, @sourceobject, @sourcefield

SET @scanline1 = ''
SET @scanline2 = ''
SET @scanline3 = ''
SET @bc2d1 = ''
SET @bc2d2 = ''
SET @bc2d3 = ''
SET @bc3of9 = ''
SET @bc3of9tmp = ''
SET @sample_scanline = ''
SET @sample_bc2d1 = ''

WHILE @@FETCH_STATUS = 0  
BEGIN
	IF @testing=1 BEGIN
		PRINT @sb_category__c
	END

	SET @scanline = ''
	SET @bc2d = ''
	SET @bc2d2tmp = ''
	SET @bc3of9tmp = ''

	--SCANLINE
	IF @sb_category__c='Keyline/Scanline' BEGIN
		IF @scanline1 > '' BEGIN
			SET @scanline1 = @scanline1 + ', '
		END

		IF COALESCE(@sourceenvironment,'None')='None' BEGIN
			IF @sourcename='Tab' BEGIN
				SET @scanline = 'REPLICATE('+@sourceField+','+CAST(COALESCE(@sb_position_length__c,1) AS VARCHAR(10))+')'
			END ELSE BEGIN
				SET @scanline = '''' + REPLICATE(@sourceField,COALESCE(@sb_position_length__c,1)) + ''''
			END
		END ELSE IF COALESCE(@sourceobject,'')='SB_Scanline_Item__c' BEGIN
			SET @scanline =  '''' + TRIM(COALESCE(@sb_default_text__c,'')) + ''''
		END ELSE BEGIN
			SET @scanline = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @tmpVar = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @scanline = 'COALESCE(CASE '+@tmpVar+ ' WHEN '''' THEN NULL ELSE ' + @tmpVar + ' END,' + '''' + TRIM(COALESCE(@sb_default_text__c,'')) + '''' + ')'
		END
		--left zero fill
		IF COALESCE(@sourceenvironment,'None')<>'None' AND COALESCE(@sb_position_length__c,0) > 0 BEGIN
			SET @scanline = 'RIGHT(REPLICATE(''0'',' + CAST(@sb_position_length__c AS VARCHAR(10)) + ')+TRIM('+@scanline+'),'+CAST(@sb_position_length__c AS VARCHAR(10))+') '
		END
		SET @scanline1 = @scanline1 + @scanline
		IF @sample_scanline > '' BEGIN
			SET @sample_scanline = @sample_scanline + '-' + @abbreviation + '(' + COALESCE(CAST(@sb_position_length__c AS VARCHAR(10)),'full') + ')'
		END ELSE BEGIN
			SET @sample_scanline = @abbreviation + '(' + COALESCE(CAST(@sb_position_length__c AS VARCHAR(10)),'full') + ')'
		END
	END

	--BC2D1
	IF @sb_category__c='2D Barcode (BC2D1)' BEGIN
		IF @bc2d1>'' BEGIN
			SET @bc2d1 = @bc2d1 + ', '
		END

		IF COALESCE(@sourceenvironment,'None')='None' BEGIN
			IF @sourcename='Tab' BEGIN
				SET @bc2d = 'REPLICATE('+@sourceField+','+CAST(COALESCE(@sb_position_length__c,1) AS VARCHAR(10))+')'
			END ELSE BEGIN
				SET @bc2d = '''' + REPLICATE(@sourceField,COALESCE(@sb_position_length__c,1)) + ''''
			END
		END ELSE IF COALESCE(@sourceobject,'')='SB_Scanline_Item__c' BEGIN
			SET @bc2d = '''' + TRIM(COALESCE(@sb_default_text__c,'')) + ''''
		--END ELSE IF COALESCE(@sb_position_length__c,0) > 0 BEGIN
		--	SET @bc2d = '''' + RIGHT(REPLICATE('0',@sb_position_length__c)+TRIM(@sb_default_text__c),@sb_position_length__c) + ''''
		END ELSE BEGIN
			--SET @bc2d = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			--SET @bc2d = 'COALESCE(NULLIF('+REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield + ',''),'+TRIM(@sb_default_text__c) + ')'
			SET @tmpVar = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @bc2d = 'COALESCE(CASE '+@tmpVar+ ' WHEN '''' THEN NULL ELSE ' + @tmpVar + ' END,' + '''' + TRIM(COALESCE(@sb_default_text__c,'')) + '''' + ')'
		END

		--left zero fill
		IF COALESCE(@sourceenvironment,'None')<>'None' AND COALESCE(@sb_position_length__c,0) > 0 BEGIN
			--SET @bc2d = '''' + RIGHT(REPLICATE('0',@sb_position_length__c)+TRIM(@bc2d),@sb_position_length__c) + ''''
			SET @bc2d = 'RIGHT(REPLICATE(''0'',' + CAST(@sb_position_length__c AS VARCHAR(10)) + ')+TRIM('+@bc2d+'),'+CAST(@sb_position_length__c AS VARCHAR(10))+') '
		END
		SET @bc2d1 = @bc2d1 + @bc2d
		IF @sample_bc2d1 > '' BEGIN
			SET @sample_bc2d1 = @sample_bc2d1 + '-' + @abbreviation + '(' + COALESCE(CAST(@sb_position_length__c AS VARCHAR(10)),'full') + ')'
		END ELSE BEGIN
			SET @sample_bc2d1 = @abbreviation + '(' + COALESCE(CAST(@sb_position_length__c AS VARCHAR(10)),'full') + ')'
		END
	END

	--BC2D2
	IF @sb_category__c='Alt 2D Barcode (BC2D2)' BEGIN
		IF @bc2d2>'' BEGIN
			SET @bc2d2 = @bc2d2 + ', '
			SET @bc2d2tmp = @bc2d2tmp + ', '
		END

		IF COALESCE(@sourceenvironment,'None')='None' BEGIN
			IF @sourcename='Tab' BEGIN
				SET @bc2d2tmp = 'REPLICATE('+@sourceField+','+CAST(COALESCE(@sb_position_length__c,1) AS VARCHAR(10))+')'
			END ELSE BEGIN
				SET @bc2d2tmp = '''' + REPLICATE(@sourceField,COALESCE(@sb_position_length__c,1)) + ''''
			END
		END ELSE IF COALESCE(@sourceobject,'')='SB_Scanline_Item__c' BEGIN
			SET @bc2d2tmp = '''' + TRIM(COALESCE(@sb_default_text__c,'')) + ''''
		--END ELSE IF COALESCE(@sb_position_length__c,0) > 0 BEGIN
		--	SET @bc2d = '''' + RIGHT(REPLICATE('0',@sb_position_length__c)+TRIM(@sb_default_text__c),@sb_position_length__c) + ''''
		END ELSE BEGIN
			--SET @bc2d2tmp = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @tmpVar = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @bc2d2tmp = 'COALESCE(CASE '+@tmpVar+ ' WHEN '''' THEN NULL ELSE ' + @tmpVar + ' END,' + '''' + TRIM(COALESCE(@sb_default_text__c,'')) + '''' + ')'
		END

		--left zero fill
		IF COALESCE(@sourceenvironment,'None')<>'None' AND COALESCE(@sb_position_length__c,0) > 0 BEGIN
			SET @bc2d = '''' + RIGHT(REPLICATE('0',@sb_position_length__c)+TRIM(@bc2d),@sb_position_length__c) + ''''
			--SET @bc2d2tmp = 'RIGHT(REPLICATE(''0'',' + CAST(@sb_position_length__c AS VARCHAR(10)) + ')+TRIM('+@bc2d2tmp+'),'+CAST(@sb_position_length__c AS VARCHAR(10))+') '
		END
		SET @bc2d2 = @bc2d2 + @bc2d2tmp
	END

	--3of9
	IF @sb_category__c='3of9 Barcode' BEGIN
		IF @bc3of9>'' BEGIN
			SET @bc3of9 = @bc3of9 + ', '
		END

		IF COALESCE(@sourceenvironment,'None')='None' BEGIN
			IF @sourcename='Tab' BEGIN
				SET @bc3of9tmp = 'REPLICATE('+@sourceField+','+CAST(COALESCE(@sb_position_length__c,1) AS VARCHAR(10))+')'
			END ELSE BEGIN
				SET @bc3of9tmp = '''' + REPLICATE(@sourceField,COALESCE(@sb_position_length__c,1)) + ''''
			END
		END ELSE IF COALESCE(@sourceobject,'')='SB_Scanline_Item__c' BEGIN
			SET @bc3of9tmp = '''' + TRIM(COALESCE(@sb_default_text__c,'')) + ''''
		END ELSE BEGIN
			--SET @bc3of9tmp = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @tmpVar = REPLACE(REPLACE(@sourceObject,'SBQQ__Quoteline__c','C'),'ORIGINAL','A') + '.' + @sourcefield
			SET @bc3of9tmp = 'COALESCE(CASE '+@tmpVar+ ' WHEN '''' THEN NULL ELSE ' + @tmpVar + ' END,' + '''' + TRIM(COALESCE(@sb_default_text__c,'')) + '''' + ')'
		END
		--left zero fill
		IF COALESCE(@sourceenvironment,'None')<>'None' AND COALESCE(@sb_position_length__c,0) > 0 BEGIN
			--SET @bc3of9tmp = '''' + RIGHT(REPLICATE('0',@sb_position_length__c)+TRIM(@bc3of9tmp),@sb_position_length__c) + ''''
			SET @bc3of9tmp = 'RIGHT(REPLICATE(''0'',' + CAST(@sb_position_length__c AS VARCHAR(10)) + ')+TRIM('+@bc3of9tmp+'),'+CAST(@sb_position_length__c AS VARCHAR(10))+') '
		END
		SET @bc3of9 = @bc3of9 + @bc3of9tmp
	END

	FETCH NEXT FROM db_buildscanline INTO @sb_category__c, @sb_type__c, @sb_field_content__c, @sb_position_length__c, @sb_default_text__c, @sb_sequence__c, @sourcename, @abbreviation, @sourceenvironment, @sourceobject, @sourcefield
END
SET @scanline1 = 'CONCAT('+@scanline1 + ','''')'

IF @bc2d1>'' BEGIN
	SET @bc2d1 = 'CONCAT('+ @bc2d1 + ','''')'
END ELSE BEGIN
	SET @bc2d1 = ''''''
END
IF @bc2d2>'' BEGIN
	SET @bc2d2 = 'CONCAT('+ @bc2d2 + ','''')'
END ELSE BEGIN
	SET @bc2d2 = ''''''
END
IF @bc3of9>'' BEGIN
	SET @bc3of9 = 'CONCAT('+ @bc3of9 + ','''')'
END ELSE BEGIN
	SET @bc3of9 = ''''''
END

IF @testing=1 BEGIN
	PRINT '@scanline1='+@scanline1
	PRINT '@bc2d1='+@bc2d1
	PRINT '@bc2d2='+@bc2d2
	PRINT '@bc3of9='+@bc3of9
	PRINT '@sample_scanline='+@sample_scanline
	PRINT '@sample_bc2d1='+@sample_bc2d1
END

IF @testing=1 BEGIN
	SET @TSQL = 'SELECT A.Parent_ID, A.child_ID, B.QuoteLine_ID, A.id, A.client_code, A.appeal1, A.rm, C.SB_RKD_Audience_Code__c, A.scanline1, A.scanline2, A.scanline3, A.bc2d1, A.bc2d2, A.bc2d3, A.bc3of9, '
	SET @TSQL = @TSQL + @scanline1 + ' scanline1, CASE WHEN COALESCE(A.appeal2,'''''''')>'''''''' THEN ' + REPLACE(@scanline1,'appeal1','appeal2') + ' ELSE NULL END scanline2, CASE WHEN COALESCE(A.appeal3,'''')>'''''''' THEN ' + REPLACE(@scanline1,'appeal1','appeal3') + ' ELSE NULL END scanline3, '
	SET @TSQL = @TSQL + @bc2d1 + ' bc2d1, '+@bc2d2+' bc2d2, '
	SET @TSQL = @TSQL + @bc3of9 + ' bc3of9, Scanline_Processed=1 '
END ELSE BEGIN
	SET @TSQL = 'UPDATE A SET scanline1='
	SET @TSQL = @TSQL + IIF(@scanline1override=1,@scanline1,'scanline1') + ', scanline2=CASE WHEN COALESCE(A.appeal2,'''''''')>'''''''' THEN ' + REPLACE(@scanline1,'appeal1','appeal2') + ' ELSE NULL END, scanline3=CASE WHEN COALESCE(A.appeal3,'''')>'''''''' THEN ' + REPLACE(@scanline1,'appeal1','appeal3') + ' ELSE NULL END, bc2d1='
	SET @TSQL = @TSQL + IIF(@bc2d1override=1,@bc2d1,'bc2d1')  + ' , bc2d2='+IIF(@bc2d2override=1,@bc2d2,'bc2d2')+', bc3of9='
	SET @TSQL = @TSQL + @bc3of9 + ', Scanline_Processed=1 '
END
SET @TSQL = @TSQL + ' FROM ORIGINAL A JOIN ProcessLog B ON B.FileID=A.FileID'
SET @TSQL = @TSQL + ' JOIN #tmpDeliverables C ON B.QuoteLine_ID=C.Id'
SET @TSQL = @TSQL + ' LEFT JOIN #tmpInstructions ON CASE WHEN COALESCE(A.child_ID,'''')='''' THEN CAST(A.parent_ID AS INT) ELSE CAST(A.child_ID AS INT) END=#tmpInstructions.Quote_ID'
--SET @TSQL = @TSQL + ' LEFT JOIN #tmpDeliverables C2 ON B.QuoteLine_ID=C2.Id AND C2.SB_Category__c=''2D Barcode (BC2D1)'''
--SET @TSQL = @TSQL + ' LEFT JOIN #tmpDeliverables C3 ON B.QuoteLine_ID=C3.Id AND C3.SB_Category__c=''3of9 Barcode'''
SET @TSQL = @TSQL + ' WHERE A.FileID=' + CAST(@FileID AS VARCHAR(10))

IF @partial=1 BEGIN
	SET @TSQL = @TSQL + ' AND A.Scanline_Processed=0'
END

CLOSE db_buildscanline  
DEALLOCATE db_buildscanline

IF @testing=1 BEGIN
	SELECT @TSQL
	SET @TSQL = @TSQL + ' ORDER BY A.parent_ID, A.child_ID'
	PRINT @TSQL
	EXEC (@TSQL)
END ELSE BEGIN
--BEGIN TRANSACTION [Trans1]

	BEGIN TRY
		--enable this part if we don't want to activate the trigger to create change history as this would generate a lot of records
		--SET @TSQL2 = 'ALTER TABLE table_name DISABLE TRIGGER Original_ChangeLog_After'
		--EXEC (@TSQL2)
		EXEC (@TSQL)
		--SET @TSQL2 = 'ALTER TABLE table_name ENABLE TRIGGER Original_ChangeLog_After'
		--EXEC (@TSQL2)
		PRINT @sample_scanline
		UPDATE FileLog SET Sample_Scanline=@sample_scanline, Sample_BC2D1=@sample_bc2d1
		WHERE FileID=@FileID

		--JCK:11.24.2025 - added check condition that all records have been flagged as scanline processed
		IF NOT EXISTS(SELECT COUNT(*) FROM ORIGINAL WHERE FileID=@FileID AND Scanline_Processed<>1) BEGIN
			UPDATE ProcessLog SET Scanline_Processed=1
			WHERE FileID=@FileID
		END
	END TRY
	BEGIN CATCH
--		ROLLBACK TRANSACTION [Trans1]
		SELECT 'Error In builiding scanlines'
		SET @errMesage  = ERROR_MESSAGE()
		RAISERROR(@errMesage, 16, 0)
	END CATCH
END


