-- Function: "fntr_Счет_Статус_10"()

-- DROP FUNCTION "fntr_Счет_Статус_10"();

CREATE OR REPLACE FUNCTION "fntr_Счет_Статус_10"()
  RETURNS trigger AS
$BODY$BEGIN
  -- NEW."Статус" := 10;
  UPDATE "Счета" SET "Статус" = 10, "Отгружен" = 't' WHERE "№ счета" = NEW."№ счета";
  -- RAISE NOTICE 'Status10: OLD=% NEW=%', OLD.Статус, NEW.Статус ;
  RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fntr_Счет_Статус_10"()
  OWNER TO arc_energo;
