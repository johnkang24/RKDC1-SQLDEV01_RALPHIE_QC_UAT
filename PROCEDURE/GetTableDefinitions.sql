
CREATE PROCEDURE [dbo].[GetTableDefinitions]
(
  @SystemName NVARCHAR(128)
, @DatabaseName NVARCHAR(128)
, @SchemaName NVARCHAR(128)
, @linkedserver BIT
, @linkedservername NVARCHAR(128)
)

AS

/*
DECLARE  @SystemName NVARCHAR(128)
, @DatabaseName NVARCHAR(128)
, @SchemaName NVARCHAR(128)
, @linkedserver BIT
, @linkedservername NVARCHAR(128)
SET @SystemName=''
SET @DatabaseName='RALPHIE_QA'
SET @SchemaName = ''
SET @linkedserver=0
SET @linkedservername=''
*/

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @sql1 NVARCHAR(MAX) = N'';
DECLARE @inSchemaName NVARCHAR(MAX) = N'';

SELECT @inSchemaName = CASE WHEN @SchemaName = N'All' THEN N's.[name]' ELSE '''' + @SchemaName + '''' END;

IF @linkedserver = 0
BEGIN

SELECT @sql = N'
SET NOCOUNT ON;

--- options ---
DECLARE @UseTransaction BIT = 0; 
DECLARE @GenerateUseDatabase BIT = 0;
DECLARE @GenerateFKs BIT = 0;
DECLARE @GenerateIdentity BIT = 1;
DECLARE @GenerateCollation BIT = 0;
DECLARE @GenerateCreateTable BIT = 1;
DECLARE @GenerateIndexes BIT = 0;
DECLARE @GenerateConstraints BIT = 1;
DECLARE @GenerateKeyConstraints BIT = 1;
DECLARE @GenerateConstraintNameOfDefaults BIT = 1;
DECLARE @GenerateDropIfItExists BIT = 0;
DECLARE @GenerateDropFKIfItExists BIT = 0;
DECLARE @GenerateDelete BIT = 0;
DECLARE @GenerateInsertInto BIT = 0;
DECLARE @GenerateIdentityInsert INT = 0; --0 ignore set,but add column; 1 generate; 2 ignore set AND column
DECLARE @GenerateSetNoCount INT = 0; --0 ignore set,1=set on, 2=set off 
DECLARE @GenerateMessages BIT = 0; --print with no wait
DECLARE @GenerateDataCompressionOptions BIT = 0; --TODO: generates the compression option only of the TABLE, not the indexes
                                                    --NB: the compression options reflects the design VALUE.
                                                    --The actual compression of a the page is saved here
