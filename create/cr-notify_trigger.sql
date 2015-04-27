-- Function: notify_trigger()

-- DROP FUNCTION notify_trigger();

CREATE OR REPLACE FUNCTION notify_trigger()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
 -- TG_TABLE_NAME is the name of the table who's trigger called this function
 -- TG_OP is the operation that triggered this function: INSERT, UPDATE or DELETE.
 execute 'NOTIFY ' || TG_TABLE_NAME || '_' || TG_OP;
 return new;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION notify_trigger()
  OWNER TO arc_energo;
