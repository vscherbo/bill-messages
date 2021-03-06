-- Function: public.send_attachment(text, text, text, text, integer, text, text, text, text, text[])

-- DROP FUNCTION public.send_attachment(text, text, text, text, integer, text, text, text, text, text[]);

-- CREATE OR REPLACE FUNCTION public.send_attachment_ssl(
CREATE OR REPLACE FUNCTION public.send_attachment(
    IN _from text,
    IN _password text,
    IN replyto text,
    IN smtp text,
    IN port integer,
    IN receiver text,
    IN bcc text,
    IN subject text,
    IN send_message text,
    IN attachment_files text[] DEFAULT NULL::text[],
    OUT rc integer,
    OUT out_msg_qid text,
    OUT out_rcpt_refused text)
  RETURNS record AS
$BODY$

import smtplib
import plpy
import sys
from StringIO import StringIO
from email.MIMEText import MIMEText
from email.MIMEMultipart import MIMEMultipart
from email.header import Header
from email.mime.application import MIMEApplication
import email.utils
from datetime import datetime
import pytz
import re
import os

re_queued = re.compile('^reply: retcode .* queued .*as ([-0-9a-zA-Z]+)')
re_timestamp = re.compile('[0-9]{10}-(.*)')


sender = _from
receivers = receiver.split(",")
if bcc is not None and bcc != '':
    receivers += bcc.split(",")

msg = MIMEMultipart("alternative")

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
    msg_html += space5 + mline + "<br>\n"

msg_html = html_prefix + msg_html + html_suffix

part1 = MIMEText(send_message, "plain", "UTF-8")
msg.attach(part1)

part2 = MIMEText(msg_html, 'html', "UTF-8")
msg.attach(part2)

# PDF attachment
if attachment_files is not None:
    msg_body = msg
    msg = MIMEMultipart("mixed")
    msg.attach(msg_body)
    for fname in attachment_files:
        if not os.path.exists(fname):
            plpy.notice("File '%s' does not exist.  Not attaching to email." % fname)
            continue
        if not os.path.isfile(fname):
            plpy.notice("Attachment '%s' is not a file.  Not attaching to email." % fname)
            continue
        plpy.notice("attachment_file="+ fname)
        fpdf = open(fname, 'rb')
        att_pdf = MIMEApplication(fpdf.read(),_subtype="pdf")
        fpdf.close()
        att_pdf.add_header('Content-Disposition','attachment',filename=os.path.basename(fname))
        msg.attach(att_pdf)
        plpy.notice("attached")

msg.add_header('Message-ID', email.utils.make_msgid())        
msg.add_header('Content-Transfer-Encoding', '8bit')
msg.add_header('Reply-To', replyto)
msg.add_header('Errors-To', 'it@kipspb.ru')
msg.set_charset("UTF-8")

now = datetime.now(pytz.timezone('W-SU'))
day = now.strftime('%a')
date = now.strftime('%d %b %Y %X %z')
msg["Date"] =  day + ', ' + date

msg["From"] = _from
msg["To"] = receiver 
msg['Subject'] = Header(subject, 'UTF-8')



rc = 999
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
    smtpObj = None
    try:
        if port == 25:
            smtpObj = smtplib.SMTP(smtp,port)
            if smtp != 'mail.arc.world':
                smtpObj.starttls()
        else:
            smtpObj = smtplib.SMTP_SSL('{0}:{1}'.format(smtp,port))
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
        lines = result_string.splitlines()

        for line in lines:
            #plpy.notice('line='+line)
            qid = re_queued.match(line)
            if qid:
                msg_qid = qid.group(1)
                plpy.notice('===<<<<<<=== msg_qid=' + msg_qid)

                ts_match = re_timestamp.match(msg_qid)
                if ts_match:
                    out_msg_qid = ts_match.group(1)
                else:
                    out_msg_qid = msg_qid
                plpy.notice('===>>>>>>>=== out_msg_qid=' + out_msg_qid)

        #for line in lines:
        #    qid = re_queued.match(line)
        #    if qid:
        #        out_msg_qid = qid.group(1)

    except smtplib.SMTPServerDisconnected:
      rc = 11
    except smtplib.SMTPResponseException, e:
      rc = e.smtp_code
    except smtplib.SMTPConnectError:
      rc = 15
    except smtplib.SMTPAuthenticationError:
      rc = 17
    #except smtplib.SMTPException:
    #  rc = 18
    except smtplib.SMTPSenderRefused:
      rc = 12
    except smtplib.SMTPRecipientsRefused:
      rc = 13
    except smtplib.SMTPDataError:
      rc = 14
    except smtplib.SMTPHeloError:
      rc = 16
    except Exception, e:
      rc = 99
      plpy.notice('Unknown:' + str(e))
    else:
      if smtpObj:
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
ALTER FUNCTION public.send_attachment(text, text, text, text, integer, text, text, text, text, text[])
  OWNER TO postgres;
