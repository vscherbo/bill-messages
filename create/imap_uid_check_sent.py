#!/usr/bin/env python

import os
import re
import imaplib
import email
import email.message
import pdb

re_rcv_by=re.compile("by .* id ([-0-9a-zA-Z]+);")

imap = imaplib.IMAP4_SSL('imap.yandex.ru')
imap.login('no-reply@tabloled.ru', 'Ya-m@il')
#print('imap.capabilities=%s' % str(imap.capabilities))

#debug_sent_ids = ['hxtvfIfnBn-77IKejPm']
#debug_sent_ids = ['CbYhVzIdq2-YdUGoXYo']
debug_sent_ids = ['hxtvfIfnBn-77IKejPm',
        'CbYhVzIdq2-YdUGoXYo',
        'wJOoGztpJj-QbWGdlIx']


#print(imap.list())


imap.select('mailer-daemon')
#imap.select('Sent')

result, search_data = imap.uid('search', None, '(FROM "mailer-daemon@yandex.ru")')
msg_uid_list = search_data[0].split()
#pdb.set_trace()

for msg_uid in msg_uid_list:
    result, msg_data = imap.uid('fetch', msg_uid, '(RFC822)')

    print('msg_uid=%s, result=%s' % (msg_uid, result))
    #print('msg_uid=%s, msg_data[0][0]=%s' % (msg_uid, msg_data[0][0]))
    #continue

    raw_email = msg_data[0][1]
    #print('raw_email=%s' % raw_email)
    #break
    #continue
    msg = email.message_from_string(raw_email)

    print 'msg.keys=%s' % msg.keys()
    #print 'msg.is_multipart=%s' % msg.is_multipart()
    if (msg.is_multipart() and len(msg.get_payload()) > 1 and 
        msg.get_payload(1).get_content_type() == 'message/delivery-status'):
        for part in msg.walk():
            part_type = part.get_content_type()
            if part.has_key('action'):
                #print 'part.items=%s' % part.items()
                print 'action=%s, diagn=%s' % (part['action'], part['diagnostic-code'])
                #print 'action=%s part.items=%s' % part['action'], part.items()
            #else:
            #    print 'part.keys=%s' % part.keys()
            #print 'part.get_content_type()=%s' % part_type
            if part_type == 'message/rfc822':
                for subpart in part.walk():
                    rcv_list = subpart.get_all('Received')
                    if rcv_list:
                        for rcv in rcv_list:
                            res=re_rcv_by.match(rcv)
                            if res:
                                non_delivered_id = res.group(1)
                                print('msg_id=%s' % non_delivered_id)
                                if non_delivered_id in debug_sent_ids:
                                    print('FOUND!')
                                    result = imap.uid('COPY', msg_uid, 'mailer-daemon|done')

                                    if result[0] == 'OK':
                                        print('COPY OK')
                                        mov, data = imap.uid('STORE', msg_uid , '+FLAGS', '(\Deleted)')
                                        imap.expunge()
                                    else:
                                        print('result[0]=%s' % result[0])
                                        print('type(result)=%s' % type(result))
                                        for i_res in result:
                                            print('i_res=%s' % i_res)

        #pdb.set_trace()
        # email is DSN
        # print(msg.get_payload(0).get_payload()) # human-readable section

        """
        for dsn in msg.get_payload(1).get_payload():
            print('action: %s' % dsn['action']) # e.g., "failed", "delivered"
            #print('dsn: %s' % dsn)

        if len(msg.get_payload()) > 2:
           print(msg.get_payload(2)) # original message
        """


imap.close()
imap.logout()
