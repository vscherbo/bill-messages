-- Function: public.write_email(text, text, text, integer, text, text, text)

-- DROP FUNCTION public.write_email(text, text, text, integer, text, text, text);

CREATE OR REPLACE FUNCTION public.write_email(_from text, _password text, smtp text, port integer, receiver text, subject text, send_message text)
  RETURNS void AS
$BODY$
DECLARE 
message text;
BEGIN
message = concat('From: ', _from,
                 '\nTo: ', receiver,
                 '\nSubject: ', subject,
                 '\n\n ', send_message);

INSERT INTO email (ereceiver, esubject, emessage) VALUES (receiver, subject, message) ;

END
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.write_email(text, text, text, integer, text, text, text)
  OWNER TO arc_energo;
