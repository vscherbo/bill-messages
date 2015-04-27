#!/bin/sh

. /usr/local/bin/bashlib

PSQL=/usr/bin/psql
TRY_COUNTER=/tmp/sendbillmsg.counter
DT=`date +%F_%H-%M-%S`
TODAY=`date +%F`

LOG_DIR=logs
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
LOG=$LOG_DIR/`namename $0`.log
DTLOG=$LOG_DIR/`namename $0`-$DT.log

CSV_DIR=no-reply-csv
[ -d $CSV_DIR ] || mkdir -p $CSV_DIR
CSV_OUTPUT=$CSV_DIR/no-reply-sent-$DT.csv
CSV_MASK=no-reply-sent-$TODAY*

exec 1>$DTLOG 2>&1
#set -vx
[ -f $TRY_COUNTER ] || echo 0 > $TRY_COUNTER

ps aux |grep -v grep |grep -q "SELECT fn_sendbillmsg"
RUNNING=$?
case $RUNNING in
  0) ERR_STR="There is running process. Skip."
     TRY_COUNT=`cat $TRY_COUNTER`
     if [ $TRY_COUNT -gt 3 ] 
     then
        echo $ERR_STR" The number of attempts has exceeded the limit." |mail -s "WARNING. SKIP fn_sendbillmsg" it-events@arc.world
     else
        set +vx
        logmsg WARNING "$ERR_STR"
        set -vx
        let TRY_COUNT+=1
        echo $TRY_COUNT > $TRY_COUNTER
     fi
     ;;
  1) echo 0 > $TRY_COUNTER
     $PSQL -U arc_energo -d arc_energo -c "SELECT fn_sendbillmsg();"
     RC=$?
     set +vx
     logmsg $RC "fn_sendbillmsg completed"
     set -vx

     for csv in `ls -1tr $CSV_DIR/$CSV_MASK`
     do
       l=$csv
     done
     if [ "+$l" != "+" ]
     then
        LAST_CSV=`tail -1 $l | awk -F"," '{split($5,arr," "); print ".*"$2".*"arr[1]}'`
        ### LAST_CSV=`tail -1 $l | awk -F"," '{print ".*"$2".*"$5}'`
        ### LAST_CSV=`tail -1 $l | awk -F"," '{printf ".*%s.*%s\n", $2, gensub(/([()\[\].<>])/, "\\\\""\\1", "g", $5) }'`
###        LAST_CSV=`tail -1 $l | awk -F"," '{printf ".*%s.*%s\n", $2, gensub(/([\(\)\[\]\.<>]+)/, "\\""\\\\1", "g", $5) }'`
        LAST_CSV="'"$LAST_CSV"'"
     fi
     set +vx
     logmsg INFO "LAST_CSV=$LAST_CSV"
     set -vx

     # check after delay sent status in maillog on kipspb.ru
     { sleep 30m; ssh -i $HOME/.ssh/id_dsa pgmaillog@kipspb.ru "/usr/local/bin/python2 /root/bin/no-reply-sent.py $LAST_CSV" > $CSV_OUTPUT;  psql -U arc_energo -d arc_energo -c "\COPY send_email_result (delivered,qid,email_to,send_timestamp,smtp_msg) FROM '"$CSV_OUTPUT"' WITH (FORMAT csv, HEADER false);" ; psql -U arc_energo -d arc_energo -c "UPDATE СчетОчередьСообщений SET msg_status = 999, msg_problem = NULL FROM send_email_result r WHERE msg_status <> 999 AND msg_qid = r.qid AND r.delivered = True ;" ; psql -U arc_energo -d arc_energo -c "UPDATE СчетОчередьСообщений SET msg_problem = r.smtp_msg FROM send_email_result r WHERE msg_status < 500 AND msg_qid = r.qid AND r.delivered = False;" ; cat $DTLOG >> $LOG; } &
     ;;
esac




