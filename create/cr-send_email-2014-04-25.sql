-- Function: public.send_email(text, text, text, integer, text, text, text)

-- DROP FUNCTION public.send_email(text, text, text, integer, text, text, text);

CREATE OR REPLACE FUNCTION public.send_email(IN _from text, IN _password text, IN smtp text, IN port integer, IN receiver text, IN subject text, IN send_message text, OUT rc integer, OUT out_rcpt_refused text)
  RETURNS record AS
$BODY$

import smtplib
from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.header import Header
from datetime import datetime
import pytz

sender = _from
receivers = receiver.split(",")

msg = MIMEMultipart()
### msg = MIMEMultipart("alternative")
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
    if port == -1:
        feml = open(smtp, "a")
        line = date + '<->' + sender + '<->' + receiver + '\n' + subject + '\n' + send_message + '\n'
        feml.write(line)
        feml.write('=============================================\n')
        feml.close()
    else:
        smtpObj = smtplib.SMTP(smtp,port)
        if smtp != 'mail.arc.world':
            smtpObj.starttls()
            smtpObj.login(_from, _password)
        rcpt_refused = smtpObj.sendmail(sender, receivers, msg.as_string())

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
  rc = 995
  out_rcpt_refused = str(rcpt_refused)
else:
  out_rcpt_refused = ""

#plpy.notice(str(rc)+" "+ out_rcpt_refused)

return rc, out_rcpt_refused
$BODY$
  LANGUAGE plpython2u VOLATILE
  COST 100;
ALTER FUNCTION public.send_email(text, text, text, integer, text, text, text)
  OWNER TO postgres;
