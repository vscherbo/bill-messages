-- Table: "СчетОчередьСообщений"

-- DROP TABLE "СчетОчередьСообщений";

CREATE TABLE "СчетОчередьСообщений"
(
  id serial NOT NULL,
  "№ счета" integer NOT NULL,
  msg_timestamp timestamp without time zone NOT NULL DEFAULT now(),
  msg_priority integer NOT NULL DEFAULT 0,
  msg_status integer NOT NULL DEFAULT 1, -- 0-sent, 1-new клиенту, 2-new менеджеру
  msg_count integer NOT NULL DEFAULT 0, -- Счётчик попыток отправки сообщения
  msg_to integer NOT NULL DEFAULT 0, -- 0 - "to client", 1 - "to manager"
  msg character varying,
  msg_problem character varying,
  CONSTRAINT "PK_СчетОчередьСообщений" PRIMARY KEY (id),
  CONSTRAINT "FK_Счета" FOREIGN KEY ("№ счета")
      REFERENCES "Счета" ("№ счета") MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=TRUE
);
ALTER TABLE "СчетОчередьСообщений"
  OWNER TO arc_energo;
COMMENT ON COLUMN "СчетОчередьСообщений".msg_status IS '0-sent, 1-new клиенту, 2-new менеджеру 
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
997-empty or invalid email,
998-delayed,
999-delivered(квитанция)';
COMMENT ON COLUMN "СчетОчередьСообщений".msg_count IS 'Счётчик попыток отправки сообщения';

