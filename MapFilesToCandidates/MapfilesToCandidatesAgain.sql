USE ProfileHospitality_Mig_Template


ALTER TABLE pstmp_fileList_import ADD postSpace VARCHAR(MAX)

UPDATE  pstmp_fileList_import SET postSpace = ltrim(SUBSTRING(fileName,CHARINDEX(' ',filename),LEN(fileNAme)))

;WITH FileNames
AS
(
	SELECT 
		SUBSTRING(fileName,1,CHARINDEX(' ',filename)) AS firstName,
		SUBSTRING(postSpace,1,CHARINDEX(' ',postSpace)) AS lastName,
		PATH,
		fileName,
		extension,
		fileDate
	FROM
		pstmp_fileList_import
)
SELECT 
	f.fileName,
	f.path,
	f.extension,
	f.fileDate,
	p.BullhornUserID,
	p.personID,
	p.firstName,
	p.lastName 
FROM 
	_person p
INNER JOIN FileNames f
	ON LTRIM(RTRIM(p.firstName)) = LTRIM(RTRIM(f.firstName))
	AND LTRIM(RTRIM(p.lastName)) = LTRIM(RTRIM(f.lastName))
	AND p.recordType = 1
UNION
SELECT 
	f.fileName,
	f.path,
	f.extension,
	f.fileDate,
	p.BullhornUserID,
	p.personID,
	p.firstName,
	p.lastName 
FROM 
	_person p
INNER JOIN pstmp_fileList_import f
	ON LTRIM(RTRIM(p.firstName)) + LTRIM(RTRIM(p.lastName)) = LTRIM(RTRIM(SUBSTRING(f.fileName,1,CHARINDEX('.',fileNAme)-1)))
	AND p.recordType = 1


SELECT * FROM pstmp_fileList_import