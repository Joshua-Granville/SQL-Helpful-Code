CREATE PROCEDURE LoadBullhorn.DropIndexes
AS
/* 
-- Joshua Granville 10/09/2015
-- Drop indexes on passed table
-- The proc will make sure to back them up first if they aren't already in tmp_indexes
-- By calling the proc: [dbo].[BackupIndexes]

USE:
	EXEC [DropIndexes] '_PersonReference'

OUTPUT:
	DROP INDEX IX__PersonReference ON _PersonReference
	DROP INDEX IX__PersonReference_1 ON _PersonReference
	DROP INDEX IX__PersonReference_2 ON _PersonReference
	DROP INDEX IX__PersonReference_3 ON _PersonReference
	DROP INDEX IX__PersonReference_4 ON _PersonReference
	DROP INDEX IX__PersonReference_5 ON _PersonReference
*/
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--Backup indexes if they aren't already backed up
IF NOT EXISTS (select 1 from sys.tables where name = 'tmp_indexes')
EXEC dbo.[BackupIndexes]

--Drop indexes
--Don't judge my cursor, this is a practical use.
DECLARE @v_drop varchar(255)

DECLARE csr_drop cursor FOR
SELECT DISTINCT dropStatement FROM dbo.tmp_indexes
Where tableName = @tableName

OPEN csr_drop
FETCH NEXT FROM csr_drop into @v_drop;

WHILE @@FETCH_STATUS = 0
BEGIN
	EXECUTE(@v_drop);
	PRINT @v_drop
	FETCH NEXT FROM csr_drop into @v_drop;
END
CLOSE csr_drop;
DEALLOCATE csr_drop;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET NOCOUNT OFF


GO