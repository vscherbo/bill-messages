--SELECT 'UPDATE Работники SET ЕАдрес='||em1||','||em2||' WHERE КодРаботника='||КодРаботника||';' FROM (
SELECT КодРаботника, ФИО, ЕАдрес
--, lower(regexp_replace(trim(email[1]), '(.*?)([a-z0-9\-\.]+)@([a-z0-9\-\.]+)', '\2@\3', 'g')) AS em1 
, regexp_replace(lower(trim(email[1])), '(.*?)([\w\-\.]+@[\w\.-]+)(.*)', '\2', 'gi') AS em1
, regexp_replace(lower(trim(email[2])), '(.*?)([\w\-\.]+@[\w\-\.]+[a-zA-Z]{2,7})(.*)', '\2', 'gi') AS em2
FROM
(SELECT 
  e.КодРаботника
  ,e.ФИО
  ,e.ЕАдрес
  ,string_to_array(e.ЕАдрес, ',') as email
FROM 
  Работники e
WHERE 
  --ЕАдрес ~* '([\w\-\.]+@[\w\-\.]+){3,}' 
  e.ЕАдрес ~* '(.*@.*,.*@)'
  ORDER BY e.КодРаботника
  ) emails
--) em1em2 WHERE em1<>em2
;
