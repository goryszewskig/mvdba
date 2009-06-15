#!/usr/bin/env bash
#
# cron_sqlarea-top.sh
#     Cron wrapper
#
# Marcus Vinicius Ferreira           ferreira.mv[ at ]gmail.com
# Jun/2009
#

PATH=/opt/csw/bin:opt/csw/sbin
PATH=$PATH:/opt/local/bin:/opt/local/sbin
PATH=$PATH:/usr/local/bin:/usr/local/sbin
PATH=$PATH:/usr/bin:/usr/sbin:/bin:/sbin

[ "$1" != '-f' ] && {
    echo
    echo "Usage: $0 -f "
    echo
    echo "    Cron: sqlarea-top.sh"
    echo
    exit 2
}

### ORACLE_HOME + ORACLE_SID
source /u01/app/oracle/bin/env-ora.sh
if [ ! -d "$ORACLE_HOME" ]
then
    logmsg "ORACLE_HOME not set!!!"
    exit 1
fi

### App settings
  APPDIR=/u01/app/oracle/top10
  LOGDIR=/u01/app/oracle/log
SPOOLDIR=/u01/app/oracle/spool
    FILE=${0##*/}
 LOGFILE=${LOGDIR}/${FILE%.*}.log
#OUTFILE=${LOGDIR}/${FILE%.*}.out

### email
HOSTNAME=`hostname`
HOSTNAME=${HOSTNAME%%.*}

MAIL_FROM="noreply@${HOSTNAME}"
# MAIL_TO: sourced in env-ora.sh
[ "$MAIL_TO" ] || MAIL_TO="ferreira.mv@gmail.com"

logmsg() {
    echo "`date '+%Y-%m-%d %H:%M:%S'` : $1" >> $LOGFILE
}

mailmsg() {
    MSG=$1
    mail -s "${HOSTNAME}: $FILE" $MAIL_TO <<MAIL
From: $MAIL_FROM
To: $MAIL_TO
Subject: ${HOSTNAME}: $FILE


$MSG

`tail -30 $LOGFILE` 

Message generated by $0 at `date`

MAIL
}

### User settings
USER="top10"
PASS="top10"
  DB="$ORACLE_SID"

### Main
logmsg "Begin"

cd $SPOOLDIR
sqlplus -s $USER/$PASS <<SQL 2>&1>>${LOGFILE}

    WHENEVER SQLERROR EXIT ERROR
    WHENEVER OSERROR EXIT ERROR

    set termout off

    @ $APPDIR/sqlarea-top.sql

    exit

SQL

ERR="$?" 
if [ "$ERR" != "0" ] 
then
    mailmsg "Cron error: [$ERR]"
    logmsg  "Error: [$ERR]"
fi

logmsg "End"

### Cleanup
_clean() {
    kount=`find $1 -name "$2" -mtime $3 -exec rm {} \; -ls | wc -l`
    logmsg "Cleanup: removed [$kount] $2 files."
}

### Rotate
  cat $LOGFILE >> ${LOGDIR}/${FILE%.*}.`date +%Y-%m-%d`.log && \
     >$LOGFILE
# cat $OUTFILE >> ${LOGDIR}/${FILE%.*}.`date +%Y-%m-%d`.out && \
#    >$OUTFILE

### Remove
  _clean $SPOOLDIR '*.htm?' +30
  _clean $LOGDIR   '*.log'  +10
# _clean $LOGDIR   '*.out'  +10

exit 0


