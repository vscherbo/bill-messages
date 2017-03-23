CREATE OR REPLACE FUNCTION get_bill_send_to(
                a_emp_code INTEGER,
                a_to_addr VARCHAR
) RETURNS VARCHAR AS
$BODY$DECLARE
    loc_to VARCHAR;
BEGIN

SELECT const_value INTO loc_to
FROM arc_constants WHERE const_name = 'autobill_msg_to';

IF NOT FOUND THEN 
    loc_to := 'it@kipspb.ru'; 
ELSE
    IF 'to_client' = loc_to THEN -- to_client is reserved word
        IF a_emp_code IN (SELECT "КодРаботника" FROM emp_company WHERE "Код" IN
                                                                       -- (250531,210282,210243,216453,233690,252638)
                                                                       (-1)
                         ) THEN -- short dealers list 
            loc_to := a_to_addr; -- overwrite to_addr value FROM arc_constants
        ELSE
            loc_to := 'arutyn@kipspb.ru,vscherbo@kipspb.ru';
        END IF;
    END IF;
END IF; -- NOT FOUND

RETURN loc_to;
            
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
