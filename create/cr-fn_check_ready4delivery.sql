-- Function: fn_check_ready4delivery()

-- DROP FUNCTION fn_check_ready4delivery();

CREATE OR REPLACE FUNCTION fn_check_ready4delivery(arg_real_send bool DEFAULT FALSE)
  RETURNS void AS
$BODY$DECLARE
    b RECORD;
    mstr varchar; -- (255);
    loc_msg_to integer;
    cnt INTEGER;
    do_send BOOLEAN := FALSE;
    _now TIMESTAMP WITHOUT TIME ZONE;
    loc_last_interval INTERVAL;
    loc_last_reminder_ts TIMESTAMP WITHOUT TIME ZONE;
    loc_firm_name TEXT;
    loc_dbg_str TEXT;
    loc_msg_status integer := -99;  -- do not send
BEGIN
FOR b IN SELECT "№ счета", "Дата счета", предок, Сумма
    FROM Счета
    WHERE 
        Готов = 't'
        AND Отгружен = 'f'
        AND Отменен = 'f'
--        AND Отгрузка = 'Самовывоз'
        AND Отгрузка in ('Самовывоз', 'Курьер заказчика')
        AND Накладная IS NULL
        AND Фактура IS NULL
        AND "Дата счета" > '2019-11-01' 
        AND Хозяин <> 91
        AND ( Сумма = fn_bill_payment("№ счета") OR Сумма = fn_bill_inetpayment("№ счета") )
        AND r4d_sent_count("№ счета")<3
        AND r4d_send_errors_count("№ счета")=0
LOOP
    -- RAISE NOTICE '№ счета,=%', b."№ счета" ; 

    mstr := E'';
    IF b.предок = b."№ счета" THEN
        mstr := mstr || E'Заказ ' || to_char(b."№ счета", 'FM9999-9999');
    ELSE
        mstr := mstr || E'Заказ ' || to_char(b.предок, 'FM9999-9999') || '/' || to_char(b."№ счета", 'FM9999-9999');
    END IF;
    mstr := mstr || E' от ' || to_char(b."Дата счета", 'YYYY-MM-DD');

    SELECT f."Название" INTO loc_firm_name FROM "Счета" b1, "Фирма" f WHERE  b1."№ счета" = b."№ счета" AND b1."фирма" = f."КлючФирмы";
    -- mstr := mstr || E' скомплектован и полностью оплачен. Готов к самовывозу.\r\n';
    mstr := format(E'%s скомплектован и полностью оплачен.\n 
Товар готов к самовывозу и находится на складе %s по адресу:
поселок Мурино (м. Девяткино), улица Ясная, дом 11.
Схема проезда по ссылке: https://www.kipspb.ru/upload/iblock/226/devyatkino_map.jpg\n
Товар можно приехать и получить без дополнительного звонка.\n
Для юридических лиц требуется печать (при условии подписи генерального директора или главного бухгалтера) или доверенность.\n
Время работы офиса и склада:
понедельник - пятница, с 9:00 до 18:00 без перерыва,\n
суббота с 9:00 до 16:00 без перерыва\n
Тел.: 8-812-327-327-4\n
Убедительная просьба забрать товар в течение 5 дней.
'
    , mstr, loc_firm_name);
    loc_msg_to := 0; -- 0 - клиенту, 2 - в файл, 1 - менеджеру

    cnt := r4d_sent_count(b."№ счета");
    _now := now(); -- DEBUG +'3 days'::INTERVAL;
    loc_last_reminder_ts := r4d_last_reminder_timestamp(b."№ счета");
    loc_last_interval := _now - loc_last_reminder_ts;

    loc_dbg_str := format('№ счета=%s, Дата счета=%s, сообщений=%s', b."№ счета", b."Дата счета", cnt);
    do_send := FALSE;
    IF cnt = 0 THEN
        RAISE NOTICE 'Send 1st reminder %', loc_dbg_str;
        do_send := TRUE;
    ELSIF cnt = 1 THEN -- there was 1st reminder
      RAISE NOTICE '== last_reminder=% / %' , loc_last_reminder_ts, loc_dbg_str;
      IF loc_last_interval >= '3 days'::INTERVAL 
      THEN
         RAISE NOTICE '=====2nd reminder::% / %', loc_last_interval, loc_dbg_str;
         do_send := TRUE;
      END IF;
    ELSIF cnt = 2 THEN -- there was 2nd reminder
      IF loc_last_interval >= '7 days'::INTERVAL 
      THEN
         RAISE NOTICE '######## ДозвонНТУ::% / %', loc_last_interval, loc_dbg_str;
      END IF; -- 7 days
    END IF;

    IF do_send THEN
        IF arg_real_send THEN
            loc_msg_status := 1;  -- send
        ELSE
            RAISE NOTICE 'TEST: NO send bill_no=% msg_to=%', b."№ счета", loc_msg_to;
        END IF;
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg, msg_type)
                    VALUES (b."№ счета", loc_msg_status, loc_msg_to, mstr, 5); -- 5 - готов к самовывозу
    END IF;

END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
