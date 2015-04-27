-- Function: "fnCreateBillStatusMessage"()

-- DROP FUNCTION "fnCreateBillStatusMessage"();

CREATE OR REPLACE FUNCTION "fnCreateBillStatusMessage"()
  RETURNS trigger AS
$BODY$DECLARE 
        mstr varchar(255);
        changes varchar;
        fld record;
        oldfld text;
        newfld text;
        message_id integer;
        TA_Name varchar;
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
           IF upper(NEW.Отгрузка) = 'САМОВЫВОЗ' THEN mstr := 'Заказ скомплектован и полностью оплачен. Готов к самовывозу.';
           -- (moved to 10) ELSEIF length(NEW.ОтгрузкаКем) > 0 THEN mstr := mstr || ' Будет отправлен: ' || NEW.ОтгрузкаКем ;
           END IF;
--           RAISE NOTICE 'WHEN 7 mstr=%', mstr  ; 
    WHEN 10 THEN -- Отгружен
           IF upper(NEW.Отгрузка) <> 'САМОВЫВОЗ' AND NEW.КодТК IS NOT NULL THEN 
                                                  -- length(NEW.ОтгрузкаКем) > 0 THEN 
                                                  -- NEW.КодТК IS NOT NULL THEN 
              SELECT Наименование INTO TA_Name FROM vwТранспортныеКомпании WHERE NEW.КодТК = КодТК ;
              mstr := 'Заказ отгружен: ' || TA_Name || ', № документа:' || NEW.ДокТК || ' от ' || NEW.ДокТКДата ;
              -- mstr := 'Заказ отгружен: ' || NEW.ОтгрузкаКем ;
           END IF;
--           RAISE NOTICE 'WHEN 10 mstr=%', mstr  ; 
    ELSE mstr := '';
--         RAISE NOTICE 'ELSE mstr=%', mstr  ; 
END CASE;

--RAISE NOTICE 'After CASE mstr=%', mstr  ; 
-- debug mstr := mstr || ' old=' ||OLD.Статус ||  ' new=' ||NEW.Статус ;

IF length(mstr) > 0 THEN
   WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg) values (NEW."№ счета",  mstr) RETURNING id
   )
   SELECT id INTO message_id FROM inserted;
END IF;
-- log changed fields into bill_status_history
changes := '';
FOR fld IN SELECT column_name FROM information_schema.columns WHERE table_schema='arc_energo' AND table_name='Счета' LOOP
   EXECUTE 'SELECT ($1)."' || fld.column_name || '"::text' INTO newfld USING NEW; 
   EXECUTE 'SELECT ($1)."' || fld.column_name || '"::text' INTO oldfld USING OLD; 
   --RAISE NOTICE 'fld=%::old=%, new=%', fld.column_name, oldfld, newfld  ; 
   IF newfld <> oldfld THEN
      changes := changes || 'OLD.' || fld ||'=' || oldfld || '/NEW.' || fld || '=' || newfld || ';' ;
      --RAISE NOTICE 'CHANGED!!! %', changes ; 
   END IF;
END LOOP;

INSERT INTO bill_status_history(bill_no, changes, msg_id)  VALUES(NEW."№ счета", changes, message_id);

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateBillStatusMessage"()
  OWNER TO arc_energo;
