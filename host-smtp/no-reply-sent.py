#!/usr/bin/env python2

# origin:
# https://github.com/strycore/scripts/blob/master/postfix-logparser.py

#import os
from sys import stdout,argv
import datetime
import re
import logging
import stat
import locale
import itertools
import collections

re_postfix = re.compile('^postfix')
re_wrong_domain = re.compile('^.*@mail\.kipspb\.ru')
re_qid = re.compile('[A-Z0-9]{10}')

locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
#loc = locale.getlocale()

#maillog = open('/root/no-reply-2014-04-24.log', 'r').readlines()
#maillog = open('/root/noreply2addr.log-full', 'r').readlines()
maillog = open('/var/log/maillog', 'r').readlines()
#maillog = open('/root/maillog-test', 'r').readlines()

if 1 == len(argv):
    maillog_tail = maillog
else:
    p = re.compile(argv[1])
    maillog_tail = itertools.dropwhile(lambda x: not p.match(x) , maillog)

mailinfo = {}
#for line in maillog:
for line in maillog_tail:
    line_parsed = False
    line = line[:-1] #remove \n character

    #Separate the date and hostname from the rest
    while line.find('  ') != -1:
        line = line.replace('  ', ' ')
    elems = line.split(' ',4)
    year = datetime.datetime.now().year
    event_date_str = ("%i %s %s %s" % (year, elems[0], elems[1], elems[2]))
    ### print "event_date_str=", event_date_str 
    event_date = str(datetime.datetime.strptime(event_date_str, "%Y %b %d %H:%M:%S"))

    hostname = elems[3]
    postfix_details = elems[4]

    #if not re.match('^postfix', postfix_details):
    if not re_postfix.match(postfix_details):
       #ignore non-postfix
       continue

    #print "postfix_details=", postfix_details
    #ignore mail.kipspb.ru
    # if re_wrong_domain.match(postfix_details):
       # print "WRONG DOMAIN"
       # continue

    postfix_event = postfix_details.split(':', 2)
    if len(postfix_event) != 3:
        #these events are not logged to database (connection information, etc..)
        pass
    else:
        command = postfix_event[0]
        queue_id = postfix_event[1].strip()
        details = postfix_event[2]

        # We need local mail
        # if command.startswith('postfix/local'):
        #     continue

        if details.startswith(' removed') and command.startswith('postfix/postsuper'):
            continue
        if details.startswith(' removed') and command.startswith('postfix/qmgr'):
            continue

        if details.startswith(' host ') and command.startswith('postfix/smtp'):
            continue

        if queue_id.startswith('warning') or queue_id.startswith('NOQUEUE'):
            continue

#        print "DETAILS=", details

        #if not re.match('[A-Z0-9]{10}', queue_id):
        if not re_qid.match(queue_id):
            #ignore events with an invalid queue_id
            #print "invalid queue id : " + queue_id
            continue

        # Create new key based on queue-id if it doesn't exists
        if not queue_id in mailinfo:
            mailinfo[queue_id] = {}
            mailinfo[queue_id]['timestamp'] = event_date

#        print "Command:", command
        if details.startswith(' message-id'):
            message_id = details[13:-1]
            mailinfo[queue_id]['message_id'] = message_id
            line_parsed = True
        if details.startswith(' from=') and command.startswith('postfix/qmgr'):
            (email_from, size, nrcpt) = details.split(',',3)
            mailinfo[queue_id]['from'] = email_from[6:]
            mailinfo[queue_id]['size'] = size[6:]
            mailinfo[queue_id]['nrcpt'] = nrcpt[7:]
            l_nrcpt = mailinfo[queue_id]['nrcpt'].split()
            Nnrcpt = l_nrcpt[0]
#            print "FROM:",mailinfo[queue_id], "Nrcpt=", Nnrcpt
            line_parsed = True
        if details.startswith(' to=') and command.startswith('postfix/'):
            to_email = details.split(', ',1)
            addr_to = to_email[0][4:]
