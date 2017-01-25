/*
	Merge two delimited lists together that are deduped and remain in proper order.
	
	use:
	
	SELECT userId, [dbo].[bhfn_Merge_columns](valueList1 + valueList2,';')
	FROM table
	
	IE:
	DECLARE @valueList1 VARCHAR(500),@valueList2 VARCHAR(500)
		SET @valueList1 = 'Kaz/KM/LMI'
		SET @valueList2 = 'Kaz/PBS KIDS/Tommee Tippee/Dorel/Safety 1st'
	
	--If you are passing multiple columns u would be expected to have a delimiter between the two columns.
		SELECT 1, [dbo].[bhfn_Merge_columns](@valueList1 + '/' +  @valueList2,'/')
	
		Output = 1, Kaz/KM/LMI/PBS KIDS/Tommee Tippee/Dorel/Safety 1st
*/


CREATE  FUNCTION [dbo].[bhfn_Merge_columns]
(
    @delimitedList VARCHAR(max),
    @delimiter VARCHAR(20)
)
RETURNS varchar(MAX)
BEGIN
DECLARE @output VARCHAR(MAX)
DECLARE @TestTable TABLE (ID INT,ValueList VARCHAR(MAX))
DECLARE @outPutTable TABLE(ID INT, Value VARCHAR(MAX),n INT )

--DECLARE @Delimiter VARCHAR(5) = '/'
INSERT @TestTable VALUES(1,@delimitedList)
;WITH CreateTableFromList AS (
SELECT 1 AS n,
       ID,
       CAST(LEFT(ValueList,ISNULL(NULLIF(CHARINDEX(@Delimiter,ValueList),0),1001)-1) AS VARCHAR(1000)) AS Value,
       CAST(LTRIM(SUBSTRING(ValueList,NULLIF(CHARINDEX(@Delimiter,ValueList),0)+1,100000)) AS VARCHAR(MAX)) AS RemainingValues
  FROM @TestTable x
 UNION ALL
SELECT n + 1,
       ID,
       CAST(LEFT(RemainingValues,ISNULL(NULLIF(CHARINDEX(@Delimiter,RemainingValues),0),1001)-1) AS VARCHAR(1000)),
       CAST(LTRIM(SUBSTRING(RemainingValues,NULLIF(CHARINDEX(@Delimiter,RemainingValues),0) + LEN(@Delimiter),100000)) AS VARCHAR(MAX))
  FROM CreateTableFromList
 WHERE LEN(RemainingValues) > 0
)
INSERT INTO @outPutTable
SELECT ID,Value,n
  FROM CreateTableFromList

DECLARE @TestTable2 TABLE (ID INT,Value VARCHAR(MAX) )
--DECLARE @Delimiter VARCHAR(5) = '/'
INSERT @TestTable2
SELECT ID,Value 
FROM (
	SELECT ID,Value,n,ROW_NUMBER() OVER(PARTITION BY ID,Value ORDER BY n)rnk
	FROM @outPutTable 
	)t
WHERE rnk = 1
ORDER BY n 
--SELECT * FROM @TestTable
SELECT @output =
       SUBSTRING((SELECT (@Delimiter+Value)
                    FROM @TestTable2 y
                   WHERE y.ID = x.ID
                     FOR XML PATH(''),type).value('(./text())[1]','varchar(max)'),2,8000)
  FROM (SELECT DISTINCT ID FROM @TestTable2) x
RETURN @output
END



--End Function call
--test performance, 10,000 records in 5 seconds.
--100,000 in 1 min

DROP TABLE testJosh
CREATE TABLE testJosh
(
	id int,
	vals varchar(MAX)
)
DECLARE @id INT = 1
WHILE (@id <= 100000)
BEGIN
	INSERT INTO testJosh(id,vals)
	VALUES(@id,'Kaz/KM/LMI''Kaz/PBS KIDS/Tommee Tippee/Dorel/Safety 1st/'+'LMI/Kaz/NewVal')
SET @id = @id + 1
END

SELECT * FROM dbo.testJosh

SELECT ID,vals, dbo.[bhfn_Merge_columns](vals,'/') fix
INTO test2
FROM dbo.testJosh
--100,000 in 1 min

SELECT * FROM test2

SELECT dbo.[bhfn_Merge_columns]('Kaz/KM/LMI''Kaz/PBS KIDS/Tommee Tippee/Dorel/Safety 1st/'+'LMI/Kaz/NewVal','/')
