CREATE OR REPLACE FUNCTION get_bill_send_to(
                a_emp_code INTEGER,
                a_to_addr VARCHAR
) RETURNS VARCHAR AS
$BODY$DECLARE
    loc_to VARCHAR;
BEGIN
RAISE NOTICE 'get_bill_send_to a_emp_code=%, a_to_addr=%', a_emp_code, a_to_addr;

IF a_emp_code IN (SELECT "КодРаботника" FROM emp_company WHERE "Код" IN
(250531,210282,210243
,216453 -- ИП Гомон, Антипин
,233690,252638,231769,241625,255596,215789,253932,233038
,229233 -- ИП Карпов, Шалаевский
,245922 -- Р-Компонент, Хапёрский
,252836 -- ТПП ВВЦА, Алексеева
,254664 -- Промэлектрика, Барабаш
,231963 -- КИП-Сервис, Хапёрский
)
) THEN -- Работник связан с Кодом дилера-тестера
    loc_to := a_to_addr;
    RAISE NOTICE 'Shortlist КодРаботника=%, to_addr=%', a_emp_code, a_to_addr;
ELSE -- ТОЛЬКО до запуска автосчетов: Если не дилер-тестер, то заменяем получателя
    loc_to := 'arutyun@kipspb.ru';
END IF;

RETURN loc_to;
            
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
