--SELECT emp.КодРаботника, em, regexp_matches(trim(emp.ЕАдрес), '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', 'i') AS email1
--FROM 
--  Работники emp, (
SELECT КодРаботника, ФИО, ЕАдрес
--,array_to_string(regexp_matches(trim(ЕАдрес), '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', 'ig'), ',') AS em 
--,regexp_replace(ЕАдрес, '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', '\1', 'i') AS em1 
--,regexp_replace(trim(email[2]), '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7}) ', '\1', 'gi') AS em2
--, regexp_replace(trim(email[2]), '(.*?)([\w\-\.]+@[\w\-\.]+[a-zA-Z]{2,7})(.*)', '\2', 'gi') AS em2
--,string_to_array(e.ЕАдрес, ',') as email
FROM 
  Работники e
WHERE 
  --ЕАдрес ~* '([\w\-\.]+@[\w\-\.]+){3,}' 
  e.ЕАдрес ~* '(.*@.*@.*)'
  -- AND e.ЕАдрес !~* '(.*@.*,.*@)'
  -- AND e.КодРаботника= 188992
  ORDER BY e.КодРаботника
--  ) AS emails
--  WHERE emails.КодРаботника = emp.КодРаботника
;
