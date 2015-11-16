SELECT q."№ счета", q.msg, q.msg_timestamp, q.msg_to, q.msg_status, s.email_to, s.delivered
FROM СчетОчередьСообщений q
LEFT JOIN send_email_result s ON s.qid = q.msg_qid
WHERE
  q."№ счета" = 38191415
  AND q.msg_timestamp > '2015-05-07'
  -- AND s.delivered IS NOT true
ORDER BY 1
  