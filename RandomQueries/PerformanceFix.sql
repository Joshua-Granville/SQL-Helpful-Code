--Original
USE BH_4720_updqc

--1. Candidate skill picker
--backup table
;WITH CreateTableFromList AS (
SELECT 1 AS n,
       userID,
       CAST(LEFT(CAST(desiredLocations AS VARCHAR(MAX)),ISNULL(NULLIF(CHARINDEX(';',CAST(desiredLocations AS VARCHAR(MAX))),0),1001)-1) AS VARCHAR(1000)) AS Value,
       CAST(LTRIM(SUBSTRING(CAST(desiredLocations AS VARCHAR(MAX)),NULLIF(CHARINDEX(';',CAST(desiredLocations AS VARCHAR(MAX))),0)+1,100000)) AS VARCHAR(MAX)) AS RemainingValues
  FROM BH_4720_updqc.bullhorn1.BH_UserContact x
		WHERE x.recordTypeBits = 1
 UNION ALL
SELECT n + 1,
       userID,
       CAST(LEFT(RemainingValues,ISNULL(NULLIF(CHARINDEX(';',RemainingValues),0),1001)-1) AS VARCHAR(1000)),
       CAST(LTRIM(SUBSTRING(RemainingValues,NULLIF(CHARINDEX(';',RemainingValues),0) + LEN(';'),100000)) AS VARCHAR(MAX))
  FROM CreateTableFromList
 WHERE LEN(RemainingValues) > 0
)
SELECT
	userID = uc.userID,
	desiredLocations_OLD = uc.desiredLocations,
	desiredLocations_NEW = STUFF((SELECT ';' + ISNULL(x.skillName_NEW, skillList.Value)
								FROM CreateTableFromList skillList
									LEFT JOIN BH_4720_updqc.dbo.pstmp_20150828_Skill_name x
										ON skillList.Value = x.skillName_OLD
								WHERE uc.userID = skillList.userID
								FOR XML PATH ('')), 1, 1, ''),
	migrateGUID = NEWID()
INTO BH_4720_updqc.dbo.pstmp_20150828_UserContact_desiredLocations
FROM BH_4720_updqc.bullhorn1.BH_UserContact uc
WHERE uc.recordTypeBits = 1
	AND EXISTS (SELECT TOP 1 1 FROM CreateTableFromList skillList JOIN BH_4720_updqc.dbo.pstmp_20150828_Skill_name x ON skillList.Value = x.skillName_OLD AND skillList.userID = uc.userID)
OPTION (MAXRECURSION 0)
--37 minutes before killing
--Needs to be broken up for performance.  Sql server cant handle the recursive CTE, the exists check and the FOR XML subquery at the same time.



/*
	Optimized changes - Need to do same for other entities that are in the update, this is an example for the largest one Candidates.
*/
USE BH_4720_updqc

--Create a work table of only the records we need, transform the text block to a varchar for the next step.
SELECT 
	uc.userId,
	CAST(uc.desiredLocations as varchar(max)) desiredLocations --max length in table is 1745
INTO
	BH_4720_updqc.bullhorn1.pstmp_20150904_ucWorkTable
FROM
	BH_4720_updqc.bullhorn1.bh_userContact uc
WHERE 
	CAST(uc.desiredLocations as varchar(max)) IS NOT NULL
AND recordTypeBits = 1;
--43277 records - 0 seconds
	
--1. Candidate skill picker
--backup table
;WITH CreateTableFromList AS (
SELECT 1 AS n,
       userID,
       CAST(LEFT(CAST(desiredLocations AS VARCHAR(MAX)),ISNULL(NULLIF(CHARINDEX(';',CAST(desiredLocations AS VARCHAR(MAX))),0),1001)-1) AS VARCHAR(1000)) AS Value,
       CAST(LTRIM(SUBSTRING(CAST(desiredLocations AS VARCHAR(MAX)),NULLIF(CHARINDEX(';',CAST(desiredLocations AS VARCHAR(MAX))),0)+1,100000)) AS VARCHAR(MAX)) AS RemainingValues
  FROM BH_4720_updqc.bullhorn1.pstmp_20150904_ucWorkTable x
 UNION ALL
SELECT n + 1,
       userID,
       CAST(LEFT(RemainingValues,ISNULL(NULLIF(CHARINDEX(';',RemainingValues),0),1001)-1) AS VARCHAR(1000)),
       CAST(LTRIM(SUBSTRING(RemainingValues,NULLIF(CHARINDEX(';',RemainingValues),0) + LEN(';'),100000)) AS VARCHAR(MAX))
  FROM CreateTableFromList
 WHERE LEN(RemainingValues) > 0
)
SELECT userID,value 
INTO BH_4720_updqc.dbo.pstmp_CreateTableFromList
FROM CreateTableFromList
OPTION (MAXRECURSION 0)
--275553 records - 14 seconds

CREATE CLUSTERED INDEX idx_pstmp_updpstmp_CreateTableFromList ON BH_4720_updqc.dbo.pstmp_CreateTableFromList(userId)

SELECT
	userID = uc.userID,
	desiredLocations_OLD = uc.desiredLocations,
	desiredLocations_NEW = STUFF((SELECT ';' + ISNULL(x.skillName_NEW, skillList.Value)
								FROM BH_4720_updqc.dbo.pstmp_CreateTableFromList skillList
									LEFT JOIN BH_4720_updqc.dbo.pstmp_20150828_Skill_name x
										ON skillList.Value = x.skillName_OLD
								WHERE uc.userID = skillList.userID
								FOR XML PATH ('')), 1, 1, ''),
	migrateGUID = NEWID()
INTO BH_4720_updqc.dbo.pstmp_20150828_UserContact_desiredLocations
FROM BH_4720_updqc.bullhorn1.BH_UserContact uc
WHERE uc.recordTypeBits = 1
	AND EXISTS (SELECT TOP 1 1 FROM BH_4720_updqc.dbo.pstmp_CreateTableFromList skillList JOIN BH_4720_updqc.dbo.pstmp_20150828_Skill_name x ON skillList.Value = x.skillName_OLD AND skillList.userID = uc.userID)
--41067 records - 19 seconds