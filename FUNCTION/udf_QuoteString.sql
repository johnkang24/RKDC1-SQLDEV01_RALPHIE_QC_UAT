CREATE FUNCTION [dbo].[udf_QuoteString] (@inputString VARCHAR(MAX))
RETURNS VARCHAR(MAX) AS
BEGIN
    RETURN CASE WHEN CHARINDEX(',',@inputString)>0 THEN '"'+@inputString+'"' ELSE @inputString END
END


