CREATE PROCEDURE [dbo].[Acquisition_PostLoad]
	@FileID INT
AS

DECLARE @testing BIT = 0
--TESTING
----DECLARE @FileID INT
----SET @FileID = 30

DECLARE @OPENQUERY nvarchar(4000), @TSQL nvarchar(4000)

SET @TSQL = 'UPDATE ORIGINAL SET rm=list, serial=id WHERE FileID=' + CAST(@FileID AS VARCHAR(10)) + ' WHERE mailtype IN (''P'',''B'',''S'')'
PRINT @TSQL
EXEC (@TSQL)


