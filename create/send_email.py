#!/usr/bin/env python
# -*- encoding: UTF-8 -*-

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
#receiver="8 921, <vv@arc.world>"
#receiver="<vv@arc.world>, <it-events@arc.world>"
receiver="<vv@arc.world>"
send_message="Изменение статуса счёта № 55181155\nЭто письмо сформировано автоматически, отвечать на него не нужно.\n\nЗаказ 55181155 отправлен: Автотрейдинг, № документа:спбп-04699 от 2014-04-24\nОтследить состояние доставки Вы можете по <a href=\"http://kipspb.ru/exp_mod/ae5000_invoicenumber.php?date=01.04.2014&number=%D1%81%D0%BF%D0%B1%D0%BF-00019\">ссылке</a>\n\nНа все Ваши вопросы Вам ответит Ваш персональный менеджер:\nАлексеева Александра, e-mail: alekseeva@kipspb.ru,\nтелефон:  (812)327-327-4\nС уважением,\nООО «КИП СПБ»"

sender = _from
receivers = receiver.split(",")

###
msg = MIMEMultipart("alternative")
###msg = MIMEMultipart()
msg.add_header('Content-Transfer-Encoding', '8bit')
msg.set_charset("UTF-8")

now = datetime.now(pytz.timezone('W-SU'))
day = now.strftime('%a')
date = now.strftime('%d %b %Y %X %z')
msg["Date"] =  day + ', ' + date

msg["From"] = _from
msg["To"] = Header(receiver, 'UTF-8') 
msg['Subject'] = Header(subject, 'UTF-8')
#msg["Subject"] = subject 
#msg["To"] = receiver 

html_prefix = """\
<html>
  <head>
    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type">
  </head>
  <body>
"""
#    <p>Hi!<br>
#       How are you?<br>
#       Here is the <a href="http://www.python.org">link</a> you wanted.
#    </p>

html_suffix = """
  </body>
</html>
"""
space5 = "     "
msg_html = ""
msg_lines = send_message.splitlines()
for mline in msg_lines:
    msg_html = msg_html + space5 + mline + "<br>\n"

msg_html = html_prefix + msg_html + html_suffix

part1 = MIMEText(send_message, "plain", "UTF-8")
part2 = MIMEText(msg_html, 'html', "UTF-8")
msg.attach(part1)
msg.attach(part2)

rc = 0
out_msg_qid = ''
rcpt_refused = []
try:
    #if port == -1:
    #feml = open('/tmp/send-email.log', "a")
    #line = date + '<->' + sender + '<->' + receiver + '\n' + subject + '\n' + send_message + '\n'
    #feml.write(line)
    #feml.write('=============================================\n')
    #feml.close()
    #else:
    smtpObj = smtplib.SMTP(smtp_srv,port)
    if smtp_srv != 'mail.arc.world':
        smtpObj.starttls()
        smtpObj.login(_from, _password)

    save_smtplib_stderr = smtplib.stderr
    result = StringIO()
    smtplib.stderr = result
#
    fbin = open('/tmp/send-bin.log', "w")  #############  "a")
    fbin.write(msg.as_string())
    fbin.write('=============================================\n')
    fbin.close()
#
    smtpObj.set_debuglevel(True)
###################################    
    rcpt_refused = smtpObj.sendmail(sender, receivers, msg.as_string())
    smtpObj.set_debuglevel(False)

    smtplib.stderr = save_smtplib_stderr
    result_string = result.getvalue()
    result.close()
    #plpy.notice(result_string)
    lines = result_string.splitlines()
    for line in lines:
        qid = re_queued.match(line)
        if qid:
           out_msg_qid = qid.group(1)

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
