CREATE OR REPLACE FUNCTION smtphost()
  RETURNS character varying AS
$BODY$
DECLARE
loc_production boolean;
loc_smtp varchar := 'mail.arc.world';
BEGIN
loc_production := pg_production();

IF loc_production THEN
    SELECT const_value INTO loc_smtp FROM arc_constants WHERE const_name = 'smtp_host';
    IF NOT FOUND THEN
        loc_smtp := 'smtp.kipspb.ru';
    ELSIF loc_smtp IS NULL OR loc_smtp = '' THEN 
        loc_smtp := 'smtp.kipspb.ru';
    END IF;
END IF;

RETURN loc_smtp;

END;$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
