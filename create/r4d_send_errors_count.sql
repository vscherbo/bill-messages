-- Function: r4d_send_errors_count(integer)

-- DROP FUNCTION r4d_send_errors_count(integer);

CREATE OR REPLACE FUNCTION r4d_send_errors_count(bill_no integer)
  RETURNS bigint AS
$BODY$
    SELECT COUNT(*) AS result FROM "СчетОчередьСообщений"
    WHERE 
        msg_type=5
        AND msg_status BETWEEN 10 AND 998 
        AND "№ счета" = bill_no;
$BODY$
  LANGUAGE sql VOLATILE
  COST 100;
ALTER FUNCTION r4d_send_errors_count(integer)
  OWNER TO arc_energo;
COMMENT ON FUNCTION r4d_send_errors_count(integer) IS 'Сколько было сбоев при отправке сообщений о готовности к самовывозу';
