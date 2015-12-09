CREATE OR REPLACE FUNCTION is_bank_payment(bill_no integer)
  RETURNS boolean AS
$BODY$
BEGIN
RETURN EXISTS ( SELECT 1 FROM "ОплатыНТУ" p JOIN "Счета" b ON "№ счета" = "Счет" WHERE "Счет" = $1 AND "ПП№" IS NOT NULL ); 
--IF EXISTS ( SELECT 1 FROM "ОплатыНТУ" p JOIN "Счета" b ON "№ счета" = "Счет" WHERE "Счет" = $1 AND "ПП№" IS NOT NULL )
--THEN
--  RETURN True;
--ELSE
--  RETURN False;
--END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
