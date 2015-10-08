-- Function: "fnCreateBillStatusMessage"()

-- DROP FUNCTION "fnCreateBillStatusMessage"();

CREATE OR REPLACE FUNCTION "fnCreateBillStatusMessage"()
  RETURNS trigger AS
$BODY$DECLARE 
        mstr varchar(255);
        order_str varchar(255);
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
        url_str varchar;
        SendMode INTEGER;
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


mstr := 'Заказ ';
IF NEW.предок = NEW."№ счета" THEN
   order_str := to_char(NEW."№ счета", 'FM9999-9999');
ELSE 
   order_str := to_char(NEW.предок, 'FM9999-9999') || '/' || to_char(NEW."№ счета", 'FM9999-9999');
END IF;
order_str := order_str || ' от ' || to_char(NEW."Дата счета", 'YYYY-MM-DD');
mstr := mstr || order_str;

IF NEW.Статус = 10 THEN -- отгружен
   SendMode := NEW.Статус; -- посылать всем
ELSIF NEW."Интернет" OR (NEW."Код" = 223719) THEN -- ИнтернетЗаказ ИЛИ Физ. лицо
   SendMode := -1; -- см. ниже CASE .. ELSE mstr := ''; НЕ посылать
ELSE
   SendMode := NEW.Статус;
END IF;

loc_msg_to := 2; -- в файл, если ниже не заданое иное
CASE SendMode -- NEW.Статус
    WHEN 1 THEN
            mstr := mstr || ' частично оплачен.'; -- RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 2 THEN
            -- mstr := mstr || ' полностью оплачен.';
            mstr := 'Поступила оплата по счету ' || order_str ;
            loc_msg_to := 0; -- клиенту
            -- RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 6 THEN -- Менеджеру: Скомплектован, ожидает оплату
            mstr := mstr || ' скомплектован, ожидает доплату.';
            loc_msg_to := 1; -- менеджеру -- RAISE NOTICE 'WHEN 6 mstr=%', mstr  ; 
    -- WHEN 7 THEN
           -- loc_msg_to := 1; -- менеджеру
--           IF delivery = 1 THEN -- если самовывоз
--              mstr := mstr || ' скомплектован и полностью оплачен. Готов к самовывозу.';
              -- НО НЕ Москва, Вахромеева, код 91
--              IF NEW.Хозяин = 91 THEN mstr := '';
--              END IF;
--           ELSE mstr := ''; -- если НЕ самовывоз
--           END IF;
--           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ; 
    WHEN 10 THEN 
            loc_msg_to := 0; -- клиенту
            IF delivery = 2 THEN -- отправлен через ТК/Почта/Курьерская служба
                mstr := mstr || ' отправлен: ' ;
                IF NEW.КодТК IS NOT NULL THEN 
                    SELECT Наименование INTO TA_Name FROM vwТранспортныеКомпании WHERE NEW.КодТК = КодТК ;
                    mstr := mstr || TA_Name;
                END IF; -- КодТК
                IF NEW.ДокТК IS NOT NULL THEN mstr := mstr || ', № документа:' || NEW.ДокТК;
                END IF; -- ДокТК
                IF NEW.ДокТКДата IS NOT NULL THEN mstr := mstr || ' от ' || NEW.ДокТКДата ;
                END IF; -- ДокТКДата
                -- для Деловых линий и Автотрединга добавляем ссылку (URL)
                IF (TA_Name IS NOT NULL) AND (NEW.ДокТК IS NOT NULL) AND (NEW.ДокТКДата IS NOT NULL) THEN
-- Заказ 55181155 отправлен: Автотрейдинг, № документа:спбп-04699 от 2014-04-24\nОтследить состояние доставки Вы можете по <a href=\"http://kipspb.ru/exp_mod/ae5000_invoicenumber.php?date=01.04.2014&number=%D1%81%D0%BF%D0%B1%D0%BF-00019\">ссылке</a>
                    CASE NEW.КодТК
                        WHEN 4 THEN
                            url_str := E'\r\nОтследить состояние доставки Вы можете по <a href=\"http://kipspb.ru/exp_mod/ae5000_invoicenumber.php?date=' || to_char(NEW.ДокТКДата, 'DD.MM.YYYY') || E'&number=' || NEW.ДокТК || E'\">ссылке</a>\r\n';
                        WHEN 6 THEN
                            url_str := E'\r\nОтследить состояние доставки Вы можете по <a href=\"http://kipspb.ru/exp_mod/dellin.php?number=' || NEW.ДокТК || E'\">ссылке</a>\r\n';
                        ELSE url_str = '';
                    END CASE;
                    mstr := mstr || url_str ;
                END IF; -- URL
            ELSE mstr := ''; -- НЕ ТК/Почта/Курьерская служба
            END IF; --           RAISE NOTICE 'WHEN % mstr=%', NEW.Статус, mstr  ;  
    ELSE mstr := ''; -- !!! see SendMode := -1
END CASE;
--RAISE NOTICE 'After CASE mstr=%', mstr  ; 
-- debug mstr := mstr || ' old=' ||OLD.Статус ||  ' new=' ||NEW.Статус ;

IF length(mstr) > 0 THEN
   WITH inserted AS (
        INSERT INTO СчетОчередьСообщений ("№ счета", msg_status, msg_to, msg) values (NEW."№ счета", loc_msg_status, loc_msg_to, mstr) RETURNING id
   )
   SELECT id INTO message_id FROM inserted;
END IF;

-- В очередь обновления статуса для Инет заказов с нашего сайта
IF NEW."ИнтернетЗаказ" > 7000 AND NEW."ИнтернетЗаказ" < 19999 THEN -- грубое отсечение нашего сайта от других площадок
    -- RAISE NOTICE 'NEW."ИнтернетЗаказ"=%', NEW."ИнтернетЗаказ"  ; 
    PERFORM "fn_InetOrderNewStatus"(NEW."Статус", NEW."ИнтернетЗаказ");
END IF;

-- log changed fields into bill_status_history
changes := '';
FOR fld IN SELECT column_name FROM information_schema.columns WHERE table_schema='arc_energo' AND table_name='Счета' LOOP
   EXECUTE 'SELECT ($1)."' || fld.column_name || '"::text' INTO newfld USING NEW; 
   EXECUTE 'SELECT ($1)."' || fld.column_name || '"::text' INTO oldfld USING OLD; 
   -- RAISE NOTICE 'fld=%::old=%, new=%', fld.column_name, oldfld, newfld  ; 
   IF (newfld is null) THEN newfld := 'NULL'; END IF;
   IF (oldfld is null) THEN oldfld := 'NULL'; END IF;
   IF (newfld <> oldfld) THEN
      changes := changes || 'OLD.' || fld ||'=' || oldfld || '/NEW.' || fld || '=' || newfld || ';' ;
      -- RAISE NOTICE 'CHANGED!!! %', changes ; 
   END IF;
END LOOP;

INSERT INTO bill_status_history(bill_no, changes, msg_id)  VALUES(NEW."№ счета", changes, message_id);

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fnCreateBillStatusMessage"()
  OWNER TO arc_energo;
