--Parse XML
--xml structure like this...
<assessmentResult>
	<results>
		<detailResult>
			<description>Test Result</description>
			<band>Passed</Band>
			<comments>This guy rules</comments>
		</detailResult>
		<detailResult>
			<description>Test Two</description>
			<band>Failed</Band>
			<comments>This guy Stinks</comments>
		</detailResult>
	</results>
</assessmentResult>

CREATE VIEW assesmentsXML AS SELECT capplicantID,CAST(assessmentXML AS XML) xmlData FROM dbo.Assessments

;WITH CTE_moreScores
AS
(
SELECT
	p.personID,
	a.capplicantid,
	m.c.query('data(Description)') AS description,
	m.c.query('data(Band)') AS Band,
	m.c.query('data(Comments)') AS Comments
FROM dbo.assesmentsXML a
INNER JOIN _person p
	ON a.capplicantID = p.externalID
	AND p.recordType = 1
CROSS APPLY a.xmlData.nodes('/AssessmentResult/Results/DetailResult') m(c)
WHERE xmlData IS NOT NULL
)
SELECT
	*
INTO pstmp_forUpdate
FROM CTE_moreScores
WHERE CAST(CTE_moreScores.description AS VARCHAR(1000)) IN ('SalesAPRecommendation','CSAPRecommendation')




--cte delete, dedupes..
;WITH wins
AS
(
SELECT *, ROW_NUMBER() OVER (
				PARTITION BY contact_id,permission_type ORDER BY permission_date) AS row_n
				FROM dbo.trans_permission
)
delete from wins
where row_n >1



