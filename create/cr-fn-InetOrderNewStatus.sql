-- Function: "fn_InetOrderNewStatus"(integer, numeric)

-- DROP FUNCTION "fn_InetOrderNewStatus"(integer, numeric);

CREATE OR REPLACE FUNCTION "fn_InetOrderNewStatus"(
    bill_status integer,
    inet_order_id numeric)
  RETURNS void AS
$BODY$DECLARE
    loc_inet_order_status CHARACTER(1);
BEGIN
    IF bill_status IS NULL THEN -- счёт создан
        loc_inet_order_status := 'O'; -- в обработке
    ELSIF 0 = bill_status THEN -- ожидает оплаты
        loc_inet_order_status := 'S'; -- ожидает оплаты
    ELSIF 2 = bill_status THEN -- оплачен
        loc_inet_order_status := 'A'; -- оплачен
    ELSIF 7 = bill_status THEN -- ожидает самовывоза
        loc_inet_order_status := 'G'; -- готов к самовывозу
    ELSIF 10 = bill_status THEN -- отправлен ТК
        loc_inet_order_status := 'D'; -- отгружен
    END IF;

    -- RAISE NOTICE 'loc_inet_order_status=%', loc_inet_order_status  ; 
    IF loc_inet_order_status IS NOT NULL 
    THEN
        INSERT INTO inet_orders_status_queue(io_id, io_status) VALUES(inet_order_id::INTEGER, loc_inet_order_status);
    END IF;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION "fn_InetOrderNewStatus"(integer, numeric)
  OWNER TO arc_energo;
