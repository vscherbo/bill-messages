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
        delivery integer;
        loc_msg_to integer;
        -- loc_msg_status integer := 998; -- deferred while debug period
        loc_msg_status integer := 1;
        TA_Name varchar;
        msg_processing varchar[3] := ARRAY[' Ожидает оплату.', ' Частичная оплата поступила.', ' 100% оплата поступила.']; -- starts with 1 
        --msg_ready varchar[3] := ARRAY[' Готов к самовывозу.', ' Отгружен через ', 'Квитанция № ']; 
BEGIN 
-- RAISE NOTICE 'OLD=% NEW=%', OLD.Статус, NEW.Статус  ; 
CASE NEW.Отгрузка
    WHEN 'Самовывоз' THEN
         delivery := 1 ;
    WHEN 'Курьер заказчика' THEN
         delivery := 1 ;
    WHEN 'Отправка' THEN
         delivery := 2 ;
    WHEN 'Отправка курьерской сл.' THEN
         delivery := 2 ;
    WHEN 'Почтой' THEN
         delivery := 2 ;
    ELSE delivery := 0;
--         RAISE NOTICE 'Wrong delivery=%', NEW.Отгрузка ; 
END CASE;


IF NEW.предок = NEW."№ счета" THEN
   mstr := 'Заказ ' || NEW."№ счета";
ELSE 
   mstr := 'Заказ ' || NEW.предок || '/' || NEW."№ счета";
END IF;

loc_msg_to := 2; -- в файл, если ниже не заданое иное
CASE NEW.Статус
    WHEN 1 THEN
           mstr := mstr || ' частично оплачен.';
--           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 2 THEN
           mstr := mstr || ' полностью оплачен.';
           loc_msg_to := 0; -- клиенту
--           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 6 THEN -- Менеджеру: Скомплектован, ожидает оплату
           mstr := mstr || ' скомплектован, ожидает оплату.';
           loc_msg_to := 1; -- менеджеру
--           RAISE NOTICE 'WHEN 6 mstr=%', mstr  ; 
    WHEN 7 THEN 
           IF delivery = 1 THEN -- если самовывоз
              mstr := mstr || ' скомплектован и полностью оплачен. Готов к самовывозу.';
              -- НО НЕ Москва, Вахромеева, код 91
              IF NEW.Хозяин = 91 THEN mstr := '';
              END IF;
           ELSE mstr := ''; -- если НЕ самовывоз
           END IF;
--           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 10 THEN 
           IF delivery = 2 THEN -- отправлен через ТК/Почта/Курьерская служба
              IF NEW.КодТК IS NOT NULL THEN
                 SELECT Наименование INTO TA_Name FROM vwТранспортныеКомпании WHERE NEW.КодТК = КодТК ;
              ELSE TA_Name := NEW.ОтгрузкаКем ;
              END IF; -- КодТК
              mstr := mstr || ' отправлен: ' || TA_Name;
              IF NEW.ДокТК IS NOT NULL THEN
                 mstr := mstr || ', № документа:' || NEW.ДокТК;
              END IF; -- ДокТК
              IF NEW.ДокТКДата IS NOT NULL THEN
                 mstr := mstr || ' от ' || NEW.ДокТКДата ;
              END IF; -- ДокТКДата
              -- mstr := mstr || ' отправлен: ' || TA_Name || ', № документа:' || NEW.ДокТК || ' от ' || NEW.ДокТКДата ;
           ELSE mstr := ''; -- НЕ ТК/Почта/Курьерская служба
           END IF;
--           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    ELSE mstr := '';
--         RAISE NOTICE 'ELSE mstr=%', mstr  ; 
END CASE;
--RAISE NOTICE 'After CASE mstr=%', mstr  ; 
-- debug mstr := mstr || ' old=' ||OLD.Статус ||  ' new=' ||NEW.Статус ;

IF length(mstr) > 0 THEN
   WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg) values (NEW."№ счета", loc_msg_status, loc_msg_to, mstr) RETURNING id
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
