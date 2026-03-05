-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[udf_TransformRM]
(	
	@rm VARCHAR(50)
)

RETURNS VARCHAR(50)
BEGIN
	DECLARE @retval VARCHAR(50)

	SET @retval = CASE WHEN CHARINDEX(LEFT(@rm,1),'ABCDEF') > 0 AND PATINDEX('%[^a-zA-Z]%', SUBSTRING(@rm,2,1)) = 0 THEN 'UU'	--A-F:any alpha'
		WHEN CHARINDEX(LEFT(@rm,1),'GHIJKLMNOPQRSTVWXYZ') > 0 THEN 'UU'	--G-T/V-Z:any alpha or numeric'
		WHEN CHARINDEX(LEFT(@rm,1),'ABCDEF') > 0 AND CHARINDEX(SUBSTRING(@rm,2,1),'0123456789') = 0 THEN 'UU'	--A-F:not numeric'
		ELSE @rm
		END

	RETURN @retval
END	