-- Fixing some bad characters in resumes
UPDATE uc SET description = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(description AS VARCHAR(MAX)),'ï¿½','&#009'),'
???
','&horbar;'),' ??? ','&horbar;'),'>???<','>&horbar;<'),'???','''')
  FROM BULLHORN8473.bullhorn1.BH_UserContact uc
       INNER JOIN BULLHORN8473.bullhorn1.PS_ResumeParse p
	   ON uc.userID = p.userID
 WHERE p.isExtracted = 1


--Parsing File paths
SELECT
	fileName AS filePath,
	SUBSTRING(fileName,1,LEN(fileName)-CHARINDEX('\',REVERSE(fileName))) folderOnly,
	REVERSE(SUBSTRING(REVERSE(fileName),0,CHARINDEX('\',REVERSE(fileName)))) FileNoPath,
	SUBSTRING(REVERSE(SUBSTRING(REVERSE(fileName),0,CHARINDEX('\',REVERSE(fileName)))) ,1, CHARINDEX('.',REVERSE(SUBSTRING(REVERSE(fileName),0,CHARINDEX('\',REVERSE(fileName)))))-1 ) FileNoExtension,
	REVERSE(SUBSTRING(REVERSE(fileName),0,CHARINDEX('.',REVERSE(fileName)))) Extension
FROM
	CompanyfilesMissing
--'

SELECT   a1.value
   ,pl.*
FROM   BULLHORN1.BH_PrivateLabelAttribute a1
inner join  BULLHORN1.BH_PrivateLabel pl
on    a1.privatelabelid = pl.privatelabelid
WHERE   a1.name  = 'databaseinstance'
and    cast(a1.value as varchar(200)) = 'bullhornXXXX'


--SQL Server cheat sheet
--Concat many phone numbers to one column
select distinct st2.contact_id,substring(
	(
	Select ', '+phone_number  AS [text()]
	From dbo.contact_phone ST1
	Where ST1.contact_id = ST2.contact_id
	ORDER BY ST1.contact_id
	For XML PATH ('')
	),2,1000)[phone_numbers]
from dbo.contact_phone st2
where contact_id in (
5203663900,
5636806738,
5137643341
)

--dynamic pivot
select * into test_j
from dbo.contact_phone
where contact_id in (
5203663900,
5636806738,
5137643341
)


DECLARE @MaxCount INT;

SELECT @MaxCount = max(cnt)
FROM (
    SELECT contact_id
        ,count(phone_number) AS cnt
    FROM test_j
    GROUP BY contact_id
    ) X;

DECLARE @SQL NVARCHAR(max)
    ,@i INT;

SET @i = 0;

WHILE @i < @MaxCount
BEGIN
    SET @i = @i + 1;
    SET @SQL = COALESCE(@Sql + ', ', '') + 'Col' + cast(@i AS NVARCHAR(10));
END

SET @SQL = N';WITH CTE AS (
   SELECT contact_id, phone_number, ''Col'' + CAST(row_number() OVER (PARTITION BY contact_id ORDER BY phone_number) AS Varchar(10)) AS RowNo
   FROM   test_j
)
SELECT *
FROM   CTE
PIVOT (MAX(phone_number) FOR RowNo IN (' + @SQL + N')) pvt';

PRINT @SQL;

EXECUTE (@SQL);


--Converts Julian dates and factors leap year.
create function Conv_FromJulian_leap(@aJulianDate int)
returns date
as
begin
	IF (convert(int, substring(convert(varchar(7),@aJulianDate),1,4) ) % 4 = 0 and convert(int, substring(convert(varchar(7),@aJulianDate),1,4) ) % 100 != 0) or convert(int, substring(convert(varchar(7),@aJulianDate),1,4) ) % 400 = 0
	BEGIN
		return ((DateAdd(Year, @aJulianDate / 1000 - 1900, @aJulianDate % 1000-1)) - 1)
	END
return DateAdd(Year, @aJulianDate / 1000 - 1900, @aJulianDate % 1000-1)
end

select dbo.Conv_FromJulian_leap(1996247)
select dbo.Conv_FromJulian_leap(1997247)
select dbo.Conv_FromJulian_leap(1996247)




--Greatest date using multiple fields.
SELECT contact_id,
       (SELECT MAX(DATES)
        FROM (VALUES (max(OBJ_MODIFIED_DATE)),(max(MODIFIED_DATE)),(max(CREATED_DATE))) AS AllDates(Dates)) as GRT_DATE,
        brand
FROM inquiry_profile
where brand = 'RSSC'
and contact_id <> 0
and contact_id = 1609723018
group by contact_id,brand



--Loop insert
declare @last_day datetime,
		@first_day datetime
set @last_day = '20140731'
set @first_day = '20140701'

while @first_day <= @last_day
BEGIN
	insert into WELCOME_CAMPAIGN_SKIP_DAY(skip_date,add_date,source,update_date,update_source)
	select
		@first_day,getdate(),'JOSHG',getdate(),'JOSHG'
	where @first_day not in (select skip_date from WELCOME_CAMPAIGN_SKIP_DAY)
set @first_day = @first_day + 1
END



--Finding values in strings (urls) charindex.
SELECT
	gregorian_date,
	account_name,
	campaign_name,
	keyword,
	ad_distribution,
	current_max_cpc,
	quality_score,
	impressions,
	clicks,
	ctr,
	spend,
	average_position,
	destination_url,
    --finds first entry of 'pid' then finds the following '&' and substrings the value between them
	CASE WHEN replace(destination_url,'=','') like '%pid%' THEN
	replace(substring(
                    (substring(destination_url,charindex('pid=',destination_url,1)+4,len(destination_url) - charindex('pid=',destination_url,1)) ),
                    1,
                    charindex('&',(substring(destination_url,charindex('pid=',destination_url,1)+4,len(destination_url) - charindex('pid=',destination_url,1))),1)
                    ),'&','')
					ELSE ' ' END ad_pid,
	CASE WHEN destination_url like '%utm_source%' THEN
		substring(destination_url,(charindex('utm_source=',destination_url,1)+11),len(destination_url) - (charindex('utm_source=',destination_url,1)))
		ELSE ' '
	END utm_source,
    --finds first entry of 'utm_campaign' then finds the following '&' and substrings the value between them
	CASE WHEN replace(destination_url,'=','') like '%utm_campaign%' THEN
   replace(substring(
                    (substring(destination_url,charindex('utm_campaign=',destination_url,1)+13,len(destination_url) - charindex('utm_campaign=',destination_url,1)) ),
                    1,
                    charindex('&',(substring(destination_url,charindex('utm_campaign=',destination_url,1)+13,len(destination_url) - charindex('utm_campaign=',destination_url,1))),1)
                    ),'&','')
         WHEN replace(destination_url,'=','') like '%utmcampaign%' THEN
            replace(substring(
                    (substring(destination_url,charindex('utm=campaign=',destination_url,1)+13,len(destination_url) - charindex('utm=campaign=',destination_url,1)) ),
                    1,
                    charindex('&',(substring(destination_url,charindex('utm=campaign=',destination_url,1)+13,len(destination_url) - charindex('utm=campaign=',destination_url,1))),1)
                    ),'&','')
         ELSE ' ' END UTM_CAMPAIGN,
    --finds first entry of 'utm_term' then finds the following '&' and substrings the value between them
	CASE WHEN replace(destination_url,'=','') like '%utm_term%' THEN
	replace(substring(
                    (substring(destination_url,charindex('utm_term=',destination_url,1)+9,len(destination_url) - charindex('utm_term=',destination_url,1)) ),
                    1,
                    charindex('&',(substring(destination_url,charindex('utm_term=',destination_url,1)+9,len(destination_url) - charindex('utm_term=',destination_url,1))),1)
                    ),'&','')
					ELSE ' ' END utm_term
FROM
	dbo.stg_bing_ads


--Pivot example
select 'Josh' name, 1241 phone
into #jtest
union
select 'Josh' name, 1234 phone
union
select 'Jill' name, 1251 phone

select name,phone_number1,isnull(phone_number2,0)phone_number2
from
(
select name,phone, CASE WHEN(row_number() over(partition by name order by phone)) = '1' then 'Phone_number1' ELSE 'Phone_number2' END PHONE_RNK
from #jtest
)t
pivot
(
	max(phone)
	for PHONE_RNK in ([Phone_number1],[Phone_number2])
)as piv;


drop table #jtest4

select 1 as cid,'Josh' name, 1241 phone
into #jtest4
union
select 1 as cid,'Josh' name, 1234 phone
union
select 2 as cid,'Jill' name, 1251 phone

select cid,name,phone_number1,isnull(phone_number2,0)phone_number2
from
(
select cid,name,phone, CASE WHEN(row_number() over(partition by cid order by phone)) = '1' then 'Phone_number1' ELSE 'Phone_number2' END PHONE_RNK
from #jtest4
)t
pivot
(
	max(phone)
	for PHONE_RNK in ([Phone_number1],[Phone_number2])
)as piv;

select * from #jtest4



--DATE Cheat Sheet!!

Select Convert(Varchar,GetDate(),0)
Sep 14 2012  2:58PM

Select Convert(Varchar,GetDate(),1)
09/14/12

Select Convert(Varchar,GetDate(),2)
12.09.14

Select Convert(Varchar,GetDate(),3)
14/09/12

Select Convert(Varchar,GetDate(),4)
14.09.12

Select Convert(Varchar,GetDate(),5)
14-09-12

Select Convert(Varchar,GetDate(),6)
14 Sep 12

Select Convert(Varchar,GetDate(),7)
Sep 14, 12

Select Convert(Varchar,GetDate(),8)
14:58:11

Select Convert(Varchar,GetDate(),9)
Sep 14 2012  2:58:11:847PM

Select Convert(Varchar,GetDate(),10)
09-14-12

Select Convert(Varchar,GetDate(),11)
12/09/14

Select Convert(Varchar,GetDate(),12)
120914

Select Convert(Varchar,GetDate(),13)
14 Sep 2012 14:58:11:847

Select Convert(Varchar,GetDate(),14)
14:58:11:847

Select Convert(Varchar,GetDate(),20)
2012-09-14 14:58:11

Select Convert(Varchar,GetDate(),21)
2012-09-14 14:58:11.847

Select Convert(Varchar,GetDate(),22)
09/14/12  2:58:11 PM

Select Convert(Varchar,GetDate(),23)
2012-09-14

Select Convert(Varchar,GetDate(),24)
14:58:11

Select Convert(Varchar,GetDate(),25)
2012-09-14 14:58:11.847

Select Convert(Varchar,GetDate(),100)
Sep 14 2012  2:58PM

Select Convert(Varchar,GetDate(),101)
09/14/2012

Select Convert(Varchar,GetDate(),102)
2012.09.14

Select Convert(Varchar,GetDate(),103)
14/09/2012

Select Convert(Varchar,GetDate(),104)
14.09.2012

Select Convert(Varchar,GetDate(),105)
14-09-2012

Select Convert(Varchar,GetDate(),106)
14 Sep 2012

Select Convert(Varchar,GetDate(),107)
Sep 14, 2012

Select Convert(Varchar,GetDate(),108)
14:58:11

Select Convert(Varchar,GetDate(),109)
Sep 14 2012  2:58:11:847PM

Select Convert(Varchar,GetDate(),110)
09-14-2012

Select Convert(Varchar,GetDate(),111)
2012/09/14

Select Convert(Varchar,GetDate(),112)
20120914

Select Convert(Varchar,GetDate(),113)
14 Sep 2012 14:58:11:847

Select Convert(Varchar,GetDate(),114)
14:58:11:847

Select Convert(Varchar,GetDate(),120)
2012-09-14 14:58:11

Select Convert(Varchar,GetDate(),121)
2012-09-14 14:58:11.847

Select Convert(Varchar,GetDate(),126)
2012-09-14T14:58:11.847

Select Convert(Varchar,GetDate(),127)
2012-09-14T14:58:11.847

Select Convert(Varchar,GetDate(),130)
28 ???? 1433  2:58:11:847PM

Select Convert(Varchar,GetDate(),131)
28/10/1433  2:58:11:847PM


--More date transformations
----Today
SELECT GETDATE() 'Today'
----Yesterday
SELECT DATEADD(d,-1,GETDATE()) 'Yesterday'
----First Day of Current Week
SELECT DATEADD(wk,DATEDIFF(wk,0,GETDATE()),0) 'First Day of Current Week'
----Last Day of Current Week
SELECT DATEADD(wk,DATEDIFF(wk,0,GETDATE()),6) 'Last Day of Current Week'
----First Day of Last Week
SELECT DATEADD(wk,DATEDIFF(wk,7,GETDATE()),0) 'First Day of Last Week'
----Last Day of Last Week
SELECT DATEADD(wk,DATEDIFF(wk,7,GETDATE()),6) 'Last Day of Last Week'
----First Day of Current Month
SELECT DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0) 'First Day of Current Month'
----Last Day of Current Month
SELECT DATEADD(ms,- 3,DATEADD(mm,0,DATEADD(mm,DATEDIFF(mm,0,GETDATE())+1,0))) 'Last Day of Current Month'
----First Day of Last Month
SELECT DATEADD(mm,-1,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0)) 'First Day of Last Month'
----Last Day of Last Month
SELECT DATEADD(ms,-3,DATEADD(mm,0,DATEADD(mm,DATEDIFF(mm,0,GETDATE()),0))) 'Last Day of Last Month'
----First Day of Current Year
SELECT DATEADD(yy,DATEDIFF(yy,0,GETDATE()),0) 'First Day of Current Year'
----Last Day of Current Year
SELECT DATEADD(ms,-3,DATEADD(yy,0,DATEADD(yy,DATEDIFF(yy,0,GETDATE())+1,0))) 'Last Day of Current Year'
----First Day of Last Year
SELECT DATEADD(yy,-1,DATEADD(yy,DATEDIFF(yy,0,GETDATE()),0)) 'First Day of Last Year'
----Last Day of Last Year
SELECT DATEADD(ms,-3,DATEADD(yy,0,DATEADD(yy,DATEDIFF(yy,0,GETDATE()),0))) 'Last Day of Last Year'


--Cursor example
SET NOCOUNT ON;
declare @v_time varchar(10), @v_property_id varchar(255), @v_hotel_code varchar(255), @v_num_guests int;

--Get next hour for check
set @v_time = REPLACE(REPLACE(CONVERT(varchar(7),CAST(DATEADD(hour, DATEDIFF(hour, 0,dateadd(hour,0,getdate()) ),0) AS TIME),100),'PM',' PM'),'AM',' AM')


DECLARE c_properties_to_pull CURSOR FOR
SELECT distinct property_id,hotel_ows_code FROM [four_seasons_stage].[dbo].[PropertyCheckInCheckOutTime]
where EST_TIME = @v_time;

OPEN c_properties_to_pull;
FETCH NEXT FROM c_properties_to_pull
INTO @v_property_id,@v_hotel_code;

Truncate table dbo.Mobile_CheckIns_Extraction;
print 'Pulling all guests that will be sent for hour: '+@v_time;
print '-----------------------------------------------------------';
print ' ';

WHILE @@FETCH_STATUS = 0
BEGIN
			INSERT INTO dbo.Mobile_CheckIns_Extraction(contact_id,title,first_name,last_name,primary_email_address,state,zip_code,gsp_yn,rc_owner_yn,prop_total,total_stays,gender_code,activity_id,arrival_date,confirmation_number,departuredate,hotel_code,property_name,address_line1,address_line2,phone_number,url_google)
			Select a.CONTACT_ID,c.PROF_TITLE TITLE,FIRST_NAME,LAST_NAME ,PRIMARY_EMAIL_ADDRESS,' ' STATE,' ' ZIP_CODE,GSP_YN,RC_OWNER_YN,0 PROP_TOTAL,0 TOTAL_STAYS,GENDER_CODE,
            'C000006792' Activity_ID,convert(varchar(10),reserve_Begin_date,101) ARRIVALDATE,CAST(b.RESV_NO as numeric) -300000000 CONFIRMATION_NUMBER,convert(varchar(10),DEPARTURE_DATE,101) DEPARTUREDATE, Hotel_ows_code HOTEL_CODE,property_name HOTEL_PROPERTY_NAME, address_line1, address_line2+ ', '+Address_Line3 address_line2, phone_number, 'www.google.com/maps/place/'+property_name URL_GOOGLE
			FROM contact c,
			Contact_Reservation a,
			Reservation_Detail b,
			[four_seasons_stage].[dbo].[PropertyCheckInCheckOutTime] d, PROPERTY e
			where a.Resv_No=b.Resv_No and (year(a.add_date)= year(b.add_date)) and c.contact_id = a.contact_id
			and datediff(DD,getdate(),RESERVE_BEGIN_DATE) = 1
			and b.PROPERTY_ID = d.property_id and b.PROPERTY_ID = e.PROPERTY_ID
			and b.property_id = @v_property_id
			group by  a.CONTACT_ID,c.PROF_TITLE,FIRST_NAME,LAST_NAME ,PRIMARY_EMAIL_ADDRESS,GSP_YN,RC_OWNER_YN,GENDER_CODE,
            CAST(b.RESV_NO as numeric) -300000000, b.PROPERTY_ID,reserve_Begin_date,DEPARTURE_DATE,Hotel_ows_code,PROPERTY_NAME, address_line1,address_line2+ ', '+Address_Line3, phone_number,'www.google.com/maps/place/'+property_name

	set @v_num_guests = @@ROWCOUNT;
	print 'Property_id: '+@v_property_id+' | '+CAST(@v_num_guests as varchar(255))+' Guest(s) extracted';
	FETCH NEXT FROM c_properties_to_pull INTO @v_property_id,@v_hotel_code;
END;
CLOSE c_properties_to_pull;
DEALLOCATE c_properties_to_pull;

SET NOCOUNT OFF;




--Build a select statement specifying the columns, can be used for automated extract where you just pass the table name.
declare @v_table_name varchar(255),
		@v_counter int,
		@v_row varchar(MAX),
		@v_size int,
		@sql varchar(max),
        @v_run_id varchar(255),
        @v_source varchar(255),
        @v_rows_del int;
set @v_table_name = '$(v_table)'
set @v_source = '$(SOURCE)'
set @v_run_id = '$(RUNID)'
set @v_size =
			(select count(1)
				FROM INFORMATION_SCHEMA.COLUMNS
				WHERE TABLE_NAME = @v_table_name AND TABLE_SCHEMA='DBO')
set @v_counter = 1
set @v_row = ''

--Get column names seperated by commas
WHILE
	@v_counter <= @v_size
BEGIN
	if @v_counter != @v_size
		set @v_row = @v_row + CAST((select column_name FROM INFORMATION_SCHEMA.COLUMNS
						WHERE TABLE_NAME = @v_table_name AND TABLE_SCHEMA='DBO'
						and ordinal_position = @v_counter) as varchar(max)) + ','
	ELSE set @v_row	= @v_row + CAST((select column_name FROM INFORMATION_SCHEMA.COLUMNS
						WHERE TABLE_NAME = @v_table_name AND TABLE_SCHEMA='DBO'
						and ordinal_position = @v_counter) as varchar(max))
	set @v_counter = @v_counter + 1
END

set @SQL = 'Select ' + @v_row + ' FROM ' +  @v_table_name
--create header for output file using replace for pipe, and then output the data by executing the query
SET NOCOUNT ON

select replace(@v_row,',',CHAR(9))
execute(@sql)
if @@ERROR > 0
	print @sql



--Example of dynamically adding columns to a table and then pivoting


/*
	PREP STEPS - Model Scores
*/
IF EXISTS (SELECT 1 FROM
	(SELECT U.NAME AS TABLE_OWNER,O.NAME AS TABLE_NAME
	FROM DBO.SYSOBJECTS O, DBO.SYSUSERS U
	WHERE O.XTYPE ='U' AND U.UID = O.UID)V
		WHERE TABLE_OWNER = 'DBO' AND TABLE_NAME = 'tmp_model_missing_address')
DROP TABLE dbo.tmp_model_missing_address

SELECT distinct c.address_id into dbo.tmp_model_missing_address
FROM dbo.contact c
LEFT JOIN MODEL_SCORE_VIEW V on c.address_id = v.address_id
WHERE v.address_id is null

--Drop index to speed up insert
EXEC DBO.BN_P_DROP_INDEXES 'MODEL_SCORE_VIEW'

--BIND DEFAULTS
EXEC DBO.BN_P_ASSIGN_MODEL_SCORES_DFLTS 'MODEL_SCORE_VIEW'


--INSERT NEW ADDRESSES, SET DEFAULT VALUES FOR THEM
INSERT INTO dbo.MODEL_SCORE_VIEW(ADDRESS_ID)
SELECT ADDRESS_ID
FROM dbo.tmp_model_missing_address;

PRINT 'NEW ADDRESSES ADDED TO MODEL_SCORE_VIEW: ' + CAST(@@ROWCOUNT AS VARCHAR(10))

create clustered index IDX_TMP_PK on DBO.MODEL_SCORE_VIEW(address_id);
UPDATE STATISTICS DBO.MODEL_SCORE_VIEW;

IF EXISTS (SELECT 1 FROM
	(SELECT U.NAME AS TABLE_OWNER,O.NAME AS TABLE_NAME
	FROM DBO.SYSOBJECTS O, DBO.SYSUSERS U
	WHERE O.XTYPE ='U' AND U.UID = O.UID)V
		WHERE TABLE_OWNER = 'DBO' AND TABLE_NAME = 'MODELS_MAX_DATES')

DROP TABLE DBO.MODELS_MAX_DATES

SELECT MODEL_NAME, MAX(UPDATE_DATE) AS UPDATE_DATE
INTO DBO.MODELS_MAX_DATES
FROM DBO.MODEL_SCORES
GROUP BY MODEL_NAME

create clustered index idx_tmp_max_mod_date_upd on DBO.MODELS_MAX_DATES(model_name);


--End Prep

IF EXISTS (SELECT 1 FROM
	(SELECT U.NAME AS TABLE_OWNER,O.NAME AS TABLE_NAME
	FROM DBO.SYSOBJECTS O, DBO.SYSUSERS U
	WHERE O.XTYPE ='U' AND U.UID = O.UID)V
		WHERE TABLE_OWNER = 'DBO' AND TABLE_NAME = 'tmp_dist_aid_model')
drop table tmp_dist_aid_model

select address_id,model_name,score_date,rank
into tmp_dist_aid_model
FROM(
SELECT c.address_id,ms.model_name,ms.score_date,ms.rank,
	   row_number() over(partition by c.address_id, ms.model_name order by ms.score_date desc)rnk
FROM MODEL_SCORES ms
INNER JOIN contact c on ms.contact_id = c.contact_id
)t
where rnk=1;

IF EXISTS (SELECT 1 FROM
	(SELECT U.NAME AS TABLE_OWNER,O.NAME AS TABLE_NAME
	FROM DBO.SYSOBJECTS O, DBO.SYSUSERS U
	WHERE O.XTYPE ='U' AND U.UID = O.UID)V
		WHERE TABLE_OWNER = 'DBO' AND TABLE_NAME = 'MODEL_SCORES_VIEW_NEW')
drop table dbo.MODEL_SCORES_VIEW_NEW

--Pivot results
declare @v_sql varchar(max),@v_columns varchar(max);
set @v_columns = STUFF((SELECT distinct ','+quotename(model_name) from tmp_dist_aid_model FOR XML PATH(''), TYPE).value('.','NVARCHAR(MAX)'),1,1,'');
set @v_columns = (SELECT left(@v_columns,nullif(len(@v_columns)-1,-1) ))
--print @v_columns

set @v_sql = ';WITH CTE AS ('+
		'SELECT address_id, rank, convert(varchar(255),model_name) AS RowNo'+
		' FROM  tmp_dist_aid_model'+
		')'+
		' SELECT * INTO dbo.MODEL_SCORES_VIEW_NEW '+
		'FROM CTE '+
		' PIVOT (MAX(rank) FOR RowNo IN ('+@v_columns+'])) pvt'
print (@v_sql);

EXECUTE(@v_sql);

select * from MODEL_SCORES_VIEW_NEW



;WITH CTE AS (SELECT address_id, rank, convert(varchar(255),model_name) AS RowNo FROM  tmp_dist_aid_model)
SELECT * --INTO dbo.MODEL_SCORES_VIEW_NEW
FROM CTE  PIVOT (MAX(rank) FOR RowNo IN ([IXI_MAY09],[JOSH_TEST1],[JOSH_TEST2],[JOSH_TEST3])) pvt





select * from dbo.MODEL_SCORES_VIEW_NEW

select * from tmp_dist_aid_model;

select * from MODEL_SCORES
insert into MODEL_SCORES
values (1339535393,'JOSH_TEST1',2,getdate(),getdate(),'test',getdate(),'test')

insert into MODEL_SCORES
values (1339535393,'JOSH_TEST2',2,getdate(),getdate(),'test',getdate(),'test')

insert into MODEL_SCORES
values (1339535393,'JOSH_TEST3',2,getdate(),getdate(),'test',getdate(),'test');

DECLARE @v_sql varchar(max),@v_model varchar(255)

SELECT * INTO MODEL_SCORE_VIEW_NEW
FROM MODEL_SCORE_VIEW;

select count(*) from MODEL_SCORE_VIEW_NEW

drop table MODEL_SCORE_VIEW_NEW


--Add new columns to model_scores_view_new;
DECLARE @v_sql varchar(max),@v_model varchar(255)

DECLARE csr_model cursor FOR
SELECT DISTINCT MODEL_NAME FROM dbo.view_models a
WHERE not exists (select 1 from information_schema.columns s where table_name = 'MODEL_SCORES_VIEW_NEW'
							and a.model_name = s.column_name)
ORDER BY MODEL_NAME

OPEN csr_model
FETCH NEXT FROM csr_model into @v_model;

WHILE @@FETCH_STATUS = 0
BEGIN
	set @v_sql = 'ALTER TABLE MODEL_SCORE_VIEW_NEW ADD '+@v_model+' varchar(255) default '' '' not null;'
	EXECUTE(@v_sql);
	FETCH NEXT FROM csr_model into @v_model;
END
CLOSE csr_model;
DEALLOCATE csr_model;



--Store column data from multiple rows in one variable
select 'Josh' name, 1241 phone
into jtest
union
select 'Josh' name, 1234 phone
union
select 'Jill' name, 1251 phone
;
GO


declare @col_list varchar(max)
set @col_list = ' '
select @col_list = coalesce(@col_list + ';','')+name
FROM jtest

select STUFF(@col_list,1,1,'');

--stuff for xml
SELECT name, phone = STUFF((
    SELECT ', ' + phone FROM jtest
    WHERE [name] = x.[name]
    FOR XML PATH(''), TYPE).value('.[1]', 'nvarchar(max)'), 1, 2, '')
FROM jtest AS x
GROUP BY [name];

--Ignore dupes on unique index.  Wont insert them.



create table josh_testing_index
(
	id int,
	name varchar(255)
)

create unique nonclustered index idx_jtest on josh_testing_index (name);

insert into josh_testing_index(id,name)
SELECT 1,'Josh'

insert into josh_testing_index(id,name)
SELECT 1,'Josh'

--Error message
--Msg 2601, Level 14, State 1, Line 14
--Cannot insert duplicate key row in object 'dbo.josh_testing_index' with unique index 'idx_jtest'. The duplicate key value is (Josh).
--The statement has been terminated.

ALTER INDEX idx_jtest ON josh_testing_index REBUILD WITH (IGNORE_DUP_KEY = ON);

insert into josh_testing_index(id,name)
SELECT 1,'Josh'

SELECT * FROM josh_testing_index;


--counter loop
CREATE TABLE table_counter
(
	table_name varchar(255),
	table_count int
)

INSERT INTO table_counter (table_name)
SELECT table_name from INFORMATION_SCHEMA.tables  order by table_name

SELECT * FROM table_counter

truncate table table_counter


DECLARE @v_sql nvarchar(max), @v_table varchar(255),@v_count int
DECLARE csr_tables cursor FOR
SELECT table_name from INFORMATION_SCHEMA.tables  order by table_name

OPEN csr_tables
FETCH NEXT FROM csr_tables into @v_table;

WHILE @@
 = 0
BEGIN
	set @v_sql = 'SELECT @v_cnt = count(*) FROM ' +@v_table+' '
	EXECUTE sp_executesql @v_sql, N'@v_cnt int out', @v_count out

	IF @v_count > 0
	BEGIN
		INSERT INTO table_counter
		VALUES (@v_table,@v_count);
	END;

	FETCH NEXT FROM csr_tables into @v_table;
END
CLOSE csr_tables;
DEALLOCATE csr_tables;


--Space checks
SELECT TOP 1
                   CAST(ROUND(size,2) AS VARCHAR) +'GB' AS [Database Size]
                  ,CAST(ROUND(size * .7,2) AS VARCHAR)+'GB' AS [Approximate .sqb file size]
                  ,CAST(ROUND(size * 1.7,2) AS VARCHAR) +'GB' AS [Total Space Needed to Restore]
                  ,IName
                  ,dbName
                  ,dateAdded
       FROM DBLOG.BULLHORN_DB_MONITOR.BULLHORN1.BH_DatabaseSize
     WHERE dbName = 'BULLHORN241' --replace your value
          AND dateadded > DATEADD(WW,-1,GETDATE())
     ORDER BY dateAdded DESC


--max length proc
CREATE PROCEDURE dbo.FindMaxLengths (@DATABASE varchar(255),@schemaName varchar(255),@TableName varchar(255))
AS

DECLARE @SQL VARCHAR(MAX),@COL_LIST VARCHAR(MAX);
--SET @TABLE_NAME = 'pstmp_20150626_BrandDefinition_companies'

SET @COL_LIST = '';
SELECT @col_list = COALESCE(@COL_LIST+',','')+'max(len('+column_name+')) AS '+COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @TableName
AND DATA_TYPE NOT IN ('text')

SET @SQL = 'SELECT '+STUFF(@COL_LIST,1,1,'')+' FROM '+@DATABASE+'.'+@schemaName+'.'+@TableName
--print(@SQL)
exec(@SQL)



EXEC dbo.FindMaxLengths 'bullhorn1345','dbo','pstmp_20150626_BrandDefinition_companies'


--xml
USE SNI_BM_MIG_Template
--DROP TABLE Applicant_References
CREATE TABLE Applicant_References (
       ID nvarchar(255),
       Name nvarchar(255),
       Company nvarchar(255),
       Phone nvarchar(255),
       Email nvarchar(255),
       Comments nvarchar(max),
       ContactDate nvarchar(255),
       ApplicantID nvarchar(255),
       EmployeeID nvarchar(255),
       Verified nvarchar(255)
       )

DECLARE @id INT = 1
WHILE @id < 18
BEGIN
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @XML VARCHAR(MAX)
DECLARE @idoc INT =1
SELECT @XML = BulkColumn
FROM OPENROWSET (BULK ''X:\Ryan\SNI\XML\applicant_reference_'+ RIGHT('0000'+cast(@id as varchar),5)+'.xml'', SINGLE_BLOB) AS x

EXEC sp_xml_preparedocument @idoc OUTPUT, @XML

INSERT INTO Applicant_References (
       ID,
       Name,
       Company,
       Phone,
       Email,
       Comments,
       ContactDate,
       ApplicantID,
       EmployeeID,
       Verified
       )
SELECT ID,
       Name,
       Company,
       Phone,
       Email,
       Comments,
       ContactDate,
       ApplicantID,
       EmployeeID,
       Verified
  FROM OPENXML (@idoc, ''/Notes/Note'',2)
  WITH (ID nvarchar(255),
       Name nvarchar(255),
       Company nvarchar(255),
       Phone nvarchar(255),
       Email nvarchar(255),
       Comments nvarchar(max),
       ContactDate nvarchar(255),
       ApplicantID nvarchar(255),
       EmployeeID nvarchar(255),
       Verified nvarchar(255))
'
SET @id = @id+1
EXEC sp_executesql @SQL
END



SELECT COUNT(*) FROM Applicant_References
SELECT TOP 1000 * FROM Applicant_References

go

-----EDUCATION---------------------------------------------------------------------

USE SNI_BM_MIG_Template
--DROP TABLE Applicant_Education
CREATE TABLE Applicant_Education (
       Institution nvarchar(255),
       Degree nvarchar(255),
       Major nvarchar(255),
       Minor nvarchar(255),
       Certification nvarchar(255),
       Notes nvarchar(max),
       EducationType nvarchar(255),
       ApplicantID nvarchar(255)
       )

DECLARE @id INT = 1
WHILE @id < 11
BEGIN
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @XML VARCHAR(MAX)
DECLARE @idoc INT =1
SELECT @XML = BulkColumn
FROM OPENROWSET (BULK ''X:\Ryan\SNI\XML\applicant_education_'+ RIGHT('0000'+cast(@id as varchar),5)+'.xml'', SINGLE_BLOB) AS x

EXEC sp_xml_preparedocument @idoc OUTPUT, @XML

INSERT INTO Applicant_Education (
       Institution,
       Degree,
       Major,
       Minor,
       Certification,
       Notes,
       EducationType,
       ApplicantID
       )
SELECT Institution,
       Degree,
       Major,
       Minor,
       Certification,
       Notes,
       EducationType,
       ApplicantID
  FROM OPENXML (@idoc, ''/Notes/Note'',2)
  WITH (Institution nvarchar(255),
       Degree nvarchar(255),
       Major nvarchar(255),
       Minor nvarchar(255),
       Certification nvarchar(255),
       Notes nvarchar(max),
       EducationType nvarchar(255),
       ApplicantID nvarchar(255))
'
SET @id = @id+1
EXEC sp_executesql @SQL
END



SELECT COUNT(*) FROM Applicant_Education
SELECT TOP 1000 * FROM Applicant_Education



--Seperating towns out

WITH CTE_town
AS
(
	SELECT 'Houghton (Shreveport, Dallas)' AS town
	UNION
    SELECT 'Test, Town' AS town
	UNION
	SELECT 'Town1' AS town
)
SELECT
	town,
	CASE WHEN town LIKE '%(%,%)%'
	THEN
	'"'+LTRIM(RTRIM(SUBSTRING(town,1,(CHARINDEX('(',town)-1)))) + '""'+ LTRIM(RTRIM(SUBSTRING(town,CHARINDEX('(',town) +1,(CHARINDEX(',',town)-1)-CHARINDEX('(',town)) ))+ '""'
	+ LTRIM(RTRIM(SUBSTRING(town,CHARINDEX(',',town)+1, (CHARINDEX(')',town) -1) - CHARINDEX(',',town)) )) + '"'
		WHEN town LIKE '%,%'
	THEN
	'"'+LTRIM(RTRIM(SUBSTRING(town,1,CHARINDEX(',',town)-1)))+'""'+LTRIM(RTRIM( SUBSTRING(town,CHARINDEX(',',town)+1, (LEN(town)-CHARINDEX(',',town)) )))+'"'
	ELSE '"'+LTRIM(RTRIM(town))+'"'
	END towns
FROM CTE_town



WITH CTE_town
AS
(
	SELECT 'Houghton (Shreveport, Dallas)' AS town
	UNION
    SELECT 'Houghtonsborough, Boston' AS town
	UNION
	SELECT 'Wakefield' AS town
	UNION
	SELECT 'Seaport (Boston)' AS town
	UNION
  SELECT 'Weatherford (Fort Worth/Boston), Dallas' AS town
	UNION
	SELECT 'Houghton (Shreveport, Dallas, town2,town3)' AS town
	UNION
	SELECT 'Wakefield (town1,town2,town3,town4,town5),town6,(town7,town8),town9' AS town
)
SELECT
	town,
	LTRIM(RTRIM(REPLACE(REPLACE(REPLACE((
		REPLACE(REPLACE(REPLACE(town,'/',','),'(',','),')','')
		),' ,',','),', ',','),',',', ')
		))
FROM
CTE_town


--running
SELECT
    P.spid,
    RIGHT(CONVERT(VARCHAR, DATEADD(ms, DATEDIFF(ms, P.last_batch, GETDATE()),
                                   '1900-01-01'), 121), 12) AS 'batch_duration',
    P.program_name,
    P.hostname,
    P.loginame,
    P.cmd,
    P.cpu,
    P.status,
    P.memusage
FROM
    master.dbo.sysprocesses P
WHERE
    P.spid > 50
    AND P.status NOT IN ( 'background', 'sleeping' )
ORDER BY
    cpu DESC;

--client name by db
SELECT   a1.value
   ,pl.*
FROM   BULLHORN1.BH_PrivateLabelAttribute a1
inner join  BULLHORN1.BH_PrivateLabel pl
on    a1.privatelabelid = pl.privatelabelid
WHERE   a1.name  = 'databaseinstance'
and    cast(a1.value as varchar(200)) = 'bullhorn7950'


-- Find server/instance/name etc based on client name
SELECT
    a1.value,
    dc.name,
    dc.primaryServer,
    c.corporationID,
    pl.*
FROM
    BULLHORN1.BH_PrivateLabelAttribute a1
INNER JOIN BULLHORN1.BH_PrivateLabel pl
    ON a1.privateLabelID = pl.privateLabelID
INNER JOIN BULLHORN1.BH_Corporation c
    ON pl.privateLabelID = c.privateLabelID
INNER JOIN BULLHORN1.BH_DatabaseInstance di
    ON CAST(a1.value AS VARCHAR(MAX)) = CAST(di.name AS VARCHAR(MAX))
INNER JOIN BULLHORN1.BH_DatabaseCluster dc
    ON di.databaseClusterID = dc.databaseClusterID
WHERE
    a1.name = 'databaseinstance'
--and    cast(a1.value as varchar(200)) = 'bullhorn7950'
    AND pl.name LIKE '%Teknetex%'


--Windowed functions
CREATE TABLE #Transactions
 (
 AccountId INTEGER,
 TranDate DATE,
 TranAmt NUMERIC(8, 2)
 );
INSERT INTO #Transactions
SELECT *
FROM ( VALUES ( 1, '2011-01-01', 500),
 ( 1, '2011-01-15', 50),
 ( 1, '2011-01-22', 250),
 ( 1, '2011-01-24', 75),
 ( 1, '2011-01-26', 125),
 ( 1, '2011-01-26', 175),
 ( 2, '2011-01-01', 500),
 ( 2, '2011-01-15', 50),
 ( 2, '2011-01-22', 25),
 ( 3, '2011-01-22', 5000),
 ( 3, '2011-01-27', 550),
 ( 3, '2011-01-27', 95 ),
 ( 3, '2011-01-30', 2500)
 ) dt (AccountId, TranDate, TranAmt);

 --Sum over partition
 SELECT
    AccountId,
    TranDate,
    TranAmt,
 -- running total of all transactions
    RunTotalAmt = SUM(TranAmt) OVER ( PARTITION BY AccountId ORDER BY TranDate )
 FROM
    #Transactions AS t
 ORDER BY
    AccountId,
    TranDate;


--Sum over partition rows unbounded.  If there is a dupe in order by it will continue to count it properly, compare columns output to see.
SELECT
    AccountId,
    TranDate,
    TranAmt,
 -- running total of all transactions
    RunTotalAmt = SUM(TranAmt) OVER ( PARTITION BY AccountId ORDER BY TranDate ),
 -- "Proper" running total by row position
    RunTotalAmt2 = SUM(TranAmt) OVER ( PARTITION BY AccountId ORDER BY TranDate
 ROWS UNBOUNDED PRECEDING )
FROM
    #Transactions AS t
ORDER BY
    AccountId,
    TranDate;


--Check oldest open transaction
DBCC OPENTRAN('MBSAssociates_Old');

Oldest active transaction:
    SPID (server process ID): 2001
    UID (user ID) : -1
    Name          : user_transaction
    LSN           : (130557:96:1)
    Start time    : Sep 14 2015 11:07:18:083AM
    SID           : 0x01050000000000051500000078006d1f7ceb240d07e53b2bb82f0000
DBCC execution completed. If DBCC printed error messages, contact your system administrator.

--The query running
SELECT s.text
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) s
WHERE c.most_recent_session_id = 2001;--use the session_id returned by the previous query
GO

--See blocks
SELECT blocking_session_id, wait_duration_ms, session_id
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL;
GO

--Create an index on view
--must use 2 part schema naming convention
--must be in same database
--can not make changes to any underlying tables that would effect the view definition
--must use SchemaBinding in definition
CREATE VIEW dbo.v_Product_Sales_By_LineTotal
WITH SCHEMABINDING
AS
SELECT p.ProductID,
 p.Name AS ProductName,
 SUM(LineTotal) AS LineTotalByProduct,
 COUNT_BIG(*) AS LineItems
FROM Sales.SalesOrderDetail s
 INNER JOIN Production.Product p
 ON s.ProductID = p.ProductID
GROUP BY p.ProductID,
 p.Name;

CREATE UNIQUE CLUSTERED INDEX UCI_v_Product_Sales_By_LineTotal
ON dbo.v_Product_Sales_By_LineTotal (ProductID);
GO
CREATE NONCLUSTERED INDEX NI_v_Product_Sales_By_LineTotal
ON dbo.v_Product_Sales_By_LineTotal (ProductName);
GO


--Merge example
MERGE INTO pstmp_20150915_Company_Insert pst
USING (SELECT * FROM (
			SELECT
				companyId,
				[outlet url],
				ROW_NUMBER() OVER(PARTITION BY companyId ORDER BY contactID) rown
			FROM
				pstmp_ImportedValues
			WHERE
				ISNULL([outlet url],'') != '')t
		WHERE rown = 1
		) iv
ON (pst.legacyCompanyId = iv.companyID
	AND ISNULL(pst.customText2,'') = '')
WHEN MATCHED THEN UPDATE
	SET
		pst.customText2 = iv.[outlet url];




--Indexes usage:
SELECT
    OBJECT_NAME(sis.object_id) TableName,
    si.name AS IndexName,
    sc.name AS ColumnName,
    sic.index_id,
    sis.user_seeks,
    sis.user_scans,
    sis.user_lookups,
    sis.user_updates
FROM
    sys.dm_db_index_usage_stats sis
INNER JOIN sys.indexes si
    ON sis.object_id = si.object_id
    AND sis.index_id = si.index_id
INNER JOIN sys.index_columns sic
    ON sis.object_id = sic.object_id
    AND sic.index_id = si.index_id
INNER JOIN sys.columns sc
    ON sis.object_id = sc.object_id
    AND sic.column_id = sc.column_id
WHERE
    sis.database_id = DB_ID('BULLHORN1345')
AND sis.object_id = OBJECT_ID('bullhorn1.bh_userContact');



--Indexes that are not used
SELECT
    OBJECT_NAME(I.object_id) OBJECTNAME,
    I.name INDEXNAME,
    I.index_id
FROM
    sys.indexes I
JOIN sys.objects O
    ON I.object_id = O.object_id
WHERE
    OBJECTPROPERTY(O.object_id, 'IsUserTable') = 1
    AND I.index_id NOT IN ( SELECT
                                S.index_id
                            FROM
                                sys.dm_db_index_usage_stats S
                            WHERE
                                S.object_id = I.object_id
                                AND I.index_id = S.index_id
                                AND database_id = DB_ID() )
ORDER BY
    OBJECTNAME,
    I.index_id,
    INDEXNAME ASC;

--Who's in my database?
DECLARE @AllConnections TABLE(
    SPID INT,
    Status VARCHAR(MAX),
    LOGIN VARCHAR(MAX),
    HostName VARCHAR(MAX),
    BlkBy VARCHAR(MAX),
    DBName VARCHAR(MAX),
    Command VARCHAR(MAX),
    CPUTime INT,
    DiskIO INT,
    LastBatch VARCHAR(MAX),
    ProgramName VARCHAR(MAX),
    SPID_1 INT,
    REQUESTID INT
)

INSERT INTO @AllConnections EXEC sp_who2

SELECT * FROM @AllConnections WHERE DBName = 'YourDatabaseName'


USE Simplicity_Mig_Template

alter PROCEDURE checkDupes @columnNames VARCHAR(MAX),@tableName VARCHAR(MAX) AS

DECLARE @sql VARCHAR(MAX), @err INT, @rows int

SET NOCOUNT ON
SET @sql = 'SELECT '+@columnNames +', count(*) FROM '+@tableName +' GROUP BY '+ @columnNames +' having count(*)>1'

EXEC (@sql)
SELECT @rows = @@ROWCOUNT,@err = @@ERROR

IF @err != 0
BEGIN
	PRINT CHAR(10)+'ERROR!!! '+CHAR(10)+CHAR(10)+'SQL ran : '+@sql
END

IF @rows > 0 AND @err = 0
BEGIN
	PRINT 'There are '+CAST(@rows AS varchar(MAX))+' duplicates on columns ' +@columnNames+' on table '+ @tableName
END

IF @rows = 0 AND @err = 0
BEGIN
	PRINT 'No Duplicates on columns ' +@columnNames+' on table '+ @tableName
END

SET NOCOUNT OFF
GO

EXEC checkDupes 'externalId,externalSource','_clientCorporation'

CREATE TABLE #joshTesting
(
id INT,
name VARCHAR(MAX)
)

INSERT INTO #joshTesting
SELECT 1,'Josh'

EXEC checkDupes 'id,name','#joshTesting'

alter PROCEDURE checkDupes @columnNames VARCHAR(MAX),@tableName VARCHAR(MAX) AS

DECLARE @sql VARCHAR(MAX)

SET @sql = 'SELECT '+@columnNames +', count(*) FROM '+@tableName +' GROUP BY '+ @columnNames +' having count(*)>1'

EXEC (@sql)
IF @@ERROR != 0
BEGIN
 PRINT CHAR(10)+'ERROR!!! '+CHAR(10)+CHAR(10)+'SQL ran :'+@sql
END
GO

EXEC checkDupes 'externalId,externalSource','_clientCorporation'





--Using sp_msForEachTable proc...

CREATE PROCEDURE [dbo].[bhsp_util_RecordCounts]  AS
BEGIN
-----------------------------------------------------------------------------------------------------------------------------------------------
-- This procedure will list all User Tables in a database and the Record Count for each table
-----------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #RecordCounts
(
    TableName VARCHAR(255),
    NumRecs INT
)

INSERT #RecordCounts
    EXEC sp_msForEachTable
        'SELECT PARSENAME(''?'', 1),
        COUNT(*) FROM ?'
SELECT TableName, NumRecs FROM #RecordCounts
ORDER BY TableName
DROP TABLE #RecordCounts
END

--Export any table
CREATE PROCEDURE [dbo].[xp_ExportTable]
@tablename VARCHAR(255),
@outputfolder VARCHAR(255),
@windowsAuthenticationOnly INT = 1

AS

SET NOCOUNT ON

DECLARE @sqlserverInstance VARCHAR(50)
DECLARE @saUsername VARCHAR(50)
DECLARE @saPassword VARCHAR(500)
DECLARE @databaseName VARCHAR(100)
DECLARE @vSelectQuery VARCHAR(8000)
DECLARE @vBcpCommand VARCHAR(8000)
DECLARE @vQueryOutToFilename VARCHAR(1000)

SET @sqlserverInstance = CAST(SERVERPROPERTY('ServerName') AS VARCHAR(50))
SET @saUsername = ''
SET @saPassword = ''
SET @databaseName = DB_NAME()

IF SUBSTRING(REVERSE(@outputfolder),1,1) <> '\'
  BEGIN SET @outputfolder = @outputfolder + '\' END

IF @windowsAuthenticationOnly = 1
  BEGIN SET @vQueryOutToFilename = ' queryout ' + @outputfolder + REPLACE(@tablename, 'dbo.', '') + '.csv -S' + @sqlserverInstance + ' -T -w ' END
ELSE
  BEGIN SET @vQueryOutToFilename = ' queryout ' + @outputfolder + REPLACE(@tablename, 'dbo.', '') + '.csv -S' + @sqlserverInstance + ' -U' + @sausername + ' -P' + @sapassword + ' -w ' END

SET @vSelectQuery = ' bcp "select * from ' + @databaseName + '.dbo.' + @tablename + '" '
SET @vBcpCommand  = @vSelectQuery + @vQueryOutToFilename
EXEC master..xp_cmdshell @vBcpCommand
GO
--'

--See what database is hogging the resources
;WITH DB_CPU_Statistics
AS
(
	SELECT
		pa.DatabaseID,
		DB_NAME(pa.DatabaseID) AS [Database Name],
		SUM(qs.total_worker_time/1000) AS [CPU_Time_Ms]
FROM
	sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY (SELECT CONVERT(INT, value) AS [DatabaseID]
			 FROM sys.dm_exec_plan_attributes(qs.plan_handle)
			 WHERE attribute = N'dbid') AS pa
GROUP BY DatabaseID
)
SELECT
	ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [CPU Ranking],
	[Database Name],
	[CPU_Time_Ms] AS [CPU Time (ms)],
	CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPU Percent]
FROM
	DB_CPU_Statistics
WHERE
	DatabaseID <> 32767 -- ResourceDB
ORDER BY [CPU Ranking] OPTION (RECOMPILE);



--Explain plan joins
-- Hash joins can be used on any size of data
--	Inner table is not indexed outer can be... small outer table large inner
-- Merge Large data sets
--	Both tables must have an index, if not it is still possible to have sorts then merge joins in the explain plan
--	but this will greatly slow down the query
-- Nested Loops
--	Inner table must be indexes and outer should be.  Good on small data sets
--more...
/*
Nested Loop:
A nested loop join uses one join input as the outer input table and the other as the inner input table. The outer
input table is shown as the top input in the execution plan, and the inner input table is shown as the bottom input
table. The outer loop consumes the outer input table row by row. The inner loop, executed for each outer row,
searches for matching rows in the inner input table.

Nested loop joins are highly effective if the outer input is quite small and the inner input is larger but indexed.
In many simple queries affecting a small set of rows, nested loop joins are far superior to both hash and merge joins.
Joins operate by gaining speed through other sacrifices. A loop join can be fast because it uses memory to take a small
set of data and compare it quickly to a second set of data. A merge join similarly uses memory and a bit of tempdb to
do its ordered comparisons. A hash join uses memory and tempdb to build out the hash tables for the join. Although a
loop join can be faster at small data sets, it can slow down as the data sets get larger or there aren’t indexes to support
the retrieval of the data. That’s why SQL Server has different join mechanisms.

Even for small join inputs, such as in the previous query, it’s important to have an index on the joining columns.
As you saw in the preceding execution plan, for a small set of rows, indexes on joining columns allow the query
optimizer to consider a nested loop join strategy. A missing index on the joining column of an input will force the
query optimizer to use a hash join instead.

Merge Join:
A merge join requires both join inputs
to be sorted on the merge columns, as defined by the join criterion. If indexes are available on both joining columns,
then the join inputs are sorted by the index. Since each join input is sorted, the merge join gets a row from each input
and compares them for equality. A matching row is produced if they are equal. This process is repeated until all rows
are processed.
In situations where the data is ordered by an index, a merge join can be one of the fastest join operations, but if
the data is not ordered and the optimizer still chooses to perform a merge join, then the data has to be ordered by an
extra operation, a sort. This can make the merge join slower and more costly in terms of memory and I/O resources.
In this case, the query optimizer found that the join inputs were both sorted (or indexed) on their joining
columns.

Hash:
The hash join performs its operation in two phases: the build phase and the probe phase. In the most commonly
used form of hash join, the in-memory hash join, the entire build input is scanned or computed, and then a hash
table is built in memory. Each row from the outer input is inserted into a hash bucket depending on the hash value
computed for the hash key (the set of columns in the equality predicate). A hash is just a mathematical construct run
against the values in question and used for comparison purposes.
This build phase is followed by the probe phase. The entire probe input is scanned or computed one row at a
time, and for each probe row, a hash key value is computed. The corresponding hash bucket is scanned for the hash
key value from the probe input, and the matches are produced.
*/

--B tree indexes
--	basic design
--			  1,10,19
--		 /	    |         \
--		/		|		   \
--	1,4,7	 10,13,16	19,22,26
--	/ | \	  / | \		   / | \

--Search downward narrowing it down each time through each node and through each leaf

--update the jira ticket
--change \\migratedb0 to match your staging server
DECLARE @uwfd VARCHAR(8000) = (SELECT 'dir /s /-C X:\PSFileServer1\UserFiles\UserWorkFiles\' + CAST(privateLabelID AS VARCHAR) FROM mig.settings)
DECLARE @uwfd2 table (id int identity, content varchar(8000))
DECLARE @ccfd VARCHAR(8000) = (SELECT 'dir /s /-C X:\PSFileServer1\UserFiles\UserAttachments\ClientCorporationFiles\' + CAST(privateLabelID AS VARCHAR) FROM mig.settings)
DECLARE @ccfd2 table (id int identity, content varchar(8000))
INSERT @uwfd2 exec xp_cmdshell @uwfd
INSERT @ccfd2 exec xp_cmdshell @ccfd
select
	sizeGB = (SELECT sum(size * 8.0 / 1048576.0) FROM sys.databases db JOIN sys.master_files mf ON mf.database_id = db.database_id WHERE s.BullhornDatabaseName = db.name),
	UserWorkFileLocation = '\\migratedb0\x$\PSFileServer1\UserFiles\UserWorkFiles\' + CAST(s.privateLabelID AS VARCHAR),
	UserWorkFileMB = (select cast(dbo.bhfn_ReturnNumbersOnly(substring(content,charindex(')',content) + 1, 255)) as bigint) / 1048576 from @uwfd2 t1 where (select max(id) - 2 from @uwfd2 t2) = t1.id),
	ClientCorporationFileLocation = '\\migratedb0\x$\PSFileServer1\UserFiles\UserAttachments\ClientCorporationFiles\' + CAST(s.privateLabelID AS VARCHAR),
	ClientCorporationFileMB = (select cast(dbo.bhfn_ReturnNumbersOnly(substring(content,charindex(')',content) + 1, 255)) as bigint) / 1048576 from @ccfd2 t1 where (select max(id) - 2 from @ccfd2 t2) = t1.id),
	users = (select count(1) from bh_usercontact where recordtypebits = 4),
	candidates = (select count(1) from bh_usercontact where recordtypebits = 1),
	notes = (select count(1) from bh_usercomment)
FROM mig.settings s

--'
--Extract files cursor

DECLARE @filetext VARbinary(MAX),
@original_date datetime,
@DESTPATH VARCHAR(MAX),
@ObjectToken INT,
@doc_id VARCHAR(210),
@extension varchar(10)

DECLARE CVPATH CURSOR FAST_FORWARD FOR
SELECT cast(his.attachbinary as varbinary(max)), cast(his.history_id as varchar(100)), dbo.bhfn_Get_FileExtension(his.attachtype,'unk')
from history his
where his.AttachBinary is not null
--and his.history_id='00004K3J'
OPEN CVPATH

FETCH NEXT FROM CVPATH INTO @filetext, @doc_id, @extension

WHILE @@FETCH_STATUS = 0
BEGIN
SET @DESTPATH = '\\migratedb0\f$\ClientData\Josh\HrSolutions\files\' + CAST(@doc_id AS varchar(max)) + '.' + @extension

EXEC sp_OACreate 'ADODB.Stream', @ObjectToken OUTPUT
EXEC sp_OASetProperty @ObjectToken, 'Type', 1
EXEC sp_OAMethod @ObjectToken, 'Open'
EXEC sp_OAMethod @ObjectToken, 'Write', NULL, @filetext
EXEC sp_OAMethod @ObjectToken, 'SaveToFile', NULL, @DESTPATH, 2
EXEC sp_OAMethod @ObjectToken, 'Close'
EXEC sp_OADestroy @ObjectToken

FETCH NEXT FROM CVPATH INTO @filetext, @doc_id, @extension
END

CLOSE CVPATH
DEALLOCATE CVPATH
--'

--Loop inserts
DROP TABLE valid_emails
CREATE TABLE valid_emails
(
    ECID NUMERIC(22,0),
    Email_metadata_mdk NUMERIC(22,0),
    journal_content VARCHAR(MAX)
)

ALTER TABLE EMAIL_CONTENT ADD ID INT IDENTITY

--Keep a log of what is going on
CREATE TABLE dbo.pstmp_LoopLog (
    OpType VARCHAR(150),
    ID_From INT,
    ID_To INT,
    DateStarted DATETIME,
    DateCompleted DATETIME,
    RecordCount INT,
    ErrorMessage VARCHAR(MAX)
)

DECLARE @j int = 0
DECLARE @ErrorMessage VARCHAR(MAX) = ''
DECLARE @RowCount INT = 0
WHILE @j < 2500000
BEGIN
    BEGIN TRY
    --Create log entry:
        INSERT INTO dbo.pstmp_LoopLog (OpType,ID_From,ID_To,DateStarted)
        SELECT 'ValidEmails',@j + 1 , @j + 10000,GETDATE();

    INSERT INTO valid_emails (ecid, Email_metadata_mdk, journal_content)
    SELECT
        ecid,
        Email_metadata_mdk,
        SUBSTRING(journal_content,CHARINDEX('quoted-printable',journal_content)+16,LEN(journal_content)) AS journal_content
    FROM
        EMAIL_CONTENT ec
    WHERE
        meetsCriteria = 'Y'
    AND EXISTS(SELECT 1 FROM emailsWeWant ww
                WHERE ec.EMAIL_METADATA_MDK = ww.email_metaData_mdk)
    AND ID BETWEEN @j + 1 AND @j + 10000

    SET @RowCount = @@ROWCOUNT
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()
    END CATCH
        --Complete log entry:
        UPDATE dbo.pstmp_LoopLog
           SET DateCompleted = GETDATE(),
               RecordCount = @RowCount,
               ErrorMessage = @ErrorMessage
         WHERE ID_From = @j+1
        --Reset loop variables:
        SET @RowCount = 0
        SET @ErrorMessage = ''
        SET @j = @j + 10000
END


--find old databases and drop them
SELECT suser_sname(owner_sid) dbowner,name,create_date,'drop database '+name+'
go'
FROM sys.databases
WHERE
(
   suser_sname(owner_sid) like '%danson%'
or suser_sname(owner_sid) like '%roorda%'
or suser_sname(owner_sid) like '%thimmig%'
or suser_sname(owner_sid) like '%zaiter%'
or suser_sname(owner_sid) like '%zaiter%'
)
ORDER BY create_date


--Schema compare
SELECT table_name,column_name FROM BULLHORN9861.INFORMATION_SCHEMA.COLUMNS --up to date db
WHERE TABLE_NAME NOT LIKE 'temp%'
AND table_name NOT LIKE 'pstmp%'
EXCEPT
SELECT table_name,column_name FROM BULLHORN9609.INFORMATION_SCHEMA.COLUMNS --your DB
WHERE TABLE_NAME NOT LIKE 'temp%'
AND table_name NOT LIKE 'pstmp%'

with events_cte as(
   select
       DATEADD(mi,
       DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
       xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [err_timestamp],
       xevents.event_data.value('(event/data[@name="severity"]/value)[1]', 'bigint') AS [err_severity],
       xevents.event_data.value('(event/data[@name="error_number"]/value)[1]', 'bigint') AS [err_number],
       xevents.event_data.value('(event/data[@name="message"]/value)[1]', 'nvarchar(512)') AS [err_message],
      xevents.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') AS [sql_text],
       xevents.event_data.value('(event/action[@name="database_id"]/value)[1]', 'nvarchar(max)') AS [db_id],
       xevents.event_data
   from sys.fn_xe_file_target_read_file
   ('D:\LG1_Data\what_queries_are_failing*.xel',
   'D:\LG1_Data\what_queries_are_failing*.xem',
   null, null)
   cross apply (select CAST(event_data as XML) as event_data) as xevents
)
SELECT *,db_name([db_id])
from events_cte
WHERE db_name([db_id]) = 'BULLHORN8205'
order by events_cte.err_timestamp

WITH [Blocking]
AS (SELECT w.[session_id]
   ,s.[original_login_name]
   ,s.[login_name]
   ,w.[wait_duration_ms]
   ,w.[wait_type]
   ,r.[status]
   ,r.[wait_resource]
   ,w.[resource_description]
   ,s.[program_name]
   ,w.[blocking_session_id]
   ,s.[host_name]
   ,r.[command]
   ,r.[percent_complete]
   ,r.[cpu_time]
   ,r.[total_elapsed_time]
   ,r.[reads]
   ,r.[writes]
   ,r.[logical_reads]
   ,r.[row_count]
   ,q.[text]
   ,q.[dbid]
   ,p.[query_plan]
   ,r.[plan_handle]
 FROM [sys].[dm_os_waiting_tasks] w
 INNER JOIN [sys].[dm_exec_sessions] s ON w.[session_id] = s.[session_id]
 INNER JOIN [sys].[dm_exec_requests] r ON s.[session_id] = r.[session_id]
 CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) q
 CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) p
 WHERE w.[session_id] > 50
  AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT'
      ,'ASYNC_NETWORK_IO'))
SELECT b.[session_id] AS [WaitingSessionID]
      ,b.[blocking_session_id] AS [BlockingSessionID]
      ,b.[login_name] AS [WaitingUserSessionLogin]
      ,s1.[login_name] AS [BlockingUserSessionLogin]
      ,b.[original_login_name] AS [WaitingUserConnectionLogin]
      ,s1.[original_login_name] AS [BlockingSessionConnectionLogin]
      ,b.[wait_duration_ms] AS [WaitDuration]
      ,b.[wait_type] AS [WaitType]
      ,t.[request_mode] AS [WaitRequestMode]
      ,UPPER(b.[status]) AS [WaitingProcessStatus]
      ,UPPER(s1.[status]) AS [BlockingSessionStatus]
      ,b.[wait_resource] AS [WaitResource]
      ,t.[resource_type] AS [WaitResourceType]
      ,t.[resource_database_id] AS [WaitResourceDatabaseID]
      ,DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName]
      ,b.[resource_description] AS [WaitResourceDescription]
      ,b.[program_name] AS [WaitingSessionProgramName]
      ,s1.[program_name] AS [BlockingSessionProgramName]
      ,b.[host_name] AS [WaitingHost]
      ,s1.[host_name] AS [BlockingHost]
      ,b.[command] AS [WaitingCommandType]
      ,b.[text] AS [WaitingCommandText]
      ,b.[row_count] AS [WaitingCommandRowCount]
      ,b.[percent_complete] AS [WaitingCommandPercentComplete]
      ,b.[cpu_time] AS [WaitingCommandCPUTime]
      ,b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime]
      ,b.[reads] AS [WaitingCommandReads]
      ,b.[writes] AS [WaitingCommandWrites]
      ,b.[logical_reads] AS [WaitingCommandLogicalReads]
      ,b.[query_plan] AS [WaitingCommandQueryPlan]
      ,b.[plan_handle] AS [WaitingCommandPlanHandle]
FROM [Blocking] b
INNER JOIN [sys].[dm_exec_sessions] s1
ON b.[blocking_session_id] = s1.[session_id]
INNER JOIN [sys].[dm_tran_locks] t
ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] = 'WAIT'
GO


select s.[host_name]
, s.login_name
-- , s.is_user_process
,DB_NAME(r.database_id) [Database]
, s.program_name
, r.wait_type
,r.wait_resource
, r.command
, r.status
, s.session_id
, r.blocking_session_id
, datediff( ms, r.start_time, getDate() ) as age_ms
, r.total_elapsed_time
, r.cpu_time
, r.percent_complete
, r.row_count
, r.granted_query_memory
, r.logical_reads
, txt.[text] as query_text
,r.plan_handle
from sys.dm_exec_requests as r
join sys.dm_exec_sessions as s
on (s.session_id=r.session_id)
cross apply sys.dm_exec_sql_text( r.sql_handle ) as txt
where s.is_user_process=1
AND s.session_Id NOT IN (@@SPID)
order by datediff( ms, r.start_time, getDate()) DESC


--1. Candidate skill picker
--backup table
DECLARE @separator varchar(10) = ';'
;WITH CreateTableFromList AS (
SELECT 1 AS n,
       userID,
       CAST(LEFT(CAST(desiredLocations AS VARCHAR(MAX)),ISNULL(NULLIF(CHARINDEX(@separator,CAST(desiredLocations AS VARCHAR(MAX))),0),1001)-1) AS VARCHAR(1000)) AS Value,
       CAST(LTRIM(SUBSTRING(CAST(desiredLocations AS VARCHAR(MAX)),NULLIF(CHARINDEX(@separator,CAST(desiredLocations AS VARCHAR(MAX))),0)+1,100000)) AS VARCHAR(MAX)) AS RemainingValues
  FROM BH_4720_updqc.bullhorn1.pstmp_20150904_ucWorkTable x
 UNION ALL
SELECT n + 1,
       userID,
       CAST(LEFT(RemainingValues,ISNULL(NULLIF(CHARINDEX(@separator,RemainingValues),0),1001)-1) AS VARCHAR(1000)),
       CAST(LTRIM(SUBSTRING(RemainingValues,NULLIF(CHARINDEX(@separator,RemainingValues),0) + LEN(';'),100000)) AS VARCHAR(MAX))
  FROM CreateTableFromList
 WHERE LEN(RemainingValues) > 0
)
SELECT DISTINCT userID,value
INTO BH_4720_updqc.dbo.pstmp_CreateTableFromList
FROM CreateTableFromList
WHERE NULLIF(value) IS NOT NULL
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
