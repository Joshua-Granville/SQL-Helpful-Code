--Files they sent to us that dont tie to the db
--I loaded by traversing the directory with a python script in same folder
--loading file name, extension path and file Date


--Create a function to clear out all numbers because some names are like this Joshua Granville14-02-01.pdf
CREATE FUNCTION [dbo].[ReturnLettersOnly](@origString VARCHAR(255))
RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @stringLen INT,
            @charInd INT,
            @currentChar VARCHAR(1),
            @charAsciiCode INT,
            @returnValue VARCHAR(255)
    
    SET @charInd = 1
    SET @stringLen = LEN(@origString)
    SET @returnValue = ''
    
    WHILE @charInd <= @stringLen
        BEGIN
            SET @currentChar = SUBSTRING(@origString, @charInd, 1)
            SET @charAsciiCode = ASCII(@currentChar)
            
            IF LOWER(@currentChar) NOT IN ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
                                       'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
                                       'u', 'v', 'w', 'x', 'y', 'z')
            BEGIN
            SET @returnValue = @returnValue + ' '
            END
			ELSE
			BEGIN 
			SET @returnValue = @returnValue + @currentChar
			END
            SET @charInd = @charInd + 1
        END
    RETURN @returnValue
END

IF EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.tables 
			WHERE TABLE_NAME = 'pstmp_fileList_importNames')
DROP TABLE pstmp_fileList_importNames
--Parse out the data
SELECT 
	fi.*,
	convert(datetime, stuff(stuff(stuff(fi.fileDate, 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) AS dateAdded,
	LTRIM(RTRIM(SUBSTRING(fi.fileName,CHARINDEX(' ',fi.fileNAme)+1,
										   CHARINDEX(' ', SUBSTRING(REPLACE(dbo.ReturnLettersOnly(fi.fileNAme),'.',' '), CHARINDEX(' ', fi.fileNAme)+2, 255)) ))) AS firstName,
	LTRIM(RTRIM(SUBSTRING(fi.fileName,1,CHARINDEX(' ',fi.fileNAme)) )) AS lastName
INTO
	pstmp_fileList_importNames
FROM 
	pstmp_fileList_import fi


SELECT 
	p.personID,
	'Resume' AS type,
	fi.fileName AS name,
	fi.extension AS fileExtension,
	fi.path + fi.fileName AS externalFileName,
	convert(datetime, stuff(stuff(stuff(fi.fileDate, 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) AS dateAdded
FROM 
	pstmp_fileList_importNames fi
INNER JOIN _person p
	ON p.firstName = fi.firstName
	AND p.lastName = fi.lastName
WHERE 
	NULLIF(p.firstName,'') IS NOT NULL
AND NULLIF(p.lastName,'') IS NOT NULL