--- variables ---
DECLARE @DataTypeSpacer INT = 1; --this is just to improve the formatting of the script ...
DECLARE @name SYSNAME;
DECLARE @sql NVARCHAR(MAX) = N'''';
DECLARE @int INT = 1;
DECLARE @maxint INT;
DECLARE @SourceDatabase NVARCHAR(MAX) = N''' + @DatabaseName + '''; --this is used by the INSERT 
DECLARE @TargetDatabase NVARCHAR(MAX) = N''' + @DatabaseName + '''; --this is used by the INSERT AND USE <DBName>
DECLARE @cr NVARCHAR(20) = NCHAR(13);
DECLARE @tab NVARCHAR(20) = NCHAR(9);

DECLARE @Tables TABLE
(
      id INT IDENTITY(1,1)
    , [name] SYSNAME
    , [object_id] INT 
    , [database_id] SMALLINT
);

BEGIN 

    INSERT INTO @Tables([name], [object_id], [database_id])
    SELECT s.[name] + N''.'' + t.[name] AS [name]
        , t.[object_id]
        , DB_ID(''' + @DatabaseName + ''') AS [database_id]
    FROM [' + @DatabaseName + '].sys.tables t
        JOIN [' + @DatabaseName + '].sys.schemas s ON t.[schema_id] = s.[schema_id]
    WHERE t.[name] NOT IN (''Tally'',''LOC_AND_SEG_CAP1'',''LOC_AND_SEG_CAP2'',''LOC_AND_SEG_CAP3'',''LOC_AND_SEG_CAP4'',''TableNames'')
        AND s.[name] = ' + @inSchemaName + '
    ORDER BY s.[name], t.[name];

    SELECT @maxint = COUNT(0) 
    FROM @Tables;

    WHILE @int <= @maxint
    BEGIN

        ;WITH 
        index_column AS 
        (
            SELECT ic.[object_id]
                , OBJECT_NAME(ic.[object_id], DB_ID(N''' + @DatabaseName + ''')) AS ObjectName
                , ic.index_id
                , ic.is_descending_key
                , ic.is_included_column
                , c.[name] 
            FROM [' + @DatabaseName + '].sys.index_columns ic WITH (NOLOCK)
                JOIN [' + @DatabaseName + '].sys.columns c WITH (NOLOCK) ON ic.[object_id] = c.[object_id] 
                    AND ic.column_id = c.column_id
                JOIN [' + @DatabaseName + '].sys.tables t ON c.[object_id] = t.[object_id]
        ) 
        , fk_columns AS 
        (
            SELECT k.constraint_object_id
                , cname = c.[name]
                , rcname = rc.[name]
            FROM [' + @DatabaseName + '].sys.foreign_key_columns k WITH (NOWAIT)
                JOIN [' + @DatabaseName + '].sys.columns rc WITH (NOWAIT) ON rc.[object_id] = k.referenced_object_id 
                    AND rc.column_id = k.referenced_column_id 
                JOIN [' + @DatabaseName + '].sys.columns c WITH (NOWAIT) ON c.[object_id] = k.parent_object_id 
                    AND c.column_id = k.parent_column_id
                JOIN [' + @DatabaseName + '].sys.tables t ON c.[object_id] = t.[object_id]
            WHERE @GenerateFKs = 1
        )
        SELECT @sql = @sql +

            --------------------  USE DATABASE   --------------------------------------------------------------------------------------------------
                CAST(
                    CASE WHEN @GenerateUseDatabase = 1
                    THEN N''USE '' + @TargetDatabase + N'';'' + @cr
                    ELSE N'''' END 
                AS NVARCHAR(200))
                +
            --------------------  SET NOCOUNT   --------------------------------------------------------------------------------------------------
                CAST(
                    CASE @GenerateSetNoCount 
                    WHEN 1 THEN N''SET NOCOUNT ON;'' + @cr
                    WHEN 2 THEN N''SET NOCOUNT OFF;'' + @cr
                    ELSE N'''' END 
                AS NVARCHAR(MAX))
                +
            --------------------  USE TRANSACTION  --------------------------------------------------------------------------------------------------
                CAST(
                    CASE WHEN @UseTransaction = 1
                    THEN 
                        N''SET XACT_ABORT ON'' + @cr
                        + N''BEGIN TRY'' + @cr
                        + N''BEGIN TRAN'' + @cr
                    ELSE N'''' END 
                AS NVARCHAR(MAX))
                +
            --------------------  DROP SYNONYM   --------------------------------------------------------------------------------------------------
                CASE WHEN @GenerateDropIfItExists = 1
                THEN CAST(N''IF OBJECT_ID('''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''',''''SN'''') IS NOT NULL DROP SYNONYM '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'';'' + @cr AS NVARCHAR(MAX))
                ELSE CAST(N'''' AS NVARCHAR(MAX))   END 
                +
            --------------------  DROP TABLE IF EXISTS --------------------------------------------------------------------------------------------------
                CASE WHEN @GenerateDropIfItExists = 1
                THEN 
                    --Drop TABLE if EXISTS
                    CAST(N''IF OBJECT_ID('''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''',''''U'''') IS NOT NULL DROP TABLE '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'';'' + @cr AS NVARCHAR(MAX))
                    + @cr
                ELSE N'''' END 
                +
            --------------------  DROP CONSTRAINT IF EXISTS --------------------------------------------------------------------------------------------------
                CAST((CASE WHEN @GenerateMessages = 1 AND @GenerateDropFKIfItExists = 1 THEN 
                    N''RAISERROR(''''DROP CONSTRAINTS OF %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr            
                ELSE N'''' END) AS NVARCHAR(MAX)) 
                +
                CASE WHEN @GenerateDropFKIfItExists = 1
                THEN 
                    --Drop foreign keys
                    ISNULL(((
                        SELECT 
                            CAST(
                                N''ALTER TABLE '' + QUOTENAME(s.[name]) + N''.'' + QUOTENAME(t.[name]) + N'' DROP CONSTRAINT '' + RTRIM(f.[name]) + N'';'' + @cr
                            AS NVARCHAR(MAX))
                        FROM [' + @DatabaseName + '].sys.tables t
                            INNER JOIN [' + @DatabaseName + '].sys.foreign_keys f ON f.parent_object_id = t.[object_id]
                            INNER JOIN [' + @DatabaseName + '].sys.schemas s ON s.[schema_id] = f.[schema_id]
                        WHERE f.referenced_object_id = t.[object_id]
                        FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''))
                    , N'''') + @cr
                ELSE N'''' END 
            +
            --------------------- CREATE TABLE -----------------------------------------------------------------------------------------------------------------
            CAST((CASE WHEN @GenerateMessages = 1 THEN 
                N''RAISERROR(''''CREATE TABLE %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr           
            ELSE CAST(N'''' AS NVARCHAR(MAX)) END) AS NVARCHAR(MAX)) 
            +
            CASE WHEN @GenerateCreateTable = 1 THEN 
                CAST(
                    N''CREATE TABLE '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + @cr + N''('' + @cr + STUFF((
                    SELECT 
                        CAST(
                            @tab + N'','' + QUOTENAME(c.[name]) + N'' '' + ISNULL(REPLICATE('' '',@DataTypeSpacer - LEN(QUOTENAME(c.[name]))),'''') 
                            +  
                            CASE WHEN c.is_computed = 1
                                THEN N'' AS '' + cc.[definition] 
                                ELSE UPPER(tp.[name]) + 
                                    CASE WHEN tp.[name] IN (N''varchar'', N''char'', N''varbinary'', N''binary'', N''text'')
                                            THEN N''('' + CASE WHEN c.max_length = -1 THEN N''MAX'' ELSE CAST(c.max_length AS NVARCHAR(5)) END + N'')''
                                            WHEN tp.[name] IN (N''NVARCHAR'', N''nchar'', N''ntext'')
                                            THEN N''('' + CASE WHEN c.max_length = -1 THEN N''MAX'' ELSE CAST(c.max_length / 2 AS NVARCHAR(5)) END + N'')''
                                            WHEN tp.[name] IN (N''datetime2'', N''time2'', N''datetimeoffset'') 
                                            THEN N''('' + CAST(c.scale AS NVARCHAR(5)) + N'')''
                                            WHEN tp.[name] = N''decimal'' 
                                            THEN N''('' + CAST(c.[precision] AS NVARCHAR(5)) + N'','' + CAST(c.scale AS NVARCHAR(5)) + N'')''
                                        ELSE N''''
                                    END +
                                    CASE WHEN c.collation_name IS NOT NULL AND @GenerateCollation = 1 THEN N'' COLLATE '' + c.collation_name ELSE N'''' END +
                                    CASE WHEN c.is_nullable = 1 THEN N'' NULL'' ELSE N'' NOT NULL'' END +
                                    CASE WHEN dc.[definition] IS NOT NULL THEN CASE WHEN @GenerateConstraintNameOfDefaults = 1 THEN N'' CONSTRAINT '' + QUOTENAME(dc.[name]) ELSE N'''' END + N'' DEFAULT'' + dc.[definition] ELSE N'''' END + 
                                    CASE WHEN ic.is_identity = 1 AND @GenerateIdentity = 1 THEN N'' IDENTITY('' + CAST(ISNULL(ic.seed_value, N''0'') AS NCHAR(1)) + N'','' + CAST(ISNULL(ic.increment_value, N''1'') AS NCHAR(1)) + N'')'' ELSE N'''' END 
                            END + @cr
                        AS NVARCHAR(MAX)) 
                    FROM [' + @DatabaseName + '].sys.columns c WITH (NOWAIT)
                        INNER JOIN [' + @DatabaseName + '].sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
                        LEFT JOIN [' + @DatabaseName + '].sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] 
                            AND c.column_id = cc.column_id
                        LEFT JOIN [' + @DatabaseName + '].sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 
                            AND c.[object_id] = dc.parent_object_id 
                            AND c.column_id = dc.parent_column_id
                        LEFT JOIN [' + @DatabaseName + '].sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 
                            AND c.[object_id] = ic.[object_id] 
                            AND c.column_id = ic.column_id
                    WHERE c.[object_id] = t.[object_id]
                    ORDER BY c.column_id
                    FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, @tab + N'' '') AS NVARCHAR(MAX))
            ELSE CAST(N'''' AS NVARCHAR(MAX)) END 
            + 
            ---------------------- Key Constraints ----------------------------------------------------------------
            CAST(
                CASE WHEN @GenerateKeyConstraints <> 1 THEN N'''' 
                ELSE 
                    ISNULL((SELECT @tab + N'', CONSTRAINT '' + QUOTENAME(k.[name]) + N'' PRIMARY KEY '' + ISNULL(kidx.[type_desc], N'''') + N''('' + 
                                (SELECT STUFF((
                                    SELECT N'', '' + QUOTENAME(c.[name]) + N'' '' + CASE WHEN ic.is_descending_key = 1 THEN N''DESC'' ELSE N''ASC'' END
                                    FROM [' + @DatabaseName + '].sys.index_columns ic WITH (NOWAIT)
                                        JOIN [' + @DatabaseName + '].sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] 
                                            AND c.column_id = ic.column_id
                                    WHERE ic.is_included_column = 0
                                        AND ic.[object_id] = k.parent_object_id 
                                        AND ic.index_id = k.unique_index_id     
                                    FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, N''''))
                        + N'')'' + @cr
                        FROM [' + @DatabaseName + '].sys.key_constraints k WITH (NOWAIT) 
                            LEFT JOIN [' + @DatabaseName + '].sys.indexes kidx ON k.parent_object_id = kidx.[object_id] 
                                AND k.unique_index_id = kidx.index_id
                        WHERE k.parent_object_id = t.[object_id] 
                            AND k.[type] = N''PK''), N'''') + N'')''  + @cr
                END 
            AS NVARCHAR(MAX))
            +
            CAST(
            CASE 
                WHEN @GenerateDataCompressionOptions = 1 AND (SELECT TOP 1 data_compression_desc FROM [' + @DatabaseName + '].sys.partitions WHERE OBJECT_ID = t.[object_id] AND index_id = 1) <> N''NONE''
                THEN N''WITH (DATA_COMPRESSION='' + (SELECT TOP 1 data_compression_desc FROM [' + @DatabaseName + '].sys.partitions WHERE OBJECT_ID = t.[object_id] AND index_id = 1) + N'')'' + @cr
                ELSE N'''' + @cr
            END AS NVARCHAR(MAX))
            + 
            --------------------- FOREIGN KEYS -----------------------------------------------------------------------------------------------------------------
            CAST((CASE WHEN @GenerateMessages = 1 AND @GenerateDropFKIfItExists = 1 THEN 
                N''RAISERROR(''''CREATING FK OF  %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr            
            ELSE N'''' END) AS NVARCHAR(MAX)) 
            +
            CAST(
                ISNULL((SELECT (
                    SELECT @cr +
                    N''ALTER TABLE '' +  QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) +  N'' WITH'' 
                    + CASE WHEN fk.is_not_trusted = 1 
                        THEN N'' NOCHECK'' 
                        ELSE N'' CHECK'' 
                    END + 
                    N'' ADD CONSTRAINT '' + QUOTENAME(fk.[name])  + N'' FOREIGN KEY('' 
                    + STUFF((
                        SELECT N'', '' + QUOTENAME(k.cname) + N''''
                        FROM fk_columns k
                        WHERE k.constraint_object_id = fk.[object_id]
                            AND fk.[object_id] = t.[object_id]
                        FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, N'''')
                    + N'')'' +
                    N'' REFERENCES '' + QUOTENAME(SCHEMA_NAME(ro.[schema_id])) + N''.'' + QUOTENAME(ro.[name]) + N'' (''
                    + STUFF((
                        SELECT N'', '' + QUOTENAME(k.rcname) + N''''
                        FROM fk_columns k
                        WHERE k.constraint_object_id = fk.[object_id]
                            AND fk.[object_id] = t.[object_id]
                        FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, N'''')
                    + N'')''
                    + CASE 
                        WHEN fk.delete_referential_action = 1 THEN N'' ON DELETE CASCADE'' 
                        WHEN fk.delete_referential_action = 2 THEN N'' ON DELETE SET NULL''
                        WHEN fk.delete_referential_action = 3 THEN N'' ON DELETE SET DEFAULT'' 
                        ELSE N'''' 
                    END
                    + CASE 
                        WHEN fk.update_referential_action = 1 THEN N'' ON UPDATE CASCADE''
                        WHEN fk.update_referential_action = 2 THEN N'' ON UPDATE SET NULL''
                        WHEN fk.update_referential_action = 3 THEN N'' ON UPDATE SET DEFAULT''  
                        ELSE N'''' 
                    END 
                    + @cr + N''ALTER TABLE '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'' CHECK CONSTRAINT '' + QUOTENAME(fk.[name])  + N'''' + @cr
                FROM [' + @DatabaseName + '].sys.foreign_keys fk WITH (NOWAIT)
                    JOIN [' + @DatabaseName + '].sys.objects ro WITH (NOWAIT) ON ro.[object_id] = fk.referenced_object_id
                WHERE fk.parent_object_id = t.[object_id]
                FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)'')), N'''')
            AS NVARCHAR(MAX))
            + 
            --------------------- INDEXES ----------------------------------------------------------------------------------------------------------
            CAST((CASE WHEN @GenerateMessages = 1 AND @GenerateIndexes = 1 THEN 
                N''RAISERROR(''''CREATING INDEXES OF  %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr           
            ELSE N'''' END) AS NVARCHAR(MAX)) 
            +
            CASE WHEN @GenerateIndexes = 1 THEN 
                CAST(
                    ISNULL(((SELECT
                        @cr + N''CREATE'' + CASE WHEN i.is_unique = 1 THEN N'' UNIQUE '' ELSE N'' '' END 
                                + i.[type_desc] + N'' INDEX '' + QUOTENAME(i.[name]) + N'' ON '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'' ('' +
                                STUFF((
                                SELECT N'', '' + QUOTENAME(c.[name]) + N'''' + CASE WHEN c.is_descending_key = 1 THEN N'' DESC'' ELSE N'' ASC'' END
                                FROM index_column c
                                WHERE c.is_included_column = 0
                                    AND c.[object_id] = t.[object_id]
                                    AND c.index_id = i.index_id
                                FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, N'''') + N'')''  
                                + ISNULL(@cr + N''INCLUDE ('' + 
                                    STUFF((
                                    SELECT N'', '' + QUOTENAME(c.[name]) + N''''
                                    FROM index_column c
                                    WHERE c.is_included_column = 1
                                        AND c.[object_id] = t.[object_id]
                                        AND c.index_id = i.index_id
                                    FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)''), 1, 2, N'''') + N'')'', N'''')  + @cr
                        FROM [' + @DatabaseName + '].sys.indexes i WITH (NOWAIT)
                        WHERE i.[object_id] = t.[object_id]
                            AND i.is_primary_key = 0
                            AND i.[type] in (1,2)
                            AND @GenerateIndexes = 1
                        FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)'')
                    ), N'''')
                AS NVARCHAR(MAX))
            ELSE N'''' END 
            +
            ------------------------  @GenerateDelete     ----------------------------------------------------------
            CAST((CASE WHEN @GenerateMessages = 1 AND @GenerateDelete = 1 THEN 
                N''RAISERROR(''''TRUNCATING  %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr            
            ELSE N'''' END) AS NVARCHAR(MAX)) 
            +
            CASE WHEN @GenerateDelete = 1 THEN
                CAST(
                    (CASE WHEN EXISTS (SELECT TOP 1 [name] FROM [' + @DatabaseName + '].sys.foreign_keys WHERE referenced_object_id = t.[object_id]) THEN 
                        N''DELETE FROM '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'';'' + @cr
                    ELSE
                        N''TRUNCATE TABLE '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'';'' + @cr
                    END)
                AS NVARCHAR(MAX))
            ELSE N'''' END 
            +
            ------------------------- @GenerateInsertInto ----------------------------------------------------------
            CAST((CASE WHEN @GenerateMessages = 1 AND @GenerateDropFKIfItExists = 1 THEN 
                N''RAISERROR(''''INSERTING INTO  %s'''',10,1, '''''' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'''''') WITH NOWAIT;'' + @cr            
            ELSE N'''' END) AS NVARCHAR(MAX)) 
            +
            CASE WHEN @GenerateInsertInto = 1
            THEN 
                CAST(
                        CASE WHEN EXISTS (SELECT TOP 1 c.[name] FROM [' + @DatabaseName + '].sys.columns c WHERE c.[object_id] = t.[object_id] AND c.is_identity = 1) AND @GenerateIdentityInsert = 1 THEN 
                            N''SET IDENTITY_INSERT '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'' ON;'' + @cr
                        ELSE N'''' END 
                        +
                        N''INSERT INTO '' + QUOTENAME(@TargetDatabase) + N''.'' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N''('' 
                        + @cr
                        +
                        (
                            @tab + N'' '' + SUBSTRING(
                                (
                                SELECT @tab + '',''+ QUOTENAME(c.[name]) + @cr 
                                FROM [' + @DatabaseName + '].sys.columns c 
                                WHERE c.[object_id] = t.[object_id] 
                                    AND c.system_type_ID <> 189 /*timestamp*/ 
                                    AND c.is_computed = 0
                                    AND (c.is_identity = 0 or @GenerateIdentityInsert in (0,1))
                                FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)'')
                            ,3,99999)

                        )
                        + N'')'' + @cr + N''SELECT '' 
                        + @cr
                        +
                        (
                            @tab + N'' '' + SUBSTRING(
                                (
                                SELECT @tab + '',''+ QUOTENAME(c.[name]) + @cr 
                                FROM [' + @DatabaseName + '].sys.columns c 
                                WHERE c.[object_id] = t.[object_id] 
                                    AND c.system_type_ID <> 189 /*timestamp*/ 
                                    AND c.is_computed = 0                     
                                    AND (c.is_identity = 0 or @GenerateIdentityInsert  in (0,1))
                                FOR XML PATH(N''''), TYPE).value(N''.'', N''NVARCHAR(MAX)'')
                            ,3,99999)
                        )
                        + N''FROM '' + @SourceDatabase +  N''.'' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id]))            
                        + N'';'' + @cr
                        + CASE WHEN EXISTS (SELECT TOP 1 c.[name] FROM [' + @DatabaseName + '].sys.columns c WHERE c.[object_id] = t.[object_id] AND c.is_identity = 1) AND @GenerateIdentityInsert = 1 THEN 
                            N''SET IDENTITY_INSERT '' + QUOTENAME(OBJECT_SCHEMA_NAME(t.[object_id], t.[database_id])) + N''.'' + QUOTENAME(OBJECT_NAME(t.[object_id], t.[database_id])) + N'' OFF;''+ @cr
                        ELSE N'''' END              
                AS NVARCHAR(MAX))
            ELSE N'''' END 
            +
            --------------------  USE TRANSACTION  --------------------------------------------------------------------------------------------------
            CAST(
                CASE WHEN @UseTransaction = 1
                THEN 
                    @cr + N''COMMIT TRAN; ''
                    + @cr + N''END TRY''
                    + @cr + N''BEGIN CATCH''
                    + @cr + N''  IF XACT_STATE() IN (-1,1)''
                    + @cr + N''      ROLLBACK TRAN;''
                    + @cr + N''''
                    + @cr + N''  SELECT   ERROR_NUMBER() AS ErrorNumber  ''
                    + @cr + N''          ,ERROR_SEVERITY() AS ErrorSeverity  ''
                    + @cr + N''          ,ERROR_STATE() AS ErrorState  ''
                    + @cr + N''          ,ERROR_PROCEDURE() AS ErrorProcedure  ''
                    + @cr + N''          ,ERROR_LINE() AS ErrorLine  ''
                    + @cr + N''          ,ERROR_MESSAGE() AS ErrorMessage; ''
                    + @cr + N''END CATCH''
                ELSE N'''' END 
            AS NVARCHAR(700))
        FROM @Tables t
        WHERE ID = @int
        ORDER BY [name]; 
    
        SET @int = @int + 1;
    
    END

    EXEC [master].dbo.PrintMax @sql;
/* see below for PrintMax code*/

END'

--EXEC (@sql);
SELECT @sql

END
ELSE
BEGIN

SELECT @sql = N'EXECUTE (''
SET NOCOUNT ON;
BEGIN

... Same code but be sure to double up on your single quotes

END

... code for the printmax proc (not mine, @Ben B) because it may not exist at destination server

    DECLARE @CurrentEnd BIGINT; /* track the length of the next substring */
    DECLARE @offset TINYINT; /*tracks the amount of offset needed */
    DECLARE @String NVARCHAR(MAX);
    SET @String = REPLACE(REPLACE(@sql, CHAR(13) + CHAR(10), CHAR(10)), CHAR(13), CHAR(10))

    WHILE LEN(@String) > 1
    BEGIN
        IF CHARINDEX(CHAR(10), @String) BETWEEN 1 AND 4000
        BEGIN
            SET @CurrentEnd = CHARINDEX(CHAR(10), @String) -1
            SET @offset = 2
        END
        ELSE
        BEGIN
            SET @CurrentEnd = 4000
            SET @offset = 1
        END   
        PRINT SUBSTRING(@String, 1, @CurrentEnd) 
        SET @String = SUBSTRING(@String, @CurrentEnd + @offset, LEN(@String))   
    END

END'') AT [' + @linkedservername + ']';

--EXEC (@sql);
SELECT @sql;

END

