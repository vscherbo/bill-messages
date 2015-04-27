#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import smtplib
import sys
from StringIO import StringIO
from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.header import Header
from datetime import datetime
import pytz
import re

re_queued = re.compile('^reply: retcode .* queued as ([0-9A-F]{10,11})$')
smtp_srv="mail.arc.world"
port=25
_from='root@arc.world'
subject="Тест"
receiver="8 921, <vv@arc.world>"
#receiver="<vv@arc.world>, <it-events@arc.world>"
send_message="Просто тест"

sender = _from
receivers = receiver.split(",")

### msg = MIMEMultipart("alternative")
msg = MIMEMultipart()
msg.add_header('Content-Transfer-Encoding', '7bit')
msg.set_charset("utf-8")
msg["From"] = _from
#msg["Subject"] = subject 
#msg["To"] = receiver 
msg['Subject'] = Header(subject, 'utf-8')
msg["To"] = Header(receiver, 'utf-8') 
now = datetime.now(pytz.timezone('W-SU'))
day = now.strftime('%a')
date = now.strftime('%d %b %Y %X %z')
msg["Date"] =  day + ', ' + date

part1 = MIMEText(send_message, "plain", "utf-8")
msg.attach(part1)

rc = 0
rcpt_refused = []
try:
    smtpObj = smtplib.SMTP(smtp_srv,port)
    if smtp_srv != 'mail.arc.world':
        smtpObj.starttls()
        smtpObj.login(_from, _password)

    save_smtplib_stderr = smtplib.stderr
    result = StringIO()
    smtplib.stderr = result

    smtpObj.set_debuglevel(True)
    rcpt_refused = smtpObj.sendmail(sender, receivers, msg.as_string())
    smtpObj.set_debuglevel(False)
    
    smtplib.stderr = save_smtplib_stderr
    result_string = result.getvalue()
    result.close()
    #print result_string
    lines = result_string.splitlines()
    for line in lines:
        #print "line=",line
        qid = re_queued.match(line)
        if qid:
            #print "qid match"
            print qid.group(1)
    
except smtplib.SMTPServerDisconnected:
  rc = 11
except smtplib.SMTPResponseException:
  rc = smtplib.SMTPResponseException.smtp_code
except smtplib.SMTPConnectError:
  rc = 15
except smtplib.SMTPAuthenticationError:
  rc = 17
except smtplib.SMTPException:
  rc = 18
except smtplib.SMTPSenderRefused:
  rc = 12
except smtplib.SMTPRecipientsRefused:
  rc = 13
except smtplib.SMTPDataError:
  rc = 14
except smtplib.SMTPHeloError:
  rc = 16

  smtpObj.quit()

if len(rcpt_refused) > 0:
  rc = 19

sys.exit(rc)
