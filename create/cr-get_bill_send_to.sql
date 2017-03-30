CREATE OR REPLACE FUNCTION get_bill_send_to(
                a_emp_code INTEGER,
                a_to_addr VARCHAR
) RETURNS VARCHAR AS
$BODY$DECLARE
    loc_to VARCHAR;
BEGIN
RAISE NOTICE 'get_bill_send_to a_emp_code=%, a_to_addr=%', a_emp_code, a_to_addr;

SELECT const_value INTO loc_to
FROM arc_constants WHERE const_name = 'autobill_msg_to'; -- в режиме отладки содержит email сотрудников через запятую

IF NOT FOUND THEN -- ошибка конфигурации, на задана настройка. Оповещение IT 
    loc_to := 'it@kipspb.ru'; 
ELSE
    IF 'to_client' = loc_to THEN -- стандартная настройка, to_client - зарезервированное слово
        IF a_emp_code IN (SELECT "КодРаботника" FROM emp_company WHERE "Код" IN
                                                                       (250531,210282,210243,216453,233690,252638,231769,241625)
                                                                       -- (-1)
                         ) THEN -- Работник связан с Кодом дилера-тестера
            loc_to := a_to_addr;
            RAISE NOTICE 'Shortlist КодРаботника=%, to_addr=%', a_emp_code, a_to_addr;
        ELSE -- Если не дилер-тестер, то заменяем получателя
            loc_to := 'arutyun@kipspb.ru,vscherbo@kipspb.ru';
        END IF;
    END IF;
END IF; -- NOT FOUND

RETURN loc_to;
            
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
