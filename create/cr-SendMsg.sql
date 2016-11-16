-- Function: sendmsg(integer, text, text, text, text, text, text, text, text[])

DROP FUNCTION sendmsg(integer, text, text, text, text, text, text, text, text[]);

CREATE OR REPLACE FUNCTION sendmsg(
    a_msg_id integer,
    sender text,
    pwd text,
    reply_to text,
    to_addr text,
    full_msg text,
    subj text DEFAULT ''::text,
    bcc text DEFAULT ''::text,
    str_docs text DEFAULT NULL::text)
  RETURNS void AS
$BODY$
DECLARE
    msg RECORD;
    send_status integer;
    rcpt_refused TEXT;

    smtp_srv TEXT;
    smtp_port CONSTANT integer := 25;
    current_srv TEXT;
    current_port integer;

    loc_sender TEXT;
    loc_subj TEXT;

    loc_msg_qid TEXT;
    loc_msg_problem TEXT;
    loc_msg_status INTEGER;

    loc_RETURNED_SQLSTATE TEXT;
    loc_MESSAGE_TEXT TEXT;
    loc_PG_EXCEPTION_DETAIL TEXT;
    loc_PG_EXCEPTION_HINT TEXT;
    loc_PG_EXCEPTION_CONTEXT TEXT;
BEGIN

/** debug **
    smtp_srv := 'mail.arc.world';
    loc_sender := 'root@arc.world';
**/

/** production **/
    smtp_srv := 'smtp.kipspb.ru';
    loc_sender := sender;
/**/

SELECT * INTO msg FROM vwqueuedmsg WHERE id = a_msg_id;

IF 2 = msg.msg_to THEN -- to file
    current_srv := '/tmp/email-file.txt' ;
    current_port := -1 ;
ELSE 
    current_srv := smtp_srv;
    current_port := smtp_port;
END IF;

IF subj IS NULL THEN
    loc_subj := msg.msg_subj;
ELSE
    loc_subj := subj;
END IF;

/**
RAISE NOTICE 'sender=%, pwd=%, current_srv=%, current_port=%, to_addr=%, bcc=%, loc_subj=%, subj=%',
              sender, pwd, current_srv, current_port, to_addr, bcc, loc_subj, subj;
**/

BEGIN 
    SELECT * INTO send_status, loc_msg_qid, rcpt_refused 
    FROM send_attachment(sender, pwd, sender, current_srv, current_port, to_addr, bcc, 
                    loc_subj, full_msg, string_to_array(str_docs, ',') );
    exception WHEN OTHERS THEN 
        GET STACKED DIAGNOSTICS 
            loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
            loc_MESSAGE_TEXT = MESSAGE_TEXT,
            loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
            loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
            loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
        loc_msg_problem = format('RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s, PG_EXCEPTION_DETAIL=%s, PG_EXCEPTION_HINT=%s, PG_EXCEPTION_CONTEXT=%s', 
                                  loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
        send_status := 998;
END;

loc_msg_status := coalesce(send_status, 10);
IF 13 = loc_msg_status THEN
    loc_msg_problem := COALESCE(loc_msg_problem, '') || ' rcpt_refused:' || rcpt_refused;
END IF;

-- UPDATE
UPDATE СчетОчередьСообщений 
SET 
  msg_status = loc_msg_status
  , msg_count = msg_count + 1
  , msg_problem = loc_msg_problem
  , msg_qid = loc_msg_qid
WHERE id = a_msg_id;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sendmsg(integer, text, text, text, text, text, text, text, text)
  OWNER TO arc_energo;
