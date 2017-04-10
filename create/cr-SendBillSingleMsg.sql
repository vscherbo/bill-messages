-- Function: sendbillsinglemsg(integer)

-- DROP FUNCTION sendbillsinglemsg(integer);

CREATE OR REPLACE FUNCTION sendbillsinglemsg(a_msg_id integer)
  RETURNS void AS
$BODY$DECLARE
    msg RECORD;
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

    sender varchar := 'no-reply@kipspb.ru';
    pwd varchar := 'Never-adm1n';

    loc_msg_problem varchar;
    loc_msg_status INTEGER;

    loc_order_no VARCHAR;
    loc_subj VARCHAR;
    str_docs varchar;
    loc_bcc VARCHAR;
    str_bill_no VARCHAR;
BEGIN

SELECT q.*, c.ЕАдрес, b.КодРаботника INTO msg
   FROM vwqueuedmsg q, Счета b
   LEFT JOIN Работники c ON  b.КодРаботника = c.КодРаботника
   WHERE
       q."№ счета" = b."№ счета"
       AND q.id = a_msg_id;

IF NOT FOUND THEN
   RAISE NOTICE 'Не найдено сообщение с id=%, формирование письма прервано', quote_nullable(a_msg_id);
   RETURN; 
END IF;

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

CASE msg.msg_to
   WHEN 0 THEN -- to client
      to_addr := get_bill_send_to(msg.КодРаботника,  msg.ЕАдрес);
      -- если to_addr содержит arutyun, т.е. не Дилер-тестер
      -- и при этом mgr_addr не arutyun, т.е. счёт дилерский и Хозяин не arutyun
      -- меняем адресата: вместо arutyun - менеджер-хозяин
      IF mgr_addr <> 'arutyun@kipspb.ru' AND position('arutyun@kipspb.ru' in to_addr) > 0
      THEN
        to_addr := mgr_addr;
      END IF;
      loc_bcc := mgr_addr || ',vscherbo@kipspb.ru';
   WHEN 1 THEN -- to manager
      to_addr := mgr_addr;
      IF mgr_addr <> 'arutyun@kipspb.ru' THEN
         loc_bcc := 'vscherbo@gmail.com'; -- DEBUG only
      END IF;
      msg_post := E'\r\n\r\nПочтовый робот АРК Энергосервис';
   WHEN 2 THEN -- to file
      to_addr := msg.ЕАдрес;
   ELSE
       to_addr := 'it@kipspb.ru';
       full_msg := 'Недопустимое значение поля СчетОчередьСообщений.msg_to=' || msg.msg_to ;
END CASE;
full_msg := msg_pre || msg.msg || msg_post;

IF to_addr IS NULL THEN
    IF msg.КодРаботника IS NULL THEN
        loc_msg_status := 996;
        loc_msg_problem := 'Не указано контактное лицо';
    ELSIF msg.ЕАдрес IS NULL THEN
        loc_msg_status := 997;
        loc_msg_problem := 'Не указан e-mail';
    END IF;
ELSE
    str_bill_no := to_char(msg."№ счета", 'FM9999-9999');
    IF msg.msg_type IN (1,5) THEN
       loc_subj := 'Изменение статуса счёта № '|| str_bill_no;
    ELSIF msg.msg_type IN (2,3,4) THEN
       SELECT "Номер"::VARCHAR into loc_order_no FROM bx_order WHERE "Счет"= msg."№ счета";
       loc_subj := 'Ваш заказ '|| (SELECT COALESCE(loc_order_no, '') ) || ' на сайте kipspb.ru';
       -- создать документы
       str_docs := fn_create_attachment(msg."№ счета", msg.msg_type);
       RAISE NOTICE 'a_msg_id=%, sender=%, mgr_addr=%, to_addr=%, loc_bcc=%', a_msg_id, sender, mgr_addr, to_addr, loc_bcc;
    ELSIF 9 = msg.msg_type THEN -- оповещение менеджера
       SELECT "Номер"::VARCHAR into loc_order_no FROM bx_order WHERE "Счет"= msg."№ счета";
       loc_subj := 'Создан автосчёт '|| str_bill_no || ' по заказу '|| (SELECT COALESCE(loc_order_no, '') ) || ' на сайте kipspb.ru';
    ELSE
       RAISE 'Недопустимый тип msg_type=% в сообщении msg_id=%', msg.msg_type, msg.id;
    END IF;

    -- RAISE NOTICE 'a_msg_id=%, sender=%, mgr_addr=%, to_addr=%, loc_bcc=%', a_msg_id, sender, mgr_addr, to_addr, loc_bcc;
    /**/
    PERFORM sendmsg(a_msg_id,
                    sender::TEXT, pwd::TEXT, mgr_addr::TEXT, to_addr::TEXT, 
                    full_msg::TEXT, 
                    loc_subj::TEXT, 
                    loc_bcc::TEXT, 
                    str_docs::TEXT );
    loc_msg_status := 0;
    /**/
END IF; -- to_addr

UPDATE "СчетОчередьСообщений" SET
              msg_status = loc_msg_status
              , msg_count = msg_count + 1
              , msg_problem = loc_msg_problem
              , msg_sent_to = to_addr
WHERE id = msg.id;
IF NOT FOUND THEN
   RAISE NOTICE 'sendbillsinglemsg:: NOT FOUND msg.id=% for to_addr=%', msg.id, to_addr;
ELSE
   RAISE NOTICE 'sendbillsinglemsg:: UPDATED msg.id=% for to_addr=% loc_msg_status=%', msg.id, to_addr, loc_msg_status;
END IF;      
      
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sendbillsinglemsg(integer)
  OWNER TO arc_energo;
