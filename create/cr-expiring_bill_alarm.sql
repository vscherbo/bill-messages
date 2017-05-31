-- Function: expiring_bill_alarm()

-- DROP FUNCTION expiring_bill_alarm();

CREATE OR REPLACE FUNCTION expiring_bill_alarm()
  RETURNS void AS
$BODY$
INSERT INTO СчетОчередьСообщений ( "№ счета", msg, msg_to, msg_type ) 
    SELECT DISTINCT Счета."№ счета",
           format(E'Добрый день,\nнапоминаем Вам, что истекает срок оплаты счёта %s от %s.\nСчёт действителен по %s (включительно).\nДля продления резерва и срока оплаты, при необходимости, свяжитесь с вашим менеджером.', to_char(Счета."№ счета", 'FM9999-9999'), to_char(Счета."Дата счета", 'YYYY-MM-DD'), (current_date + interval '1 day')::date) AS msg,
           -- 2 AS msg_to, 11 AS msg_type --debug msg_to=file
           -- production to_client
          0 AS msg_to, 11 AS msg_type
        FROM Резерв
        INNER JOIN Счета ON Резерв.Счет = Счета."№ счета"
        LEFT JOIN vwДилеры ON Счета.Код = vwДилеры.Код
        WHERE
            -- Счета."Дата счета" =(current_date-4)::timestamp without time zone
            bill_valid_until(Счета."Дата счета", 5) = current_date + interval '1 day'
            AND Резерв.КогдаСнял Is Null
            AND (Счета.Оплата1=0 OR Счета.Оплата1 Is Null)
            AND vwДилеры.Код Is Null
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION expiring_bill_alarm()
  OWNER TO arc_energo;
