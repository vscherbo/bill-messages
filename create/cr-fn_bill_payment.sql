-- Function: fn_bill_payment(integer)

-- DROP FUNCTION fn_bill_payment(integer);

CREATE OR REPLACE FUNCTION fn_bill_payment(bill_no integer)
  RETURNS numeric AS
$BODY$SELECT 
    sum("ОплатыНТУ"."Сумма") AS "Оплачено"
FROM "ОплатыНТУ"
WHERE "ОплатыНТУ"."Счет" = $1
GROUP BY "ОплатыНТУ"."Счет";$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION fn_bill_payment(integer)
  OWNER TO arc_energo;
