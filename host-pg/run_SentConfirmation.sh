#!/bin/sh

. /usr/local/bin/bashlib

PSQL=/usr/bin/psql
DT=`date +%F_%H-%M-%S`
TODAY=`date +%F`

LOG_DIR=$HOME/logs
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
LOG=$LOG_DIR/`namename $0`.log
DTLOG=$LOG_DIR/`namename $0`-$DT.log
DTLOG_MASK=`namename $0`-*.log

CSV_DIR=no-reply-csv
[ -d $CSV_DIR ] || mkdir -p $CSV_DIR
CSV_OUTPUT=$CSV_DIR/no-reply-sent-$DT.csv
CSV_MASK=no-reply-sent-$TODAY*

exec 1>$DTLOG 2>&1

set -vx
for csv in `ls -1tr $CSV_DIR/$CSV_MASK`
do
   [ -s $csv ] && l=$csv
done

if [ "+$l" != "+" ]
then
	LAST_CSV=`tail -1 $l | awk -F"," '{split($5,arr," "); print ".*"$2".*"arr[1]}'`
	LAST_CSV="'"$LAST_CSV"'"
fi # if exist and greater than zero

set +vx
logmsg INFO "LAST_CSV=$LAST_CSV"
set -vx

ssh -i $HOME/.ssh/id_dsa pgmaillog@smtp.kipspb.ru "/usr/local/bin/python2 /root/bin/no-reply-sent.py $LAST_CSV" > $CSV_OUTPUT

$PSQL -U arc_energo -d arc_energo -c "\COPY send_email_result (delivered,qid,email_to,send_timestamp,smtp_msg) FROM '"$CSV_OUTPUT"' WITH (FORMAT csv, HEADER false);" 

$PSQL -U arc_energo -d arc_energo -c "UPDATE СчетОчередьСообщений SET msg_status = 999, msg_problem = NULL FROM send_email_result r WHERE msg_status <> 999 AND msg_qid = r.qid AND r.delivered = True ;" 

$PSQL -U arc_energo -d arc_energo -c "UPDATE СчетОчередьСообщений SET msg_status = 995, msg_problem = r.smtp_msg FROM send_email_result r WHERE msg_status < 900 AND msg_qid = r.qid AND r.delivered = False;" 



cat $DTLOG >> $LOG 

find $LOG_DIR -type f -name "${DTLOG_MASK}" -mtime +7 |xargs rm -f 
find $CSV_DIR -type f -name "no-reply-sent*.csv" -mtime +7 |xargs rm -f


