#!/bin/sh

. /usr/local/bin/bashlib

PSQL=/usr/bin/psql
DT=`date +%F_%H-%M-%S`

LOG_DIR=logs
[ -d $LOG_DIR ] || mkdir -p $LOG_DIR
LOG=$LOG_DIR/`namename $0`-$DT.log

exec 1>$LOG 2>&1

$PSQL -U arc_energo -d arc_energo -c "SELECT fn_check_ready4delivery();"
RC=$?
logmsg $RC "fn_check_ready4delivery completed"

