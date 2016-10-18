-- Function: fn_check_ready4delivery()

-- DROP FUNCTION fn_check_ready4delivery();

CREATE OR REPLACE FUNCTION fn_check_ready4delivery()
  RETURNS void AS
$BODY$DECLARE
    b RECORD;
    mstr varchar(255);
    loc_msg_to integer;
    msg_sent_count INTEGER;
BEGIN
    FOR b IN SELECT "№ счета",
                    "Дата счета",
                    -- Хозяин, 
                    -- fn_bill_payment("№ счета") AS Paym, 
                    предок,
                    Сумма
                FROM Счета
                WHERE 
                    Готов = 't'
                    AND Отгружен = 'f'
                    AND Отменен = 'f'
                    AND Отгрузка = 'Самовывоз'
                    AND Накладная IS NULL
                    AND Фактура IS NULL
                    -- AND фирма <> 'АРКОМ' -- физ. лица будут получать уведомления с 2015-12-08
                    AND "Дата счета" > '2014-06-01' 
                    AND Хозяин <> 91
                    -- AND Сумма = fn_bill_payment("№ счета")
                    AND ( Сумма = fn_bill_payment("№ счета") OR Сумма = fn_bill_inetpayment("№ счета") )
    LOOP
        -- RAISE NOTICE '№ счета,=%', b."№ счета" ; 

        mstr := E'';
        IF b.предок = b."№ счета" THEN
            mstr := mstr || E'Заказ ' || to_char(b."№ счета", 'FM9999-9999');
        ELSE 
            mstr := mstr || E'Заказ ' || to_char(b.предок, 'FM9999-9999') || '/' || to_char(b."№ счета", 'FM9999-9999');
        END IF;
        mstr := mstr || E' от ' || to_char(b."Дата счета", 'YYYY-MM-DD');

        -- mstr := mstr || E' скомплектован и полностью оплачен. Готов к самовывозу. \r\nЕсли это не так, сообщите об этом в отдел ИТ.';
        mstr := mstr || E' скомплектован и полностью оплачен. Готов к самовывозу.\r\n';
        -- loc_msg_to := 2; -- в файл
        -- loc_msg_to := 1; -- менеджеру
        loc_msg_to := 0; -- клиенту

        /** fast patch for endless messages **/
        SELECT COUNT(*) INTO msg_sent_count FROM "СчетОчередьСообщений"
        WHERE 
            msg_type=5
            -- AND msg_status=999 
            AND "№ счета" = b."№ счета";
        IF msg_sent_count < 3 THEN
            INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg, msg_type)
                   VALUES (b."№ счета", 1, loc_msg_to, mstr, 5); -- 5 - готов к самовывозу
        END IF; -- less than 3
    END LOOP;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_check_ready4delivery()
  OWNER TO arc_energo;
