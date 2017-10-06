-- Table: bill_status_history

-- DROP TABLE bill_status_history;

CREATE TABLE bill_status_history
(
  id serial NOT NULL,
  changed timestamp without time zone DEFAULT clock_timestamp(),
  changes character varying,
  bill_no integer,
  msg_id integer,
  CONSTRAINT "PK_bills_status_history" PRIMARY KEY (id),
  CONSTRAINT "FK_Счета" FOREIGN KEY (bill_no)
      REFERENCES "Счета" ("№ счета") MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
)
WITH (
  OIDS=FALSE
);
ALTER TABLE bill_status_history
  OWNER TO arc_energo;
COMMENT ON TABLE bill_status_history
  IS 'Для хранения истории изменения статуса счёта.';
