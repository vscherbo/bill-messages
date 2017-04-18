-- Function: fn_sendbillmsg()

-- DROP FUNCTION fn_sendbillmsg();

CREATE OR REPLACE FUNCTION fn_sendbillmsg()
  RETURNS integer AS
$BODY$DECLARE
    msg RECORD;
    cnt integer;
    send_status integer;
    rcpt_refused varchar;
    full_msg varchar ;
    msg_pre VARCHAR = E'Это письмо сформировано автоматически, отвечать на него не нужно.\r\n\r\n' ;
    msg_post_common VARCHAR = E'\r\n\r\nНа все Ваши вопросы Вам ответит Ваш персональный менеджер:\r\n';
    msg_post varchar ;
    to_addr varchar ;
    mgr_addr varchar ;
    mgr_name varchar ;
    firm_name varchar ;    

    current_port integer;
    current_srv varchar;
    smtp_port CONSTANT integer := 25;
    smtp_srv varchar;
    pwd varchar;
    sender varchar;

    loc_msg_qid varchar;
    loc_msg_problem varchar;
    loc_msg_status INTEGER;

    loc_RETURNED_SQLSTATE varchar;
    loc_MESSAGE_TEXT varchar;
    loc_PG_EXCEPTION_DETAIL varchar;
    loc_PG_EXCEPTION_HINT varchar;
    loc_PG_EXCEPTION_CONTEXT varchar;
    
BEGIN
    smtp_srv := smtphost();
    IF pg_production() THEN
        pwd := 'Never-adm1n';
        sender := 'no-reply@kipspb.ru';
    ELSE
        pwd := '';
        sender := 'root@arc.world';
    END IF;

    cnt := 0;
    -- FOR msg IN SELECT * FROM СчетОчередьСообщений WHERE (msg_status > 0 AND msg_status < 500 AND msg_count <= 3) LOOP
    FOR msg IN SELECT q.*, c.ЕАдрес, b.КодРаботника
                    FROM vwqueuedmsg q, Счета b
                    LEFT JOIN Работники c ON  b.КодРаботника = c.КодРаботника
                    WHERE q."№ счета" = b."№ счета"
                    AND q.msg_type IN (1,5,11) -- до окончания отладки sendbillmsgparam
    LOOP
        SELECT e.email, e.Имя, f.Название
              FROM Сотрудники e, Счета b, Фирма f
              WHERE msg."№ счета" = b."№ счета" 
                AND b.фирма = f.КлючФирмы
                AND b.Хозяин = e.Менеджер 
              INTO mgr_addr, mgr_name, firm_name ;
    
        msg_post := msg_post_common
                || mgr_name
                || E', e-mail: ' || mgr_addr || E',\r\n'
                || E'телефон:  (812)327-327-4\r\n'
                || E'С уважением,\r\n' 
                || firm_name;

        current_srv := smtp_srv ;
        current_port := smtp_port ;

        CASE msg.msg_to
           WHEN 0 THEN -- to client
              to_addr := msg.ЕАдрес;
              -- msg_pre := E'Уважаемый клиент!\r\n\r\n' || msg_pre;
           WHEN 1 THEN -- to manager
              to_addr := mgr_addr;
              msg_post := E'\r\n\r\nПочтовый робот АРК Энергосервис';
           WHEN 2 THEN -- to file
              to_addr := msg.ЕАдрес;
              current_srv := '/tmp/email-file.txt' ;
              current_port := -1 ;
           ELSE
               to_addr := 'it@kipspb.ru';
               full_msg := 'Недопустимое значение поля СчетОчередьСообщений.msg_to=' || msg.msg_to ;
        END CASE;
        full_msg := msg_pre || msg.msg || msg_post;
        
        loc_msg_problem := NULL;
        loc_msg_qid := NULL;
        IF to_addr IS NULL THEN
            IF msg.КодРаботника IS NULL THEN
                loc_msg_status := 996;
                loc_msg_problem := 'Не указано контактное лицо';
            ELSIF msg.ЕАдрес IS NULL THEN
                loc_msg_status := 997;
                loc_msg_problem := 'Не указан e-mail';
            END IF;
        ELSE
            SELECT format('sender=%s, pwd=%s, mgr_addr=%s, current_srv=%s, current_port=%s, to_addr=%s, subj=%s, msg=%s', 
                            sender, pwd, mgr_addr, current_srv, current_port, to_addr, 
                            'Изменение статуса счёта № '|| to_char(msg."№ счета", 'FM9999-9999'), full_msg) INTO loc_MESSAGE_TEXT ;
            RAISE NOTICE '######################################## %', loc_MESSAGE_TEXT;
            /*** DEBUG ***/
            BEGIN
                SELECT *  INTO send_status, loc_msg_qid, rcpt_refused 
                FROM send_email(sender, pwd, mgr_addr, current_srv, current_port, to_addr, 
                                'Изменение статуса счёта № '|| to_char(msg."№ счета", 'FM9999-9999'), full_msg);                                
                exception WHEN OTHERS THEN 
                    GET STACKED DIAGNOSTICS 
                        loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                        loc_MESSAGE_TEXT = MESSAGE_TEXT,
                        loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                        loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                        loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
                        loc_msg_problem = format(
                                                'RETURNED_SQLSTATE=%s, 
                                                MESSAGE_TEXT=%s, 
                                                PG_EXCEPTION_DETAIL=%s, 
                                                PG_EXCEPTION_HINT=%s, 
                                                PG_EXCEPTION_CONTEXT=%s', 
                                                loc_RETURNED_SQLSTATE, 
                                                loc_MESSAGE_TEXT,
                                                loc_PG_EXCEPTION_DETAIL,
                                                loc_PG_EXCEPTION_HINT,
                                                loc_PG_EXCEPTION_CONTEXT );
                        send_status := 998;
            END;
            /***/
            loc_msg_status := coalesce(send_status, 10);
            IF 13 = loc_msg_status THEN
                loc_msg_problem := COALESCE(loc_msg_problem, '') || ' rcpt_refused:' || rcpt_refused;
            END IF;
        END IF;
           -- UPDATE
        UPDATE "СчетОчередьСообщений"
        SET 
          msg_status = loc_msg_status
          , msg_count = msg_count + 1
          , msg_problem = loc_msg_problem
          , msg_qid = loc_msg_qid
          , msg_sent_to = to_addr
        WHERE id = msg.id;
        IF 0 = send_status THEN 
           cnt := cnt+1;
        END IF;
    END LOOP; -- FOR queued msg
    RETURN cnt;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_sendbillmsg()
  OWNER TO arc_energo;
