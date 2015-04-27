SELECT q1."№ счета", q1.msg_timestamp, q1.msg, q2.msg_timestamp, q2.msg
FROM СчетОчередьСообщений q1, СчетОчередьСообщений q2
WHERE q1."№ счета" = q2."№ счета"
AND q1.id <> q2.id
AND q1.msg_timestamp < q2.msg_timestamp