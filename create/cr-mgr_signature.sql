-- Function: mgr_signature(integer)

-- DROP FUNCTION mgr_signature(integer);

CREATE OR REPLACE FUNCTION mgr_signature(a_bill_no integer)
  RETURNS varchar AS
$BODY$DECLARE
-- OLD loc_msg_post_common VARCHAR = E'\r\n\r\nНа все Ваши вопросы Вам ответит Ваш персональный менеджер:\r\n';
loc_msg_post_common VARCHAR = E'\r\n\r\nНа все Ваши вопросы Вам ответит Ваш персональный менеджер:';
loc_msg_post varchar ;
loc_msg_post_mobile varchar ;
loc_mgr_addr varchar ;
loc_mgr_name varchar ;
loc_firm_name varchar ;    
loc_firm_phone varchar ;    
loc_ext_phone VARCHAR;
loc_mob_phone VARCHAR;
BEGIN

SELECT * FROM bill_mgr_attrs(a_bill_no) INTO loc_mgr_addr, loc_mgr_name, loc_firm_name, loc_firm_phone, loc_ext_phone, loc_mob_phone;

/**
loc_msg_post_mobile := E'моб.т./WhatsApp/Viber: ' || loc_mob_phone || E'\r\n';
loc_msg_post := loc_msg_post_common
        || loc_mgr_name
        || E', e-mail: ' || loc_mgr_addr || E',\r\n'
        || E'телефон:  ' || loc_firm_phone || ', доб. '|| loc_ext_phone || E'\r\n'
        || COALESCE(loc_msg_post_mobile, E'')
        || E'С уважением,\r\n' 
        || loc_firm_name;
**/


loc_msg_post := format(E'%s\r\n%s, e-mail: %s,\r\nтелефон: %s, доб. %s\r\nмоб.т./WhatsApp/Viber: %s\r\nС уважением,\r\n%s', loc_msg_post_common, loc_mgr_name, loc_mgr_addr, loc_firm_phone, loc_ext_phone, COALESCE(loc_mob_phone, E''), loc_firm_name);

RETURN loc_msg_post;      
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION sendbillsinglemsg(integer)
  OWNER TO arc_energo;
