-- Function: dupl_emails()

-- DROP FUNCTION dupl_emails();

CREATE OR REPLACE FUNCTION dupl_emails()
  RETURNS integer AS
$BODY$DECLARE 
  eaddr record;
  em1 varchar;
  em2 varchar;
  emails varchar;
BEGIN
 FOR eaddr IN SELECT КодРаботника, ЕАдрес FROM Работники WHERE ЕАдрес ~* '(.*@.*@)' LOOP
 --FOR eaddr IN SELECT КодРаботника, ЕАдрес FROM Работники WHERE ЕАдрес ~* '(.*lazareva.*@.*@)' LOOP
    -- emails := '';
    em1 := array_to_string(regexp_matches(eaddr.ЕАдрес, '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', 'i'), '');
    emails = em1 ;
    em2 := trim(replace(eaddr.ЕАдрес, em1, ''));
     --RAISE NOTICE 'em1=%___em2=%', em1, em2;
    IF position('@' in em2) > 0 THEN
       em2 := trim(array_to_string(regexp_matches(em2, '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', 'i'), ''));
       emails := em1 || ',' || em2;
       -- RAISE NOTICE 'Two=%', emails;
    ELSIF em2 = '<>,' OR em2 = ',' OR em2 = '<>' THEN NULL; -- emails := em1;
    ELSIF position('<>' in em2) > 0 THEN emails := trim(replace(em2, '<>', '<' || em1 || '>'), ',');
    END IF;
    --RAISE NOTICE 'UPDATE Работники SET ЕАдрес = % WHERE КодРаботника = %', emails, eaddr.КодРаботника;
    UPDATE Работники
    SET ЕАдрес = emails
    WHERE КодРаботника = eaddr.КодРаботника;
 END LOOP;
 RETURN 0;
END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION dupl_emails()
  OWNER TO arc_energo;
