#!/bin/sh

. /usr/local/bin/bashlib

PSQL=/usr/bin/psql
TRY_COUNTER=/tmp/sendbillmsg.counter
DT=`date +%F_%H-%M-%S`
TODAY=`date +%F`

LOG_DIR=$HOME/logs
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
LOG=$LOG_DIR/`namename $0`.log
DTLOG=$LOG_DIR/`namename $0`-$DT.log
DTLOG_MASK=`namename $0`-*.log

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
     ;;
esac

find $LOG_DIR -type f -name "${DTLOG_MASK}" -mtime +7 |xargs rm -f 
