#!/bin/sh

#HTML_HEADER='<html><head><meta http-equiv="content-type" content="text/html; charset=utf-8" /></head><body>'
#HTML_FOOTER='</body></html>'

echo $HTML_HEADER
psql -h vm-pg -U arc_energo -d arc_energo -A -F ',' -f bills-2014.sql
echo $HTML_FOOTER

