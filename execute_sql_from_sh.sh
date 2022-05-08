/* 
execute_sql_from_sh.sh : example of execution of .sql script for Oracle database from a .sh script
UNIX Demo

Author Daniel G. Campos 2008

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
parameters :

1 date from 
2 date to

this script does the following:

1. Executes a .sql file, which generates files with reports
2. Sends the generated reports by mail
3. Erases temporary files
*/

# parameters
DATE_FROM=$1
DATE_TO=$2
CICLO=$3

#name of execution script 
NOMBRE_PROC=reports_post_billing

#Host del script
VHOST=$(hostname)

#exit code
EXIT_CODE=0

case $vHOST in
	ttlux04)
		DIR_LOG=/home/billing/scripts/EXECUTE/log
		DIR_SQL=/home/billing/scripts/EXECUTE/sql
		MSG_LOG=$DIR_LOG/reports_post_billing.log
		BASE=HPUXPROD1
		MAIL_SYS=" operator@hpuxprod1.com "
		break;;

	ttlux02)
		DIR_LOG=/home/billing/scripts/EXECUTE/1og
		DIR_SOL=/home/billing/scripts/EXECUTE/sql
		MSG_LOG=$DIR_LOG/reports_post_billing.log
		BASE=HPUXDEV1
		MAIL_SYS=" daniel.campos@testmail.com "
		break;;

	*)	
		DIR_LOG=/home/billing/scripts/EXECUTE/1og
		DIR_SOL=/home/billing/scripts/EXECUTE/sql
		MSG_LOG=$DIR_LOG/reports_post_billing.log
		BASE=HPUXDEV1
		MAIL_SYS=" daniel.campos@testmail.com "
		break;;
esac

# Oracle environment set
. Env $BASE > $MSG_LOG 2>$MSG_LOG

# save the parameters in the log file 
echo $DATE_FROM >> $MSG_LOG
echo $DATE_TO >> $MSG_LOG
echo $CICLO >> $MSG_LOG


# step 1. Execute the pl which generates the files with the reports

echo " " >> $MSG_LOG
echo "------------------------------------+------------+-------------------------- " >> $MSG_LOG

echo $(date +"%Y/%m/%d %H:%M:%S") " start with reports_post_billing.sql " >> $MSG_LOG

sqlplus -s /@${BASE} <<EOF 1>>$MSG_LOG 2>>$MSG_LOG

set serveroutput on size 1000000
WHENEVER SQLERROR EXIT 1

@${DIR_SQL}/reports_post_billing.sql ${DATE_FROM} ${DATE_TO} ${CICLO} >> $MSG_LOG

EOF

if [ $? -eq 0 ]
	then 
		echo "OK execution of reports_post_billing.sql" >> $MSG_LOG
	else
		EXIT_CODE=1
		echo "ERROR with reports_post_billing.sql " >> $MSG_LOG
fi


echo $(date +"%y/%m/%d %H:%M:%S") " fin reports_post_billing.sql" >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG
echo " " >> $MSG_LOG

# check connection error 
echo " " >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG
echo $(date +"%Y/%m/%d %H:%M:%S") " check start  " >> $MSG_LOG

if [ $(awk '/ERROR|Unable to CONNECT to ORACLE|ORA-/{print $0}' $MSG_LOG | wc -1) -ne O ]
	then
		EXIT_CODE=2
fi

echo $(date +"%Y /%mn/%d %H:%M:%S") " check end " $EXIT_CODE >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG
echo " " >> $MSG_LOG

# step 2 once the reports has been generate, send the respective mails

cp /datafiles/utldir/mails_to /datafiles/utldir/mails_to_x
chmod 755 /datafiles/utldir/mails_to_x

echo " executing sendmailsfrom.sh "
/datafiles/utldir/mails_to_x

# step 3. Delete the temporary files
echo " deleting temporary files "

rm -f /datafiles/utldir/mails_to_*

# end step 5

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
fi

echo $(date +"%yY/%m/%d %H:%M:%S")" END PROCESS  " ${RESULT} >> $MSG_LOG
echo "--------------------------------------------------------- " >> $MSG_LOG

echo " " >> $MSG_LOG

echo ">>>>>>>>>>" >> $MSG_LOG

cat $MSG_LOG | mailx -s "$vHOST: $NOMBRE_PROC END $RESULT" $MAIL_SYS


# end final step 
exit $EXIT_CODE
