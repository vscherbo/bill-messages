-- Table: inet_orders_status_queue

-- DROP TABLE inet_orders_status_queue;

CREATE TABLE inet_orders_status_queue
(
  id serial NOT NULL,
  ios_timestamp timestamp without time zone DEFAULT now(), -- Дата-время помещения в очередь
  io_id integer, -- Номер (id) интернет-заказа
  io_status character(1), -- Новый статус
  io_update_result integer, -- Результат обновления на сайте: 0-успешно
  io_update_timestamp timestamp without time zone, -- Дата-время операции обновления на сайте.
  io_update_msg character varying,
  CONSTRAINT "ios_queue_PK" PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE inet_orders_status_queue
  OWNER TO arc_energo;
COMMENT ON COLUMN inet_orders_status_queue.ios_timestamp IS 'Дата-время помещения в очередь';
COMMENT ON COLUMN inet_orders_status_queue.io_id IS 'Номер (id) интернет-заказа';
COMMENT ON COLUMN inet_orders_status_queue.io_status IS 'Новый статус';
COMMENT ON COLUMN inet_orders_status_queue.io_update_result IS 'Результат обновления на сайте: 0-успешно';
COMMENT ON COLUMN inet_orders_status_queue.io_update_timestamp IS 'Дата-время операции обновления на сайте.';

CREATE TRIGGER "tr_inet_order_status_AI" AFTER INSERT
   ON inet_orders_status_queue FOR EACH ROW
   EXECUTE PROCEDURE arc_energo.fntr_update_inet_order_status();
