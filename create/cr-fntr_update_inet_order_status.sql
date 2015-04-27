-- Function: fntr_update_inet_order_status()

-- DROP FUNCTION fntr_update_inet_order_status();

CREATE OR REPLACE FUNCTION fntr_update_inet_order_status()
  RETURNS trigger AS
$BODY$DECLARE
  res varchar;
  run_out varchar;
  run_err varchar;
BEGIN
    SELECT *  INTO res, run_out, run_err FROM public.ssh_run(site(), 'uploader', './order-status-safe-update.php ' || NEW.io_id::VARCHAR || ' ' || NEW.io_status);
    -- RAISE NOTICE 'res=%, out=%, err=%', res, run_out, run_err;
    IF 'OK' = res THEN
        NEW.io_update_result := 0;
        NEW.io_update_msg := res;
    ELSE
        NEW.io_update_result := 1;
        NEW.io_update_msg := format('%s, out=%s, err=%s', res, run_out, run_err);
    END IF;
    NEW.io_update_timestamp := clock_timestamp();
    RETURN NEW;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fntr_update_inet_order_status()
  OWNER TO arc_energo;
