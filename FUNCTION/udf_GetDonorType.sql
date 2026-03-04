-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[udf_GetDonorType]
(	
	@rm VARCHAR(50)
)

RETURNS VARCHAR(50)
AS BEGIN
	DECLARE @out_field VARCHAR(50)
	DECLARE @rm1 CHAR(1) = LEFT(@rm,1)
	DECLARE @rm2 CHAR(1) = SUBSTRING(@rm,2,1)

	SET @out_field =
		CASE WHEN @rm1='A' AND ISNUMERIC(@rm2)=1 THEN 'Active'
		 WHEN @rm1='B' AND ISNUMERIC(@rm2)=1 THEN 'Active'
		 WHEN @rm1='C' AND ISNUMERIC(@rm2)=1 THEN 'Active'
		 WHEN @rm1='D' AND ISNUMERIC(@rm2)=1 THEN 'Lapsed'
		 WHEN @rm1='E' AND ISNUMERIC(@rm2)=1 THEN 'Extended Lapsed'
		 WHEN @rm1='F' AND ISNUMERIC(@rm2)=1 THEN 'Extended Lapsed'
		 WHEN @rm1='U' AND @rm2='U' THEN 'House'
		 WHEN ISNUMERIC(@rm1)=1 AND ISNUMERIC(@rm2)=1 THEN 'Active'
		 ELSE 'House'
		END

	RETURN @out_Field
END


