-- Function: fn_bill_inetpayment(integer)

-- DROP FUNCTION fn_bill_inetpayment(integer);

CREATE OR REPLACE FUNCTION fn_bill_inetpayment(bill_no integer)
  RETURNS numeric AS
$BODY$
SELECT sum(amount) AS "Оплачено"
FROM inetpayments
WHERE order_id = (SELECT "ИнтернетЗаказ" FROM "Счета" WHERE "№ счета" = $1)
GROUP BY inetpayments.order_id;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION fn_bill_inetpayment(integer)
  OWNER TO arc_energo;
