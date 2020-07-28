CREATE OR REPLACE FUNCTION fntr_check_ignored()
  RETURNS trigger AS
$BODY$
DECLARE
brec record;
loc_ent_ignore boolean;
loc_action varchar;
loc_reason varchar;
BEGIN
    SELECT "Код", "Интернет", op INTO brec FROM "Счета" b
    WHERE b."№ счета" = NEW."№ счета";
    RAISE NOTICE 'brec=%', brec;

    PERFORM 1 FROM "СоотношениеСтатуса" s WHERE s."КодПредприятия" = brec."Код" AND s."СтатусПредприятия" = 14;
    loc_ent_ignore := FOUND;

    IF brec."Интернет" THEN -- по автосчетам оповещаем                           
        loc_action := 'put';                                                     
        loc_reason := 'по автосчетам оповещаем';                                          
    ELSIF loc_ent_ignore THEN -- статус 14 - отключаем оповещения                            
        NEW.msg_status := -99;                                                   
        loc_action := 'ignore';                                                  
        loc_reason := 'не оповещаем для СтатусПредприятия = 14';                                               
        NEW.msg_problem := loc_reason;                                                   
    ELSIF brec.op IN (30) THEN -- не оповещаем о счёте с такими значениями op 
        NEW.msg_status := -99;                                                   
        loc_action := 'ignore';                                                  
        loc_reason := format('не оповещаем о счёте со значением op=%s', brec.op);
        NEW.msg_problem := loc_reason;                                                   
    ELSE                                                                         
        loc_action := 'put';                                                     
        loc_reason := 'no reasons to ignore';                                                        
    END IF;     
    RAISE NOTICE '%', format('%s message NEW.№ счета=%s, NEW.msg_status=%s (%s)', loc_action, NEW."№ счета", NEW.msg_status, loc_reason);

    RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
