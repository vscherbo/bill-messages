UPDATE 
  СчетОчередьСообщений
SET msg_problem = r.smtp_msg
FROM
  send_email_result r
WHERE 
 msg_qid = r.qid
 AND r.delivered = False
