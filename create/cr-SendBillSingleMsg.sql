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
    loc_msg_status INTEGER := 0;

    loc_order_no VARCHAR;
    loc_subj VARCHAR;
    str_docs varchar;
    loc_bcc VARCHAR;
    str_bill_no VARCHAR;
  loc_RETURNED_SQLSTATE TEXT;
  loc_MESSAGE_TEXT TEXT;
  loc_PG_EXCEPTION_DETAIL TEXT;
  loc_PG_EXCEPTION_HINT TEXT;
  loc_PG_EXCEPTION_CONTEXT TEXT;
loc_bill_owner INTEGER;
loc_ext_phone VARCHAR;
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

/**
SELECT e.email, e.Имя, f.Название
    FROM Сотрудники e, Счета b, Фирма f
    WHERE msg."№ счета" = b."№ счета" 
        AND b.фирма = f.КлючФирмы
        AND b.Хозяин = e.Менеджер 
    INTO mgr_addr, mgr_name, firm_name ;
**/
SELECT * FROM autobill_mgr_attrs(msg."№ счета") INTO mgr_addr, mgr_name, firm_name, loc_ext_phone;

msg_post := msg_post_common
        || mgr_name
        || E', e-mail: ' || mgr_addr || E',\r\n'
        || E'телефон:  (812)327-327-4, доб. '|| loc_ext_phone || E'\r\n'
        || E'С уважением,\r\n' 
        || firm_name;

CASE msg.msg_to
   WHEN 0 THEN -- to client
      loc_bill_owner := msg."№ счета" / 1000000;
      IF 41 = loc_bill_owner THEN -- для Хозяина 41, отправляем клиенту
          to_addr := msg.ЕАдрес;
      ELSIF is_tester(msg.КодРаботника) THEN
          to_addr := msg.ЕАдрес;
      ELSE -- не 41, значит дилерский. И не тестер. Подменяем в получателе клиента на менеджера
          to_addr := mgr_addr;
      END IF; -- <> 41

      loc_bcc := mgr_addr || ',vscherbo@kipspb.ru';
   WHEN 1 THEN -- to manager
      to_addr := mgr_addr;
      -- loc_bcc := 'vscherbo@gmail.com'; -- DEBUG only
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
    SELECT "Номер"::VARCHAR into loc_order_no FROM bx_order WHERE "Счет"= msg."№ счета";
    IF msg.msg_type IN (1,5) THEN
       loc_subj := 'Изменение статуса счёта № '|| str_bill_no;
    ELSIF msg.msg_type IN (2,3,4) THEN
        loc_subj := 'Ваш заказ '|| (SELECT COALESCE(loc_order_no, '') ) || ' на сайте kipspb.ru';
        -- создать документы
        BEGIN
           str_docs := fn_create_attachment(msg."№ счета", msg.msg_type);
        EXCEPTION WHEN OTHERS THEN
            str_docs := '';
            GET STACKED DIAGNOSTICS
                loc_RETURNED_SQLSTATE = RETURNED_SQLSTATE,
                loc_MESSAGE_TEXT = MESSAGE_TEXT,
                loc_PG_EXCEPTION_DETAIL = PG_EXCEPTION_DETAIL,
                loc_PG_EXCEPTION_HINT = PG_EXCEPTION_HINT,
                loc_PG_EXCEPTION_CONTEXT = PG_EXCEPTION_CONTEXT ;
            loc_msg_problem = format('RETURNED_SQLSTATE=%s, MESSAGE_TEXT=%s, PG_EXCEPTION_DETAIL=%s, PG_EXCEPTION_HINT=%s, PG_EXCEPTION_CONTEXT=%s', loc_RETURNED_SQLSTATE, loc_MESSAGE_TEXT, loc_PG_EXCEPTION_DETAIL, loc_PG_EXCEPTION_HINT, loc_PG_EXCEPTION_CONTEXT);
            loc_msg_status := 995;
            UPDATE bx_order SET billcreated = -3 WHERE "Счет" = msg."№ счета";
            RAISE NOTICE 'ОШИБКА при создании документов автосчёта=[%] exception=[%]', msg."№ счета", loc_msg_problem;
        END;

        RAISE NOTICE 'a_msg_id=%, sender=%, mgr_addr=%, to_addr=%, loc_bcc=%', a_msg_id, sender, mgr_addr, to_addr, loc_bcc;
    ELSIF 9 = msg.msg_type THEN -- оповещение менеджера
       loc_subj := 'Создан автосчёт '|| str_bill_no || ' по заказу '|| (SELECT COALESCE(loc_order_no, '') ) || ' на сайте kipspb.ru';
    ELSIF 11 = msg.msg_type THEN -- истекает срок оплаты счёта
        loc_subj := 'Истекает срок оплаты счёта '|| str_bill_no;
    ELSE
       loc_msg_status := 994;
       RAISE NOTICE 'Недопустимый тип msg_type=% в сообщении msg_id=%', msg.msg_type, msg.id;
    END IF;

    -- RAISE NOTICE 'a_msg_id=%, sender=%, mgr_addr=%, to_addr=%, loc_bcc=%', a_msg_id, sender, mgr_addr, to_addr, loc_bcc;
    /**/
    
    IF 0 = loc_msg_status THEN
        PERFORM sendmsg(a_msg_id,
                        sender::TEXT, pwd::TEXT, mgr_addr::TEXT, to_addr::TEXT, 
                        full_msg::TEXT, 
                        loc_subj::TEXT, 
                        loc_bcc::TEXT, 
                        str_docs::TEXT );
    END IF;
    /**/
END IF; -- to_addr

UPDATE "СчетОчередьСообщений" SET
              msg_status = loc_msg_status
              , msg_count = msg_count + 1
              , msg_problem = loc_msg_problem
              , msg_sent_to = to_addr
WHERE id = msg.id;
IF NOT FOUND THEN
   RAISE NOTICE 'sendbillsinglemsg:: NOT FOUND after UPDATE msg.id=% for to_addr=%', msg.id, to_addr;
ELSE
   RAISE NOTICE 'sendbillsinglemsg:: UPDATED msg.id=% for to_addr=% loc_msg_status=%', msg.id, to_addr, loc_msg_status;
END IF;      
      
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sendbillsinglemsg(integer)
  OWNER TO arc_energo;
