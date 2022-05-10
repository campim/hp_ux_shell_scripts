/*
execute_sql_from_sh_2.sh : example of execution of .sql script for Oracle database from a .sh script
UNIX Demo

Author Daniel G. Campos 2007

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

/* 
parameters : none

this script does the following :

1. executes an .sql script for an Oracle database if conditions are true, no parameters are sent to the .sql script
This script updates some tables on the database and then commits the changes.

*/

. /etc/profile > /dev/null 2> /dev/null
. $HOME/.profile > /dev/null 2> /dev/null

export DATE=$(date +"%Y%m%d%H%M%S")

# name of execution script
NOMBRE_PROC=example_procedure

vHOST=$(hostname)

case $VHOST 1in
	ttTux04)
		DIR_FCO=/home/billing/scripts/EXECUTE/FCO
		DIR_OUT=/datafiles/utldir
		BASE=HPUXPROD1
		MAIL_SYS=" operator@hpuxprod1.com "
		break;;

	ttlux02)
		DIR_FCO=/home/billing/scripts/EXECUTE/FCO
		DIR_OUT=/datafiles/utldir
		BASE=HPUXDEV1
		MAIL_SYS=" daniel.campos@testmail.com "
		break;;
	*)
		DIR_FCO=/home/billing/scripts/EXECUTE/FCO
		DIR_OUT=/datafiles/utldir
		BASE=HPUXDEV1
		MAIL_SYS=" daniel.campos@testmail.com "
		break;;
esac

# dirs settings
DIR_SQL=${DIR_FCO}/sql
DIR_LOG=${DIR_OUT}/logs
MSG_LOG=${DIR_LOG}/$NOMBRE_PROC.$DATE.log
EXIT_CODE=0

# Oracle environment settings 
. Env $BASE >> $MSG_LOG 2 >> $MSG_LOG


# step 1, run first sql 
echo " " >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG
echo $(date +"%Y/%m/%d %H:%M:%S") " start example_sql_with_procedure_call.sql"” >>$MSG_LOG

sqlplus /@${BASE} <<EOF >> $MSG_LOG 2>> $MSG_LOG
set serveroutput on size 1000000
WHENEVER SQLERROR EXIT 1
start $DIR_SQL/example_sql_with_procedure_call.sql
EOF

if [ $? -eq 0 ]
	then
		echo "Ejecuto OK example_sql_with_procedure_call.sql" >> $MSG_LOG
	else
		echo $?
		EXIT_CODE=1
		echo "ERROR IN example_sql_with_procedure_call " >> $MSG_LOG
fi

echo $(date +"VY//m//d BH:%M:%S") " End example_sql_with_procedure_call.sql" >> $MSG_LOG
echo " " >> $MSG_LOG

# end step 1


# step 2, update table with an .sql script 
echo " " >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG

echo $(date +"%Y/%m/%d %H:%M:%S") " start with example_updates_with_sql_script.sql" >> $MSG_LOG


sqlplus /@${BASE} <<EOF >> $MSG_LOG 2>> $MSG_LOG
set serveroutput on size 1000000
WHENEVER SQLERROR EXIT 1
start $DIR_SQL/example_updates_with_sql_script.sql
EOF

if [ $? -eq 0 ]
	then
		echo "Execution OK example_updates_with_sql_script.sql" >> $MSG_LOG
	else
		echo $?
		EXIT_CODE=1
		echo "ERROR IN example_updates_with_sql_script.sql" >> $MSG_LOG
fi

echo $(date +"%y/%m/%d %H:%M:%s") " fin example_updates_with_sql_script.sql" >>$MSG_LOG

echo "--------------------------------------------------------- " >> $MSG_LOG


# check connection error
echo " " >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG
echo $(date +"%Y/%m/%d %H:%M:%S") " start error check" >> $MSG_LOG

if [ $(awk '/ERROR|unable to CONNECT to ORACLE|ORA-/{print $0}' $MSG_LOG | wc -l) -ne 0 ]
	then
		EXIT_CODE=2
if

echo $(date +"%Y/%m/%d %H:%M:%S") " end error check  " $EXIT_CODE >> $MSG_LOG 
		

# final step 

echo " " >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG

if [ $EXIT_CODE -eq 0 ]
	then
		echo " END OK " $? >> $MSG_LOG
		RESULT=OK
	else
		echo " END WITH ERROR " $? >> $MSG_LOG
		RESULT=ERROR
		echo " EXIT_CODE " $EXIT_CODE >> $MSG_LOG
if

echo $(date +"%Y/%m/%d %H:%M:%S")" END PROCESS " ${RESULT} >> $MSG_LOG
echo ">>>>>>>>\n" >> $MSG_LOG

echo "--------------------------------------------------------- " >> $MSG_LOG
echo " " >> $MSG_LOG

cat $MSG_LOG | mailx -s "$vHOST: $NOMBRE_PROC END $RESULT" $MAIL_SYS

# end final step

exit $EXIT_CODE

