-- View: vwqueuedmsg

-- DROP VIEW vwqueuedmsg;

CREATE OR REPLACE VIEW vwqueuedmsg AS 
 SELECT "СчетОчередьСообщений".id,
    "СчетОчередьСообщений"."№ счета",
    "СчетОчередьСообщений".msg_timestamp,
    "СчетОчередьСообщений".msg_priority,
    "СчетОчередьСообщений".msg_status,
    "СчетОчередьСообщений".msg,
    "СчетОчередьСообщений".msg_count,
    "СчетОчередьСообщений".msg_to,
    "СчетОчередьСообщений".msg_problem,
    "СчетОчередьСообщений".msg_qid
   FROM "СчетОчередьСообщений"
  WHERE ("СчетОчередьСообщений".msg_status > 0 AND "СчетОчередьСообщений".msg_status < 500 ) AND "СчетОчередьСообщений".msg_count < 3;

ALTER TABLE vwqueuedmsg
  OWNER TO arc_energo;
