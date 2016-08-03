-- Function: fn_sendbillmsgparam(integer[])

-- DROP FUNCTION fn_sendbillmsgparam(integer[]);

CREATE OR REPLACE FUNCTION fn_sendbillmsgparam(a_msg_type integer[])
  RETURNS VOID AS
$BODY$DECLARE
BEGIN

    PERFORM fn_sendbillsinglemsg(id) FROM vwqueuedmsg WHERE msg_type = ANY(a_msg_type);

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION fn_sendbillmsgparam(integer[])
  OWNER TO arc_energo;
