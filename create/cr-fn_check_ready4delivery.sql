-- Function: fn_check_ready4delivery()

-- DROP FUNCTION fn_check_ready4delivery();

CREATE OR REPLACE FUNCTION fn_check_ready4delivery()
  RETURNS void AS
$BODY$DECLARE
    b RECORD;
    mstr varchar(255);
    loc_msg_to integer;
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
                    AND фирма <> 'АРКОМ'
                    AND "Дата счета" > '2014-06-01' 
                    AND Хозяин <> 91
                    AND Сумма = fn_bill_payment("№ счета")
    LOOP
        -- RAISE NOTICE '№ счета,=%', b."№ счета" ; 

        mstr := 'Напомните, пожалуйста, клиенту, что ';
        IF b.предок = b."№ счета" THEN
            mstr := 'заказ ' || to_char(b."№ счета", 'FM9999-9999');
        ELSE 
            mstr := 'заказ ' || to_char(b.предок, 'FM9999-9999') || '/' || to_char(b."№ счета", 'FM9999-9999');
        END IF;
        mstr := mstr || ' от ' || to_char(b."Дата счета", 'YYYY-MM-DD');

        mstr := mstr || ' скомплектован и полностью оплачен. Готов к самовывозу.';
        -- loc_msg_to := 2; -- в файл
        loc_msg_to := 1; -- менеджеру
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg) values (b."№ счета", 1, loc_msg_to, mstr);

    END LOOP;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_check_ready4delivery()
  OWNER TO arc_energo;
