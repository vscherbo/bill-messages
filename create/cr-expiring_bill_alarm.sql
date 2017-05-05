-- Function: expiring_bill_alarm()

-- DROP FUNCTION expiring_bill_alarm();

CREATE OR REPLACE FUNCTION expiring_bill_alarm()
  RETURNS void AS
$BODY$
INSERT INTO СчетОчередьСообщений ( "№ счета", msg, msg_to, msg_type ) 
    SELECT Счета."№ счета", '4-ый день ' AS msg, 1 AS msg_to, 11 
        FROM Резерв 
        INNER JOIN Счета ON Резерв.Счет = Счета."№ счета" 
        LEFT JOIN vwДилеры ON Счета.Код = vwДилеры.Код
        WHERE Счета."Дата счета" =(current_date-4)::timestamp without time zone 
            AND Резерв.КогдаСнял Is Null
            AND Счета.Оплата1=0
            AND vwДилеры.Код Is Null
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION expiring_bill_alarm()
  OWNER TO arc_energo;
