-- Function: msg_bill_of_5th_day()

-- DROP FUNCTION msg_bill_of_5th_day();

CREATE OR REPLACE FUNCTION msg_bill_of_5th_day()
  RETURNS void AS
$BODY$INSERT INTO СчетОчередьСообщений ( "№ счета", msg, msg_to, msg_type ) SELECT Счета.
"№ счета", '5-ый день ' AS msg, 1 AS msg_to, 11 FROM Резерв INNER JOIN Счета 
ON Резерв.Счет = Счета."№ счета" WHERE Счета."Дата счета" =(current_date-5)::timestamp without time zone 
AND Резерв.КогдаСнял Is Null ORDER BY Счета."Дата счета";
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION msg_bill_of_5th_day()
  OWNER TO arc_energo;
