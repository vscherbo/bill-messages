CREATE OR REPLACE FUNCTION arc_energo."fntr_СообщениеОбновлено"()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE 
  DT TIMESTAMP WITHOUT TIME ZONE;
  loc_msg VARCHAR;
  loc_inet_order NUMERIC; 
BEGIN
    DT := clock_timestamp();
    IF NEW.msg_problem IS NULL OR length(NEW.msg_problem) = 0 THEN 
        loc_msg := NEW.msg;
    ELSE
        loc_msg := 'Ошибка: ' || NEW.msg_problem || '/' || COALESCE(NEW.msg, 'msg IS NULL ');
    END IF;
    loc_msg := substring(loc_msg from 1 for 250);
    -- SELECT email_to INTO NEW.msg_sent_to FROM send_email_result e WHERE e.qid=NEW.msg_qid LIMIT 1;

    IF NEW.msg_sent_to IS NOT NULL THEN
        INSERT INTO "ДозвонНТУ"(
                "Счет", "Дата", "КтоЗвонил", "КомуПередал", "Примечание", status)
                -- tips)
        -- VALUES (NEW."№ счета", DT, 'робот', NEW.msg_sent_to, loc_msg, NEW.msg_status);
        VALUES (NEW."№ счета", DT, 'робот', NEW.msg_sent_to, rtrim(rpad(loc_msg, 250)), NEW.msg_status);
            -- ?);
    END IF;

    -- UPDATE "Счета" SET "Уведомили" = DT WHERE "№ счета" = NEW."№ счета";

    /** DEBUG only **/
    IF NEW.msg_type IN (2,3,4) THEN -- бланк заказа, бланк с квитанцией, счёт-факс
        RAISE NOTICE '№ счета=%, msg_type=%, msg_status=%, NEW.msg_sent_to=%', NEW."№ счета", NEW.msg_type, NEW.msg_status, NEW.msg_sent_to;
    END IF;
    /**/

    IF (NEW.msg_type IN (2,3,4)) AND -- бланк заказа, бланк с квитанцией, счёт-факс
       (0 = NEW.msg_status) AND -- email sent
       (position('@kipspb.ru' IN NEW.msg_sent_to) = 0) -- получатель внешний, т.е. не тестовое письмо
    THEN
        SELECT "ИнтернетЗаказ" INTO loc_inet_order FROM "Счета" WHERE "№ счета" = NEW."№ счета";
        IF FOUND THEN
            PERFORM "fn_InetOrderNewStatus"(0, loc_inet_order);
        ELSE /** DEBUG only **/
            RAISE NOTICE 'fntr_СообщениеОбновлено:: NOT FOUND № счета=%', NEW."№ счета";
        /**/
        END IF;
    END IF;
    
    RETURN NEW;
END;$function$
