SELECT 'UPDATE Работники SET ЕАдрес='||em1||','||em2||' WHERE КодРаботника='||КодРаботника||';'
FROM
(SELECT КодРаботника, ФИО, ЕАдрес, regexp_replace(trim(email[1]), '(.*?)([\w\-\.]+@[\w\-\.]+)>', '\2') AS em1 
, regexp_replace(trim(email[2]), '(.*)([\w\-\.]+@[\w\-\.]+)>', '\2') AS em2
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
) em1em2
 WHERE
 em1<>em2
;
