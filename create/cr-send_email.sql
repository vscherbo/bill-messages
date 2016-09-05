-- DROP FUNCTION public.send_email(text, text, text, text, integer, text, text, text);

CREATE OR REPLACE FUNCTION public.send_email(IN _from text, IN _password text, IN replyto text, IN smtp text, IN port integer, IN receiver text, IN subject text, IN send_message text, OUT rc integer, OUT out_msg_qid text, OUT out_rcpt_refused text) AS
$BODY$

import smtplib
import plpy
import sys
from StringIO import StringIO
from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.header import Header
from datetime import datetime
import pytz
import re

re_queued = re.compile('^reply: retcode .* queued as ([0-9A-F]{10,11})$')

sender = _from
receivers = receiver.split(",")

### 
msg = MIMEMultipart("alternative")
###msg = MIMEMultipart()
msg.add_header('Content-Transfer-Encoding', '8bit')
msg.add_header('Reply-To', replyto)
msg.add_header('Errors-To', 'it@kipspb.ru')
msg.set_charset("UTF-8")

now = datetime.now(pytz.timezone('W-SU'))
day = now.strftime('%a')
date = now.strftime('%d %b %Y %X %z')
msg["Date"] =  day + ', ' + date

msg["From"] = _from
# msg["To"] = Header(receiver, 'UTF-8') 
msg["To"] = receiver 
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
out_rcpt_refused = ''
rcpt_refused = []
if port == -1:
    feml = open(smtp, "a")
    line = date + '<->' + sender + '<->' + receiver + '\n' + subject + '\n' + send_message + '\n'
    feml.write(line)
    feml.write('=============================================\n')
    feml.close()
else:
    try:
        smtpObj = smtplib.SMTP(smtp,port)
        if smtp != 'mail.arc.world':
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
        #plpy.notice(result_string)
        lines = result_string.splitlines()
        for line in lines:
            qid = re_queued.match(line)
            if qid:
                out_msg_qid = qid.group(1)

    except smtplib.SMTPServerDisconnected:
      rc = 11
    except smtplib.SMTPResponseException, e:
      rc = e.smtp_code
    except smtplib.SMTPConnectError:
      rc = 15
    except smtplib.SMTPAuthenticationError:
      rc = 17
    except smtplib.SMTPSenderRefused:
      rc = 12
    except smtplib.SMTPRecipientsRefused:
      rc = 13
    except smtplib.SMTPDataError:
      rc = 14
    except smtplib.SMTPHeloError:
      rc = 16
    #except smtplib.SMTPException:
    #  rc = 18
    finally:
      smtpObj.quit()

if len(rcpt_refused) > 0:
  rc = 995
  out_rcpt_refused = str(rcpt_refused)
# else:
#  out_rcpt_refused = ""

#plpy.notice(str(rc)+" "+ out_rcpt_refused)

return rc, out_msg_qid, out_rcpt_refused
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
