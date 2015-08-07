-- Function: "fntr_Счет_Статус_10"()

-- DROP FUNCTION "fntr_Счет_Статус_10"();

CREATE OR REPLACE FUNCTION "fntr_Счет_Статус_10"()
  RETURNS trigger AS
$BODY$BEGIN
  NEW."Статус" := 10;
  RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fntr_Счет_Статус_10"()
  OWNER TO arc_energo;
