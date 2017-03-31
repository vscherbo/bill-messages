-- Table: "СчетОчередьСообщений"

-- DROP TABLE "СчетОчередьСообщений";

CREATE TABLE "СчетОчередьСообщений"
(
  id serial NOT NULL,
  "№ счета" integer NOT NULL,
  msg_timestamp timestamp without time zone NOT NULL DEFAULT now(),
  msg_priority integer NOT NULL DEFAULT 0,
  msg_status integer NOT NULL DEFAULT 1, -- 0-sent, 1-new, 2-периодический, ...
  msg character varying,
  msg_count integer NOT NULL DEFAULT 0, -- Счётчик попыток отправки сообщения
  msg_to integer DEFAULT 0, -- 0 - "to client", 1 - "to manager"
  msg_problem character varying,
  msg_qid character varying(11),
  msg_type integer, -- Тип сообщения:...
  CONSTRAINT "PK_СчетОчередьСообщений" PRIMARY KEY (id),
  CONSTRAINT "FK_Счета" FOREIGN KEY ("№ счета")
      REFERENCES "Счета" ("№ счета") MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
)
WITH (
  OIDS=TRUE
);
ALTER TABLE "СчетОчередьСообщений"
  OWNER TO arc_energo;
COMMENT ON COLUMN "СчетОчередьСообщений".msg_status IS '0-sent, 1-new, 2-периодический, 
10 - sender address not found,  
11- SMTPServerDisconnected
12 - SMTPSenderRefused
13 - SMTPRecipientsRefused
14 - SMTPDataError
15 - SMTPConnectError
16 - SMTPHeloError
17 - SMTPAuthenticationError
18 - SMTPException
19 - rcpt_refused
3xx-5xx SMTPResponseException (SMTPResponseException.smtp_code)
996-КодРаботника IS NULL
997-empty or invalid email,
998-deferred,
999-delivered(квитанция)';
COMMENT ON COLUMN "СчетОчередьСообщений".msg_count IS 'Счётчик попыток отправки сообщения';
COMMENT ON COLUMN "СчетОчередьСообщений".msg_to IS '0 - "to client", 1 - "to manager"';
COMMENT ON COLUMN "СчетОчередьСообщений".msg_type IS 'Тип сообщения:
1 - статус счёта
2 - бланк-заказа
3 - бланк-заказа и квитанция
4 - счёт-факс';


-- Index: "idx_СчетОчередьСообщений_bill_no"

-- DROP INDEX "idx_СчетОчередьСообщений_bill_no";

CREATE INDEX "idx_СчетОчередьСообщений_bill_no"
  ON "СчетОчередьСообщений"
  USING btree
  ("№ счета");


-- Trigger: trg_msg_status_AU on "СчетОчередьСообщений"

-- DROP TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений";

CREATE TRIGGER "trg_msg_status_AU"
  AFTER UPDATE OF msg_status
  ON "СчетОчередьСообщений"
  FOR EACH ROW
  -- WHEN (((new.msg_status >= 10) AND (new.msg_status <> old.msg_status)))
  WHEN (new.msg_status <> old.msg_status)
  EXECUTE PROCEDURE "fntr_Сообщение_в_ДозвонНТУ"();
COMMENT ON TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений" IS 'При присвоении msg_status значения >= 10 (сообщение об ошибке или пришла квитанция о доставке) заносит сообщение в ДозвонНТУ';


