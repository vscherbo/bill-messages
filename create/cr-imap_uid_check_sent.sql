create or replace function imap_uid_check_sent(
in arg_imap_srv varchar,
in arg_login varchar,
in arg_password varchar,
in arg_folder varchar,
in arg_sender varchar
)
returns varchar
language plpython2u
as
$$

import re
import imaplib
import email
import email.message
import plpy

ret_result = ''
msg_status = None

re_rcv_by=re.compile("by .* id ([-0-9a-zA-Z]+);")

imap = imaplib.IMAP4_SSL(arg_imap_srv)
imap.login(arg_login, arg_password)
# imap.login('no-reply@tabloled.ru', 'Ya-m@il')


imap.select(arg_folder)
#imap.select('mailer-daemon')

#result, search_data = imap.uid('search', None, '(FROM "mailer-daemon@yandex.ru")')
search_result, search_data = imap.uid('search', None, '(FROM "%s")' % arg_sender)
msg_uid_list = search_data[0].split()

for msg_uid in msg_uid_list:
    fetch_result, msg_data = imap.uid('fetch', msg_uid, '(RFC822)')

    if fetch_result == 'OK':
        # raw_email
        msg = email.message_from_string(msg_data[0][1])

        if (msg.is_multipart() and len(msg.get_payload()) > 1 and 
            msg.get_payload(1).get_content_type() == 'message/delivery-status'):
            for part in msg.walk():
                part_type = part.get_content_type()
                part_diag = dict(part.items())
                plpy.notice('part_diag=%s' % part_diag)
                if part.has_key('diagnostic-code'):
                    msg_problem = part['diagnostic-code']
                    msg_diag = part_diag
                    if not msg_status and part.has_key('status'):
                        # try int()
                        msg_status = int(part['status'].replace('.', ''))
                    else:
                        msg_status = 994
                    plpy.notice('msg_status=%s' % msg_status)
                if part_type == 'message/rfc822':
                    for subpart in part.walk():
                        if subpart.has_key('to'):
                            plpy.notice('subpart.to=%s' % subpart['to'])
                            msg_to = subpart['to']
                        rcv_list = subpart.get_all('Received')
                        if rcv_list:
                            for rcv in rcv_list:
                                res=re_rcv_by.match(rcv)
                                if res and msg_diag:
                                    non_delivered_id = res.group(1)
                                    msg_qid = non_delivered_id
                                    plpy.notice('msg_qid=%s' % msg_qid)
                                    ins_sql = "INSERT INTO send_problem(mail_srv, msg_qid, msg_to, msg_diag) VALUES (E'%s', E'%s', E'%s', E'%s')" % (arg_imap_srv, msg_qid, msg_to, str(msg_diag).replace("'", "\\'"))
                                    plpy.notice('ins_sql=%s' % ins_sql)
                                    msg_diag = None
                                    try:
                                        plpy.execute(ins_sql)
                                    except plpy.SPIError, e:
                                        ret_result = "INSERT INTO send_problem error, SQLSTATE %s" % e.sqlstate
                                    else:
                                        upd_sql = """UPDATE "СчетОчередьСообщений" SET msg_status = %s, msg_problem = E'%s' WHERE msg_qid = '%s'""" % (msg_status, msg_problem.replace("'", "\\'"), msg_qid)
                                        plpy.notice('upd_sql=%s' % upd_sql)
                                        try:
                                            plpy.execute(upd_sql)
                                        except plpy.SPIError, e:
                                            ret_result = "UPDATE СчетОчередьСообщений error, SQLSTATE %s" % e.sqlstate
                                            plpy.warning(ret_result)
                                        else:
                                            copy_result = imap.uid('COPY', msg_uid, 'mailer-daemon|done')
                                            if copy_result[0] == 'OK':
                                                # TODO try
                                                mov, data = imap.uid('STORE', msg_uid , '+FLAGS', '(\Deleted)')
                                                imap.expunge()
                                            else:
                                                plpy.warning(copy_result)
                                                ret_result = copy_result
    else:
        plpy.notice('Error reading msg_uid=%s, result=%s' % (msg_uid, result))



imap.close()
imap.logout()
return ret_result
$$
