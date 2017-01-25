CREATE PROCEDURE [dbo].[BackupIndexes]
AS
/* 
-- Joshua Granville 10/09/2015
-- Store tablename / indexname / drop index statement / create index statement

USE:
	EXEC [BackupIndexes]

OUTPUT:
	4 columns tableName, indexName, dropStatement and createStatement

*/
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--Get list of tables and columns to search
IF EXISTS (select 1 from sys.tables where name = 'tmp_indexes')
DROP TABLE tmp_indexes

CREATE TABLE tmp_indexes
(
	tableName VARCHAR(MAX),
	indexName VARCHAR(MAX),
	dropStatement VARCHAR(MAX),
	createStatement VARCHAR(MAX)
)

SELECT 
     TableName = sch.name + '.' + t.name,
     IndexName = ind.name,
     ColumnName = col.name,
     ind.type_desc
INTO #tmpIndexes
FROM 
     sys.indexes ind 
INNER JOIN 
     sys.index_columns ic ON  ind.object_id = ic.object_id and ind.index_id = ic.index_id 
INNER JOIN 
     sys.columns col ON ic.object_id = col.object_id and ic.column_id = col.column_id 
INNER JOIN 
     sys.tables t ON ind.object_id = t.object_id 
INNER JOIN 
	 sys.schemas sch ON t.schema_id = sch.schema_id
WHERE 
     ind.is_primary_key = 0 
     AND t.is_ms_shipped = 0 
     AND ind.is_unique_constraint = 0 
ORDER BY 
     t.name, ind.name, ind.index_id, ic.index_column_id 


--Split columns to delimited list
;WITH CTE_indexColumns
AS
(
	SELECT IndexName,TableName, IndexColumns = STUFF((
		SELECT ', ' + ColumnName FROM #tmpIndexes
		WHERE IndexName = x.IndexName
		AND TableName = x.TableName
		FOR XML PATH(''), TYPE).value('.[1]', 'nvarchar(max)'), 1, 2, '')
	FROM #tmpIndexes AS x
	GROUP BY IndexName,TableName
)
--Load tmpIndexes table.
INSERT INTO tmp_indexes
(
	tableName,
	indexName,
	dropStatement,
	createStatement
)
SELECT
	DISTINCT
	t.TableName,
	t.indexName,
	'DROP INDEX '+ t.indexName+ ' ON '+ t.tableName,
	'CREATE '+ type_desc + ' INDEX ['+ t.indexName + '] ON ' + t.TableName + ' (' + ct.IndexColumns collate database_default  + ')' 
FROM
	#tmpIndexes t
INNER JOIN CTE_indexColumns ct
	ON t.TableName COLLATE DATABASE_DEFAULT = ct.TableName
	AND t.IndexName COLLATE DATABASE_DEFAULT = ct.IndexName

SELECT * FROM tmp_indexes


SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET NOCOUNT OFF


GO