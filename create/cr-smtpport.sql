CREATE OR REPLACE FUNCTION smtpport()
  RETURNS character varying AS
$BODY$
DECLARE
loc_production boolean;
loc_port integer := 25;
BEGIN
loc_production := pg_production();

IF loc_production THEN
    SELECT const_value::integer INTO loc_port FROM arc_constants WHERE const_name = 'smtp_port';
    IF NOT FOUND THEN
        loc_port := 25;
    ELSIF loc_port IS NULL THEN 
        loc_port := 25;
    END IF;
END IF;

RETURN loc_port;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
