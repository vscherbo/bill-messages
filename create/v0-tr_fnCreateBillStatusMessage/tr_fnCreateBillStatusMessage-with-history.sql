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
