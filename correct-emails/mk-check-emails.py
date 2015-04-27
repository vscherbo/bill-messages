#!/usr/bin/env python2

#import os
from sys import stdout
import datetime
import re
import logging
import stat

re_upd_1 = re.compile('^UPDATE (.*) SET (?:(.*) = ((.*)| (\w+\(.*\)))(?:(\s*,|\s*)) )+? WHERE (.*);$')
re_upd_m = re.compile('[A-Z0-9]{10}')


upd_file = open('correct-emails.sql-0', 'r').readlines()
mailinfo = {}
for line in upd_file:
    upd1 = re_upd_1.match(line)
    if upd1:
       print line
       print upd1.group(1)
       print upd1.group(2)
       print upd1.group(3)
       print upd1.group(4)
       print '###########################################'
