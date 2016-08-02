-- Function: fn_sendbillmsgparam(integer[])

-- DROP FUNCTION fn_sendbillmsgparam(integer[]);

CREATE OR REPLACE FUNCTION fn_sendbillmsgparam(a_msg_type integer[])
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
    pwd varchar := 'Never-adm1n';

    -- production
    smtp_srv CONSTANT varchar := 'smtp.kipspb.ru';
    sender varchar := 'no-reply@kipspb.ru';

    -- test
    --smtp_srv CONSTANT varchar := 'mail.arc.world';
    --sender varchar := 'root@arc.world';

    loc_msg_qid varchar;
    loc_msg_problem varchar;
    loc_msg_status INTEGER;

    loc_RETURNED_SQLSTATE varchar;
    loc_MESSAGE_TEXT varchar;
    loc_PG_EXCEPTION_DETAIL varchar;
    loc_PG_EXCEPTION_HINT varchar;
    loc_PG_EXCEPTION_CONTEXT varchar;

    loc_order_no VARCHAR;
    loc_subj VARCHAR;
    arr_docs  VARCHAR[];
    str_docs TEXT;
BEGIN
    cnt := 0;
    -- FOR msg IN SELECT * FROM СчетОчередьСообщений WHERE (msg_status > 0 AND msg_status < 500 AND msg_count <= 3) LOOP
    FOR msg IN SELECT q.*, c.ЕАдрес, b.КодРаботника
                    FROM vwqueuedmsg q, Счета b
                    LEFT JOIN Работники c ON  b.КодРаботника = c.КодРаботника
                    WHERE q."№ счета" = b."№ счета"
                    AND q.msg_type = ANY(a_msg_type)
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
              -- DEBUG to_addr := msg.ЕАдрес;
              to_addr := 'vscherbo@mail.ru';
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
        -- *OLD* SELECT send_email(sender, pwd, current_srv, current_port, to_addr, 'Изменение статуса счёта № '||msg."№ счета", full_msg)
        --       INTO send_status;
        
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
            BEGIN
                IF 1 = msg.msg_type THEN
                   loc_subj := 'Изменение статуса счёта № '|| to_char(msg."№ счета", 'FM9999-9999');
                ELSIF msg.msg_type IN (2,3,4) THEN
                   SELECT "Номер"::VARCHAR into loc_order_no FROM bx_order WHERE "Счет"= msg."№ счета";
                   loc_subj := 'Ваш заказ '|| (SELECT COALESCE(loc_order_no, '') ) || ' на сайте kipspb.ru';
                   -- создать документы
                   str_docs := fn_create_attachment(msg."№ счета", msg.msg_type);
                ELSE
                   RAISE 'Недопустимый тип сообщения msg_id=%', msg.msg_id;
                END IF;
            
                SELECT *  INTO send_status, loc_msg_qid, rcpt_refused 
                FROM send_attachment(sender, pwd, mgr_addr, current_srv, current_port, to_addr, 
                                loc_subj, full_msg, string_to_array(str_docs, ',') );
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
            loc_msg_status := coalesce(send_status, 10);
        END IF;
           -- UPDATE
        UPDATE СчетОчередьСообщений 
        SET 
          msg_status = loc_msg_status
          , msg_count = msg_count + 1
          , msg_problem = loc_msg_problem
          , msg_qid = loc_msg_qid
        WHERE id = msg.id;
        IF 0 = send_status THEN 
           cnt := cnt+1;
        END IF;
    END LOOP; -- FOR queued msg
    RETURN cnt;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_sendbillmsgparam(integer[])
  OWNER TO arc_energo;
