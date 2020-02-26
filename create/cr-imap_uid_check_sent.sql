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
from plpy import notice as pl_notice
from plpy import warning as pl_warning
from plpy import execute as pl_execute
from plpy import SPIError as pl_SPIError

re_rcv_by=re.compile("by .* id ([-0-9a-zA-Z]+);")
re_rcv_by_str=re.compile("^Received: by .* id ([-0-9a-zA-Z]+);")
re_to=re.compile("To: (.*)")

# DEBUG
#def pl_execute(arg_sql):
#    pass

######################
def db_write(a_imap_srv, a_msg_qid='empty', a_msg_to='empty', a_msg_diag='empty', a_msg_status='empty', a_msg_problem='empty'):
    loc_result = ''
    ins_sql = "INSERT INTO send_problem(mail_srv, msg_qid, msg_to, msg_diag) VALUES (E'%s', E'%s', E'%s', E'%s')" % (a_imap_srv, a_msg_qid, a_msg_to, str(a_msg_diag).replace("'", "\\'"))
    pl_notice('ins_sql=%s' % ins_sql)
    try:
        pl_execute(ins_sql)
    except pl_SPIError, e:
        loc_result = "INSERT INTO send_problem error, SQLSTATE %s" % e.sqlstate
    else:
        upd_sql = """UPDATE "СчетОчередьСообщений" SET msg_status = %s, msg_problem = E'%s' WHERE msg_qid = '%s'""" % (a_msg_status, a_msg_problem.replace("'", "\\'"), a_msg_qid)
        pl_notice('upd_sql=%s' % upd_sql)
        try:
            pl_execute(upd_sql)
        except pl_SPIError, e:
            loc_result = "UPDATE СчетОчередьСообщений error, SQLSTATE %s" % e.sqlstate
    return loc_result

######################
def to_extract(a_part):
    loc_to = ''
    if a_part:
        if a_part.has_key('to'):
            loc_to = a_part['to']
            pl_notice('>>> FOUND loc_to=%s' % loc_to)
    return loc_to

######################
def qid_extract(a_part):
    loc_qid = None
    if a_part:
        rcv_list = a_part.get_all('Received')
        if rcv_list:
            #pl_notice('rcv_list=%s' % rcv_list)
            for rcv in rcv_list:
                res=re_rcv_by.match(rcv)
                if res:
                    non_delivered_id = res.group(1)
                    loc_qid = non_delivered_id
                    pl_notice('>>> FOUND loc_qid=%s' % loc_qid)
        else:
            pass
            #pl_notice('rcv_list is None')
    return loc_qid


ret_result = ''
msg_status = None

imap = imaplib.IMAP4_SSL(arg_imap_srv)
imap.login(arg_login, arg_password)


imap.select(arg_folder)

search_result, search_data = imap.uid('search', None, '(FROM "%s")' % arg_sender)
msg_uid_list = search_data[0].split()

for msg_uid in msg_uid_list:
    fetch_result, msg_data = imap.uid('fetch', msg_uid, '(RFC822)')

    if fetch_result == 'OK':
        msg_status = None
        msg_diag = None
        msg_problem = None
        msg_to = None
        msg_qid = None
        pl_notice('################################')

        # raw_email
        msg = email.message_from_string(msg_data[0][1])
        #_structure(msg)  # DEBUG
        payloads_cnt = len(msg.get_payload())
        #for i_payload in range(payloads_cnt):
        #    pl_notice('payload[%s]=%s' % (i_payload, type(msg.get_payload(i_payload))))
        if (msg.is_multipart() and len(msg.get_payload()) > 1 and
            msg.get_payload(1).get_content_type() == 'message/delivery-status'):
            for part in msg.walk():
                part_type = part.get_content_type()
                part_diag = dict(part.items())
                #pl_notice('part_type=%s' % part_type)
                #pl_notice('part.keys()=%s' % part.keys())
                if part.has_key('to'):
                    msg_to = to_extract(part)
                msg_qid = qid_extract(part) or msg_qid
                #pl_notice('msg.walk extracted msg_to={0}, msg_qid={1}'.format(msg_to, msg_qid))
                if part.has_key('diagnostic-code'):
                    msg_problem = part['diagnostic-code']
                    #pl_notice('has_key diagnostic-code msg_problem=%s' % msg_problem)
                    msg_diag = part_diag
                    if not msg_status:
                        if part.has_key('status'):
                            #pl_notice("(not msg_status)=%s and part['status']=%s" % (not msg_status, part['status']) )
                            # try int()
                            msg_status = int(part['status'].replace('.', ''))
                        else:
                            msg_status = 994
                    pl_notice('msg_status=%s, msg_diag=%s' % (msg_status, msg_diag))
                if part_type == 'text/rfc822-headers':
                    msg2 = msg.get_payload(2)
                    if msg2:
                        #pl_notice('msg2={0}'.format(msg2))
                        #pl_notice('msg2_type=%s' % msg2.__class__.__name__)
                        #pl_notice('len(msg2)=%s' % len(msg2))
                        if not msg2.is_multipart():
                            #pl_notice('msg2.is_multipart is FALSE')
                            p2 = msg2.get_payload()
                            #pl_notice('len(p2)=%s' % len(p2))
                            list2 = p2.split('\n')
                            for el in list2:
                                #pl_notice('el={0}'.format(el))
                                res=re_rcv_by_str.match(el)
                                if res:
                                    msg_qid = res.group(1)
                                    pl_notice('in str={0}'.format(el))
                                    pl_notice('>>> FOUND msg_qid=%s' % msg_qid)
                                res=re_to.match(el)
                                if res:
                                    msg_to = res.group(1)
                                    pl_notice('>>> FOUND msg_to=%s' % msg_to)

            if msg_diag:
                db_res = db_write(arg_imap_srv, msg_qid, msg_to, msg_diag, msg_status, msg_problem)
                if db_res == '':
                    copy_result = imap.uid('COPY', msg_uid, 'mailer-daemon|done')
                    if copy_result[0] == 'OK':
                        # TODO try
                        mov, data = imap.uid('STORE', msg_uid , '+FLAGS', '(\Deleted)')
                        imap.expunge()
                    else:
                        ret_result = copy_result
                        pl_warning(ret_result)
                else:
                    ret_result = db_res
                    pl_warning(ret_result)

    else:
        ret_result = fetch_res
        pl_warning('Error reading msg_uid=%s, result=%s' % (msg_uid, res_result))

imap.close()
imap.logout()
return ret_result
$$
