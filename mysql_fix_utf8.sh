#!/bin/bash
database=DATABASE
password=PASSWORD
user=root
sqlBackup=~/backup.sql

echo Copying database
# this makes a copy of the current database, or comment out the next line if you want to start with an existing backup.
mysqldump -p$password -u $user --opt -R --single-transaction --result-file="$sqlBackup" $database
cp $sqlBackup  ~/fix_utf8.sql

echo  Clearing old data
echo "drop database if exists $database; create database $database character set utf8 COLLATE utf8_general_ci;" | mysql -u $user -p$password

echo Correcting sql file to specify utf8, not latin1
perl -i -pe 's/DEFAULT CHARSET=latin1/DEFAULT CHARSET=utf8/' ~/fix_utf8.sql

echo Importing data
mysql -u $user -p$password --database $database < ~/fix_utf8.sql
rm ~/fix_utf8.sql

echo Importing fix_utf8
mysql -u $user -p$password --database $database < procedure_fix_utf8.sql

echo Running fix_utf8
echo "set names utf8; call fix_utf8('$database');" | mysql -u $user -p$password --database=$database