#            print "addr_to=", addr_to
            #if 'nrcpt' in mailinfo[queue_id].keys():
            #    print mailinfo[queue_id]['nrcpt']
            #    l_nrcpt = mailinfo[queue_id]['nrcpt'].split()
            #    nrcpt = l_nrcpt[0]
            #    if nrcpt > 1:
            #        if not addr_to in mailinfo[queue_id]:
            #            mailinfo[queue_id]['to'] = addr_to
            line_parsed = True

        #Ignore useless postfix commands
        if details.startswith(' removed') and command.startswith('postfix/postsuper'):
            pass #Ignore this line
            line_parsed = True
        if details.startswith(' removed') and command.startswith('postfix/qmgr'):
            pass #Ignore this line
            line_parsed = True
        if details.startswith(' uid') and command.startswith('postfix/pickup'):
            pass #Ignore this line
            line_parsed = True
        #if details.startswith(' uid') and command.startswith('postfix/cleanup'):
        if command.startswith('postfix/cleanup'):
            pass #Ignore this line
            line_parsed = True

        if command.startswith('postfix/smtp') or command.startswith('postfix/local'):
            elems = details.split(', ')
            if len(elems) > 1:
               for elem in elems:
                   index = elem.find('=')
                   key = elem[0:index].strip()
                   val = elem[index+1:].strip()
                   #print "key=",key, "val=", val
                   if 'nrcpt' in mailinfo[queue_id].keys():
                       if key in mailinfo[queue_id].keys():
                           mailinfo[queue_id][key][addr_to] = val
                           #print "mailinfo append=", mailinfo[queue_id][key]
                       else:
                           #mailinfo[queue_id][key] = [addr_to, val]
                           mailinfo[queue_id][key] = {}
                           mailinfo[queue_id][key][addr_to] = val
                           #mailinfo[queue_id][key].append([addr_to, val])
                           #print "mailinfo assign=", mailinfo[queue_id][key]
            line_parsed = True
        if command.startswith("postfix/bounce"):
            mailinfo[queue_id]['bounce_message'] = details.strip()
            line_parsed = True

        #rename reserved mysql keywords
        #if 'status' in  mailinfo[queue_id]:
        #    mailinfo[queue_id]['status_'] = mailinfo[queue_id]['status']
        #    del mailinfo[queue_id]['status']
        #if 'from' in  mailinfo[queue_id]:
        #    mailinfo[queue_id]['from_'] = mailinfo[queue_id]['from']
        #    del mailinfo[queue_id]['from']
        #if 'to' in  mailinfo[queue_id]:
        #    mailinfo[queue_id]['to_'] = mailinfo[queue_id]['to']
        #    del mailinfo[queue_id]['to']

        #print unparsed lines
        if not line_parsed:
            stdout.write("UNPARSED")
            print postfix_event
        #else:
        #    print 'Parsed::', postfix_event

re_st_sent = re.compile('^sent')
re_from_noreply = re.compile('^<no-reply@kipspb')
re_virtuser = re.compile('^<virtuser_\d+@mail\.kipspb\.ru>')
sent_cnt = 0

#print "Size:", len(mailinfo)
dt = datetime.datetime.now()


#for key, val in mailinfo.items():
#    print "key=",key, "val=", val
#print "=============================================="

str_items = {}

for key, val in mailinfo.items():
    if 'status' in val:
        #print "val_nrcpt=", val['nrcpt']
        #print "key=",key, "val=", val
        from_yes = re_from_noreply.match(val['from'])
        #print "val[status]=",val['status']
        #print "val[from]=",val['from']
        #print "val[to]=",val['to']
        if from_yes:
            for to, status_to in val['status'].items():
                #print "to=", to, " status=", status_to
                dt_sent = dt.strptime(val['timestamp'], '%Y-%m-%d %X') + datetime.timedelta(seconds=int(float(val['delay'][to])) )
                #print "dt-timestamp=", dt.strptime(val['timestamp'], '%Y-%m-%d %X')
                #, " delay=", datetime.timedelta(seconds=int(float(val['delay'][to])) ), " dt_sent=", dt_sent
                sent_yes = re_st_sent.match(status_to)
                if sent_yes:
                    sent_cnt = sent_cnt+1
                    sent_result = "t"
                else: 
                    sent_result = "f"

                loc_mail = re_virtuser.match(val['to'][to])
                res_str = ''
                if loc_mail:
                    key_str = str(dt_sent) +" "+ key +" "+ val['orig_to'][to]
                    res_str = sent_result +","+ key +","+ val['orig_to'][to] +","+ str(dt_sent) +","+ status_to
                    #print res_str
                else:
                    key_str = str(dt_sent) +" "+ key +" "+ val['to'][to]
                    res_str = sent_result +","+ key +","+ val['to'][to] +","+ str(dt_sent) +","+ status_to
                    #print res_str
                str_items[key_str] = res_str

#print '##############################'
sorted_items = collections.OrderedDict()
sorted_items = collections.OrderedDict(sorted(str_items.items(), key=lambda t: t[0]))

for k,val in sorted_items.items():
    #print "k=",k, "/val=", str(val)
    print val

#print "Successfully sent: ", sent_cnt   
