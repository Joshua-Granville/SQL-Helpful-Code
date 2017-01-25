import os
import os.path
import sys
import pypyodbc
import time
import glob
import datetime


		
def table_check(connection):
	c = connection.cursor()
	#SQLQuery = ("SELECT ISNULL(SELECT top 1 'Y' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pstmp_fileList_import','N')")
	SQLQuery = ("DECLARE @col VARCHAR(1) SET @col = (SELECT top 1 'Y' colCheck FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'pstmp_fileList_import') IF @col IS NULL SET @col = 'N' SELECT @col")
	c.execute(SQLQuery)
	
	tablecheckval = c.fetchone()
	
	connection.commit()
	#print tablecheckval
	return tablecheckval

def table_creator(connection,tableexists):
	if tableexists[0] == "Y":
		cursor = connection.cursor() 
		SQLCommand = ("truncate table pstmp_fileList_import")
		cursor.execute(SQLCommand)
		connection.commit()
		print "Table exists, truncating table...."
	else:
		cursor = connection.cursor() 
		SQLCommand = ("create table pstmp_fileList_import(PATH varchar(500), FILENAME varchar(500), EXTENSION varchar(500), FILEDATE varchar(50))")
		cursor.execute(SQLCommand)
		connection.commit()
		print "Table created"
	return;
	

def load_table(connection,dirIn):
	print "Loading table!"
	cur = connection.cursor() 
	insertStatement = ("INSERT INTO pstmp_fileList_import (PATH,FILENAME,EXTENSION,FILEDATE) VALUES (?,?,?,?)")
	for folderName, subfolders, filenames in os.walk(dirIn):
		#counter = 1
		for filename in filenames:
			statinfo = os.stat(folderName + '\\'+ filename)
			timestamp = statinfo.st_mtime
			date = datetime.datetime.fromtimestamp(timestamp)
			extension = os.path.splitext(filename)[1]
			filedate = date.strftime('%Y%m%d%H%M%S')
			#print(folderName + '\\'+ filename + '|' + folderName + '|' + filename + '|' + extension)
			cur.execute(insertStatement,(folderName,filename,extension,filedate))
			connection.commit()
			
def welcome_page(serverIn,databaseIn,dirIn):
	print "/--------------------------------------------------------------------/"
	print "|    Directory Listing table load                                    |"
	print "|  This job will take the folder you pass it and loop through all sub|"
	print "|  folders inserting them into your database.                        |"
	print "|____________________________________________________________________|"
	print ""
	print "Passed values:"
	print "Server name -> %s" % serverIn
	print "Database name -> %s" % databaseIn
	print "Directory -> %s" % dirIn
	print ""
	print "Processing..."
	print ""

def main():	
	serverIn = "migratedb1\\ps_lg15"
	databaseIn = "Quaero_Mig_Template_Final"
	dirIn = '\\\\migratedb1\\d$\\ClientData\\Josh\\Quaero\\ResumesProvided\\'
	conString = "Driver={SQL Server};Server=%s;Database=%s;Trusted_Connection=yes;" % (serverIn,databaseIn)
	connection = pypyodbc.connect(conString)

	welcome_page(serverIn,databaseIn,dirIn)
	#tableexists = 'N'
	
	tableexists = table_check(connection)
	#print tableexists
	table_creator(connection,tableexists)
	load_table(connection,dirIn)
	connection.close()
	
	print ""
	print "How to convert loaded filedate field to datetime in SQLServer"
	print "SQL:"
	print "SELECT a.*,convert(datetime, stuff(stuff(stuff(fileDate, 9, 0, ' '), 12, 0, ':'), 15, 0, ':')) FROM pstmp_fileList_import a"
	
main()