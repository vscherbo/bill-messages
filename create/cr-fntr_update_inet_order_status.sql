-- Function: fntr_update_inet_order_status()

-- DROP FUNCTION fntr_update_inet_order_status();

CREATE OR REPLACE FUNCTION fntr_update_inet_order_status()
  RETURNS trigger AS
$BODY$DECLARE
cmd character varying;
res_exec RECORD;
loc_site VARCHAR := 'kipspb-fl.arc.world';
BEGIN

cmd := format(E'php $ARC_PATH/order-status-safe-update.php %s %s', NEW.io_id::VARCHAR, NEW.io_status);
IF cmd IS NULL
THEN
    RAISE NOTICE 'update_inet_order_status cmd IS NULL';
ELSE
    res_exec := public.exec_paramiko(loc_site, 22, 'uploader'::VARCHAR, cmd);

    IF res_exec.err_str <> ''
    THEN
       NEW.io_update_result := 1;
       NEW.io_update_msg := format('ERROR: cmd=%s, out=%s, err=%s', cmd, res_exec.out_str, res_exec.err_str);
    ELSE
       NEW.io_update_result := 0;
       NEW.io_update_msg := 'kipspb.ru updated';
    END IF;
    NEW.io_update_timestamp := clock_timestamp();
END IF;

RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_update_inet_order_status()
  OWNER TO arc_energo;
