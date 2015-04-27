-- Function: "fnCreateBillStatusMessage"()

-- DROP FUNCTION "fnCreateBillStatusMessage"();

CREATE OR REPLACE FUNCTION "fnCreateBillStatusMessage"()
  RETURNS trigger AS
$BODY$DECLARE 
        mstr varchar(255);
        msg_processing varchar[3] := ARRAY[' Ожидает оплату.', ' Частичная оплата поступила.', ' 100% оплата поступила.']; -- starts with 1 
        --msg_ready varchar[3] := ARRAY[' Готов к самовывозу.', ' Отгружен через ', 'Квитанция № ']; 
BEGIN 
-- RAISE NOTICE 'OLD=% NEW=%', OLD.Статус, NEW.Статус  ; 
CASE NEW.Статус
    WHEN 3 THEN -- В работе
           mstr := 'Заказ комплектуется.' || msg_processing[ coalesce(OLD.Статус+1, 1) ];
--           RAISE NOTICE 'WHEN 3 mstr=%', mstr  ; 
    WHEN 6 THEN -- Скомплектован, ожидает оплату
           mstr := 'Заказ скомплектован, ожидает оплату.';
--           RAISE NOTICE 'WHEN 6 mstr=%', mstr  ; 
    WHEN 7 THEN -- Готов
           mstr := 'Заказ скомплектован и полностью оплачен.';
           IF upper(NEW.Отгрузка) = 'САМОВЫВОЗ' THEN mstr := mstr ||' Готов к самовывозу.';
           ELSEIF length(NEW.ОтгрузкаКем) > 0 THEN mstr := mstr || ' Отгружен: ' || NEW.ОтгрузкаКем ;
           END IF;
--           RAISE NOTICE 'WHEN 7 mstr=%', mstr  ; 
    ELSE mstr := '';
--         RAISE NOTICE 'ELSE mstr=%', mstr  ; 
END CASE;

--RAISE NOTICE 'After CASE mstr=%', mstr  ; 
-- debug mstr := mstr || ' old=' ||OLD.Статус ||  ' new=' ||NEW.Статус ;

IF length(mstr) > 0 THEN	
   INSERT INTO СчетОчередьСообщений("№ счета", msg) 
               values (NEW."№ счета",  mstr);
END IF;
RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateBillStatusMessage"()
  OWNER TO arc_energo;

