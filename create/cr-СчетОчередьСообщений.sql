-- Table: "СчетОчередьСообщений"

-- DROP TABLE "СчетОчередьСообщений";

CREATE TABLE "СчетОчередьСообщений"
(
  id serial NOT NULL,
  "№ счета" integer NOT NULL,
  msg_timestamp timestamp without time zone NOT NULL DEFAULT clock_timestamp(),
  msg_priority integer NOT NULL DEFAULT 0,
  msg_status integer NOT NULL DEFAULT 1, -- 0-sent, 1-new, 2-периодический, ...
  msg character varying,
  msg_count integer NOT NULL DEFAULT 0, -- Счётчик попыток отправки сообщения
  msg_to integer DEFAULT 0, -- 0 - "to client", 1 - "to manager"
  msg_problem character varying,
  msg_qid character varying(11),
  msg_type integer, -- Тип сообщения:...
  msg_subj character varying, -- тема (subject) сообщения
  msg_sent_to character varying,
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
4 - счёт-факс
5 - готов к самовывозу (разновидность 1)
6 - запрос акта сверки
7 - отправка акта сверки
8 - заказ получен
9 - оповещение менеджера о создании автосчёта
11 - истекает срок оплаты счёта';
COMMENT ON COLUMN "СчетОчередьСообщений".msg_subj IS 'тема (subject) сообщения';


-- Index: "idx_СчетОчередьСообщений_bill_no"

-- DROP INDEX "idx_СчетОчередьСообщений_bill_no";

CREATE INDEX "idx_СчетОчередьСообщений_bill_no"
  ON "СчетОчередьСообщений"
  USING btree
  ("№ счета");

-- Index: "idx_СчетОчередьСообщений_qid"

-- DROP INDEX "idx_СчетОчередьСообщений_qid";

CREATE INDEX "idx_СчетОчередьСообщений_qid"
  ON "СчетОчередьСообщений"
  USING btree
  (msg_qid COLLATE pg_catalog."default");


-- Trigger: trg_msg_status_AU on "СчетОчередьСообщений"

-- DROP TRIGGER "trg_msg_status_AU" ON "СчетОчередьСообщений";

CREATE TRIGGER "trg_msg_status_AU"
  AFTER UPDATE OF msg_status, msg_sent_to
  ON "СчетОчередьСообщений"
  FOR EACH ROW
  WHEN (((old.msg_status IS NULL) OR (new.msg_status <> old.msg_status) OR (old.msg_sent_to IS NULL)))
  EXECUTE PROCEDURE "fntr_СообщениеОбновлено"();


