CREATE OR REPLACE FUNCTION is_tester(a_emp_code INTEGER) RETURNS BOOLEAN AS
$BODY$DECLARE
loc_result BOOLEAN;
BEGIN

loc_result := a_emp_code IN (SELECT "КодРаботника" FROM emp_company
WHERE "Код" IN (250531,210282,210243,216453,233690,252638,231769,241625,255596,215789,253932,233038
,229233 -- ИП Карпов, Шалаевский
,245922 -- Р-Компонент, Хапёрский
,252836 -- ТПП ВВЦА, Алексеева
,254664 -- Промэлектрика, Барабаш
,231963 -- КИП-Сервис, Хапёрский
)
);  -- Работник связан с Кодом дилера-тестера

IF loc_result THEN
    RAISE NOTICE 'Shortlist КодРаботника=%', a_emp_code;
END IF;

RETURN loc_result;
            
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
