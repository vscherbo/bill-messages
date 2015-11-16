DO $$ DECLARE
    send_status integer;
    rcpt_refused varchar;
    current_port integer;
    current_srv varchar;
    smtp_port CONSTANT integer := 25;
    pwd varchar := 'Never-adm1n';

    -- production
    smtp_srv CONSTANT varchar := 'kipspb.ru';
    sender varchar := 'no-reply@kipspb.ru';
    loc_msg_qid varchar;
    loc_msg_problem varchar;
    loc_msg_status INTEGER;
    to_addr VARCHAR;
    mgr_addr VARCHAR := 'no-reply@kipspb.ru';
    full_msg VARCHAR;
    loc_RETURNED_SQLSTATE varchar;
    loc_MESSAGE_TEXT varchar;
    loc_PG_EXCEPTION_DETAIL varchar;
    loc_PG_EXCEPTION_HINT varchar;
    loc_PG_EXCEPTION_CONTEXT varchar;
BEGIN
    current_srv := smtp_srv ;
    current_port := smtp_port ;
    to_addr := 'vscherbo@gmail.com';
    full_msg := NULL; -- 'test';

    SELECT *  INTO send_status, loc_msg_qid, rcpt_refused 
                FROM send_email(sender, pwd, mgr_addr, current_srv, current_port, to_addr, 
                                'Изменение статуса счёта №', full_msg);
    exception WHEN OTHERS THEN 
        GET STACKED DIAGNOSTICS 
            loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
            loc_MESSAGE_TEXT = MESSAGE_TEXT,
            loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
            loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
            loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
        loc_msg_problem = format('RETURNED_SQLSTATE=%s, 
                                  MESSAGE_TEXT=%s, 
                                  PG_EXCEPTION_DETAIL=%s, 
                                  PG_EXCEPTION_HINT=%s, 
                                  PG_EXCEPTION_CONTEXT=%s', 
                                  loc_RETURNED_SQLSTATE, 
                                  loc_MESSAGE_TEXT,
                                  loc_PG_EXCEPTION_DETAIL,
                                  loc_PG_EXCEPTION_HINT,
                                  loc_PG_EXCEPTION_CONTEXT );
        loc_msg_status := 998;
        RAISE NOTICE 'loc_msg_problem=%', loc_msg_problem ;
END; $$
