-- Function: "fntr_Сообщение_в_ДозвонНТУ"()

-- DROP FUNCTION "fntr_Сообщение_в_ДозвонНТУ"();

CREATE OR REPLACE FUNCTION "fntr_Сообщение_в_ДозвонНТУ"()
  RETURNS trigger AS
$BODY$
DECLARE DT TIMESTAMP WITHOUT TIME ZONE;
BEGIN
    --RAISE NOTICE 'IN trigger function fntr_Сообщение_в_ДозвонНТУ';
    DT := now();
    INSERT INTO "ДозвонНТУ"(
            "Счет", "Дата", "КтоЗвонил", "КомуПередал", "Примечание")
            -- tips)
    VALUES (NEW."№ счета", DT, 'робот', (SELECT email_to FROM send_email_result e WHERE e.qid=NEW.msg_qid LIMIT 1), NEW.msg);
            -- ?);
    -- UPDATE "Счета" SET "Уведомили" = DT WHERE "№ счета" = NEW."№ счета";
    RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fntr_Сообщение_в_ДозвонНТУ"()
  OWNER TO arc_energo;
