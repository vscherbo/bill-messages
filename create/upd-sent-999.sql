UPDATE 
  СчетОчередьСообщений
SET msg_status = 999
FROM
  send_email_result r
WHERE 
 msg_qid = r.qid
 AND r.delivered = True
