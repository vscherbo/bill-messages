-- Function: r4d_last_reminder_timestamp(integer)

-- DROP FUNCTION r4d_last_reminder_timestamp(integer);

CREATE OR REPLACE FUNCTION r4d_last_reminder_timestamp(bill_no integer)
  RETURNS timestamp without time zone AS
$BODY$
    SELECT msg_timestamp AS result
    FROM "СчетОчередьСообщений"
    WHERE 
        msg_type=5
        AND "№ счета" = bill_no
    ORDER BY msg_timestamp DESC
    LIMIT 1;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION r4d_last_reminder_timestamp(integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION r4d_last_reminder_timestamp(integer) IS 'момент последнего оповещения о готовности к самовывозу';
