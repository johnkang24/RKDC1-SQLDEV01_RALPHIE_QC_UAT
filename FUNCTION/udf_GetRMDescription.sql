-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[udf_GetRMDescription]
(	
	@rm VARCHAR(50)
)

RETURNS VARCHAR(50)
AS BEGIN
	DECLARE @out_field VARCHAR(50)
	DECLARE @rm1 CHAR(1) = LEFT(@rm,1)
	DECLARE @rm2 CHAR(1) = SUBSTRING(@rm,2,1)

	SET @out_field =
		CASE WHEN @rm1='A' THEN '0 - 12'
		 WHEN @rm1='B' THEN '13-24 Months'
		 WHEN @rm1='C' THEN '25-36 Months'
		 WHEN @rm1='D' THEN '37-48 Months'
		 WHEN @rm1='E' THEN '49-60 Months'
		 WHEN @rm1='F' THEN '61+ Months'
		 ELSE 'Unknown'
		END

	SET @out_field = @out_field + ' ' +
		CASE WHEN @rm2='0' THEN '$0-4.99'
		 WHEN @rm2='1' THEN '$5-9.99'
		 WHEN @rm2='2' THEN '$10-24.99'
		 WHEN @rm2='3' THEN '$25-49.99'
		 WHEN @rm2='4' THEN '$50-99.99'
		 WHEN @rm2='5' THEN '$100-249.99'
		 WHEN @rm2='6' THEN '$250-499.99'
		 WHEN @rm2='7' THEN '$500-999.99'
		 WHEN @rm2='8' THEN '$1000+'
		 ELSE 'Unknown'
		END

	RETURN @out_Field
END


