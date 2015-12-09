CREATE OR REPLACE FUNCTION is_inet_payment(bill_no integer)
  RETURNS boolean AS
$BODY$
BEGIN
RETURN EXISTS ( SELECT 1 FROM inetpayments
                         WHERE order_id = (SELECT "ИнтернетЗаказ" FROM "Счета" WHERE "№ счета" = $1)
              );
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
