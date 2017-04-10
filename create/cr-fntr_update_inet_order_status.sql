-- Function: fntr_update_inet_order_status()

-- DROP FUNCTION fntr_update_inet_order_status();

CREATE OR REPLACE FUNCTION fntr_update_inet_order_status()
  RETURNS trigger AS
$BODY$DECLARE
cmd character varying;
res_exec RECORD;
loc_io_update_result INTEGER;
loc_io_update_msg VARCHAR;
loc_io_update_timestamp timestamp without time zone;
loc_site VARCHAR := 'kipspb-fl.arc.world';
BEGIN
loc_site := site();

cmd := format(E'php $ARC_PATH/order-status-safe-update.php %s %s', NEW.io_id::VARCHAR, NEW.io_status);
IF cmd IS NULL
THEN
    RAISE NOTICE 'update_inet_order_status cmd IS NULL';
ELSE
    res_exec := public.exec_paramiko(loc_site, 22, 'uploader'::VARCHAR, cmd);

    IF res_exec.err_str <> ''
    THEN
       loc_io_update_result := 1;
       loc_io_update_msg := format('ERROR: cmd=%s, out=%s, err=%s, site=%s', cmd, res_exec.out_str, res_exec.err_str, loc_site);
    ELSE
       loc_io_update_result := 0;
       loc_io_update_msg := loc_site || ' updated';
    END IF;
    loc_io_update_timestamp := clock_timestamp();
END IF;

UPDATE inet_orders_status_queue
SET 
    io_update_result = loc_io_update_result
    , io_update_msg = loc_io_update_msg
    , io_update_timestamp = loc_io_update_timestamp
WHERE id=NEW.id;

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_update_inet_order_status()
  OWNER TO arc_energo;
