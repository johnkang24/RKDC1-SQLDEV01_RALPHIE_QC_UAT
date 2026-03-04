CREATE FUNCTION [dbo].[fnEval](@s nvarchar(MAX))
RETURNS float
AS 
BEGIN
    -- Token Types:
    -- -1 => error
    -- 0 => whitespace
    -- 1 => number
    -- 2 => opening parens
    -- 3 => closing parens
    -- 4 => operator + -
    -- 5 => operator * /
    DECLARE @result float;
    WITH cteChar AS (
        SELECT 0 ix, CAST(N' ' AS nchar(1)) c, 0 iType, 1 iGroup -- Anchor
        UNION ALL 
        SELECT LEN(@s)+1, NULL, 3, -1 iGroup -- Finalizer
        UNION ALL
        SELECT c.ix+1, CAST(SUBSTRING(@s, c.ix+1, 1) AS nchar(1)), CASE 
            WHEN SUBSTRING(@s, c.ix+1, 1) LIKE CASE WHEN c.iType=1 and c.c=N'e' THEN N'[0123456789\+\-]' WHEN c.iType=1 THEN N'[0123456789.e]' ELSE N'[0123456789]' END ESCAPE N'\' THEN 1 
            WHEN SUBSTRING(@s, c.ix+1, 1)=N'(' THEN 2 
            WHEN SUBSTRING(@s, c.ix+1, 1)=N')' THEN 3 
            WHEN SUBSTRING(@s, c.ix+1, 1) IN (N'+', N'-') THEN 4
            WHEN SUBSTRING(@s, c.ix+1, 1) IN (N'*', N'/') THEN 5
            WHEN RTRIM(SUBSTRING(@s, c.ix+1, 1))=N'' THEN 0 
            ELSE -1 
        END, CASE 
            WHEN SUBSTRING(@s, c.ix+1, 1) LIKE CASE WHEN c.iType=1 and c.c=N'e' then N'[0123456789\+\-]' WHEN c.iType=1 THEN N'[0123456789.e]' END ESCAPE N'\' THEN c.iGroup 
            ELSE c.iGroup+1
        END
        FROM cteChar c 
        WHERE c.ix<LEN(@s)
    ), cteToken AS (
        SELECT CAST(ROW_NUMBER() OVER (ORDER BY MIN(c.ix)) AS int) ix, STRING_AGG(c.c, N'') WITHIN GROUP (ORDER BY c.ix) s, c.iType
        FROM cteChar c
        WHERE c.iType>0 -- We could handle lexical errors here
        GROUP BY c.iGroup, c.iType
    ), cteParser AS (
        SELECT CASE WHEN EXISTS (SELECT * FROM cteToken f WHERE f.ix>2) THEN CAST(0 AS bit) ELSE CAST(1 AS bit) END bResult, t.ix+1 ixNext, CASE WHEN t.iType=1 THEN 
                (SELECT t.s [@val] FOR XML PATH(N'operand'), TYPE) 
            END xOperand, CASE WHEN t.iType>1 THEN 
                (SELECT t.s [@val], t.iType [@type] FOR XML PATH(N'operator'), TYPE) 
            END xOperator
        FROM cteToken t
        WHERE t.ix=1
        UNION ALL
        SELECT CASE WHEN p.xOperator.exist(N'/*')=0 AND t.s IS NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END, t.ix+CASE WHEN (t.iType>3 AND t.iType<=p.xOperator.value(N'*[1]/@type', 'int')) OR (t.iType=3 AND NOT p.xOperator.value(N'*[1]/@type', 'int')=2) THEN 0 ELSE 1 END,
            CASE 
            WHEN t.iType=1 THEN 
                (SELECT t.s [@val], p.xOperand.query(N'*') FOR XML PATH(N'operand'), TYPE) 
            WHEN (t.iType>3 AND t.iType<=p.xOperator.value(N'*[1]/@type', 'int')) OR (t.iType=3 AND NOT p.xOperator.value(N'*[1]/@type', 'int')=2) THEN
                (SELECT CASE p.xOperator.value(N'*[1]/@val', 'nchar') 
                    WHEN N'+' THEN
                        p.xOperand.value(N'*[1]/*[1]/@val', 'float')+p.xOperand.value(N'*[1]/@val', 'float')
                    WHEN N'-' THEN
                        p.xOperand.value(N'*[1]/*[1]/@val', 'float')-p.xOperand.value(N'*[1]/@val', 'float')
                    WHEN N'*' THEN
                        p.xOperand.value(N'*[1]/*[1]/@val', 'float')*p.xOperand.value(N'*[1]/@val', 'float')
                    WHEN N'/' THEN
                        p.xOperand.value(N'*[1]/*[1]/@val', 'float')/p.xOperand.value(N'*[1]/@val', 'float')
                    END [@val], p.xOperand.query(N'*/*/*') FOR XML PATH(N'operand'), TYPE)
            ELSE
                p.xOperand
            END xOperand, 
            CASE 
            WHEN t.iType=1 THEN 
                p.xOperator
            WHEN (t.iType>3 AND t.iType<=p.xOperator.value(N'*[1]/@type', 'int')) OR (t.iType=3) THEN
                p.xOperator.query(N'/*/*')
            ELSE
                (SELECT t.s [@val], t.iType [@type], p.xOperator.query(N'*') FOR XML PATH(N'operator'), TYPE) 
            END xOperator
        FROM cteToken t
        JOIN cteParser p ON p.ixNext=t.ix AND p.bResult=CAST(0 AS bit)
    )
    SELECT @result=p.xOperand.value(N'/ *[1]/@val', 'float')
        FROM cteParser p
        WHERE bResult=CAST(1 AS bit)
        OPTION (MAXRECURSION 0);
    RETURN @result;
END

