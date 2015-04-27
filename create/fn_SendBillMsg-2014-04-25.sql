-- Function: fn_sendbillmsg()

-- DROP FUNCTION fn_sendbillmsg();

CREATE OR REPLACE FUNCTION fn_sendbillmsg()
  RETURNS integer AS
$BODY$DECLARE
    msg RECORD;
    cnt integer;
    send_status integer;
    full_msg varchar ;
    msg_pre varchar ;
    msg_post varchar ;
    to_addr varchar ;
    mgr_addr varchar ;
    mgr_name varchar ;
    firm_name varchar ;    
    smtp_port integer := 25;
    smtp_srv varchar := 'kipspb.ru';
    sender varchar := 'no-reply@kipspb.ru';
    pwd varchar := 'Never-adm1n';
BEGIN
    cnt := 0;
    msg_pre := E'Это письмо сформировано автоматически, отвечать на него не нужно.\r\n\r\n' ;
    -- msg_post := E'\r\n\r\nЕсли у Вас возникли вопросы,\r\nВы можете обратиться к Вашему персональному менеджеру:\r\n';
    msg_post := E'\r\n\r\nНа все Ваши вопросы Вам ответит Ваш персональный менеджер:\r\n';
    -- FOR msg IN SELECT * FROM СчетОчередьСообщений WHERE (msg_status > 0 AND msg_status < 500 AND msg_count <= 3) LOOP
    FOR msg IN SELECT * FROM СчетОчередьСообщений q, vwЕАдресСчета a 
               WHERE msg_status > 0 AND msg_status < 500 
                     AND msg_count <= 3
                     AND a."№ счета" = q."№ счета"
    LOOP
        SELECT e.email, e.Имя, f.Название
              FROM Сотрудники e, Счета b, Фирма f
              WHERE msg."№ счета" = b."№ счета" 
                AND b.фирма = f.КлючФирмы
                AND b.Хозяин = e.Менеджер 
              INTO mgr_addr, mgr_name, firm_name ;
    
        full_msg := msg_pre || msg.msg || msg_post
                || mgr_name
                || E', e-mail: ' || mgr_addr || E',\r\n'
                || E'телефон:  (812)327-327-4\r\n'
                || E'С уважением,\r\n' 
                || firm_name;

        smtp_port := 25;
        smtp_srv := 'kipspb.ru';

        CASE msg.msg_to
           WHEN 0 THEN -- to client
              to_addr := msg.ЕАдрес;
           WHEN 1 THEN -- to manager
              to_addr := mgr_addr;
              full_msg := msg.msg ;
           WHEN 2 THEN -- to file
              to_addr := msg.ЕАдрес;
              smtp_srv := '/tmp/email-file.txt' ;
              smtp_port := -1 ;
           ELSE
               to_addr := 'it@kipspb.ru';
               full_msg := 'Недопустимое значение поля СчетОчередьСообщений.msg_to=' || msg.msg_to ;
        END CASE;
        SELECT send_email(sender, pwd, smtp_srv, smtp_port, to_addr, 'Изменение статуса счёта № '||msg."№ счета", full_msg)
               INTO send_status;
           -- UPDATE
        UPDATE СчетОчередьСообщений 
        SET msg_status = coalesce(send_status, 10), msg_count = msg_count + 1
        WHERE id = msg.id;
        IF 0 = send_status THEN 
           cnt := cnt+1;
        END IF;
    END LOOP; -- FOR msg with email
    -- Defer msg with КодРаботника IS NULL 
    FOR msg IN SELECT q.id FROM vwQueuedMsg q, Счета b
                           WHERE q."№ счета" = b."№ счета" AND b.КодРаботника IS NULL
    LOOP
        UPDATE СчетОчередьСообщений
        SET msg_status = 996
        WHERE id = msg.id;
    END LOOP; -- FOR msg with КодРаботника IS NULL
    -- Defer msg without/invalid email
    FOR msg IN SELECT q.id, q."№ счета", c.ЕАдрес, c.ФИО
               FROM vwQueuedMsg q, Счета b, Работники c
               WHERE q."№ счета" = b."№ счета"
                     AND b.КодРаботника = c.КодРаботника
                     AND c.ЕАдрес IS NULL
    LOOP
        UPDATE СчетОчередьСообщений 
        SET msg_status = 997, msg_problem = coalesce('empty ЕАдрес', msg.ЕАдрес)
        WHERE id = msg.id;
    END LOOP; -- FOR msg without email
    RETURN cnt;  
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_sendbillmsg()
  OWNER TO arc_energo;
