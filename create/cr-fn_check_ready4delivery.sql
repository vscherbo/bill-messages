-- Function: fn_check_ready4delivery()

-- DROP FUNCTION fn_check_ready4delivery();

CREATE OR REPLACE FUNCTION fn_check_ready4delivery()
  RETURNS void AS
$BODY$DECLARE
    b RECORD;
    mstr varchar(255);
    loc_msg_to integer;
    cnt INTEGER;
    do_send BOOLEAN := FALSE;
    _now TIMESTAMP WITHOUT TIME ZONE;
    loc_last_interval INTERVAL;
    loc_last_reminder_ts TIMESTAMP WITHOUT TIME ZONE;
    loc_dbg_str TEXT;
BEGIN
FOR b IN SELECT "№ счета", "Дата счета", предок, Сумма
    FROM Счета
    WHERE 
        Готов = 't'
        AND Отгружен = 'f'
        AND Отменен = 'f'
        AND Отгрузка = 'Самовывоз'
        AND Накладная IS NULL
        AND Фактура IS NULL
        AND "Дата счета" > '2014-06-01' 
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

    mstr := mstr || E' скомплектован и полностью оплачен. Готов к самовывозу.\r\n';
    loc_msg_to := 0; -- клиенту, 2 - в файл, 1 - менеджеру

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
      RAISE NOTICE '=== last_reminder=% / %' , loc_last_reminder_ts, loc_dbg_str;
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
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg, msg_type)
                                  VALUES (b."№ счета", 1, loc_msg_to, mstr, 5); -- 5 - готов к самовывозу
    END IF;

END LOOP;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_check_ready4delivery()
  OWNER TO arc_energo;
