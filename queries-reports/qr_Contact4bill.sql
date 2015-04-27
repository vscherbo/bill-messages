SELECT eaddr, efio, email_from_Eaddr, email_from_FIO 
FROM (
SELECT  
e.КодРаботника
, e.ФИО efio
, regexp_matches(lower(e.ФИО), '([\w\-.]+@[\w\-.]+)', 'ig') AS email_from_FIO
, e.ЕАдрес AS eaddr
, regexp_matches(lower(e.ЕАдрес), '([\w\-.]+@[\w\-.]+)', 'ig') AS email_from_Eaddr
-- , e."Телефон"
FROM Работники e
WHERE 
  e.ЕАдрес IS NOT NULL
-- position('@' in e.ФИО) > 0
--LIMIT 800
 ) AS empl
WHERE
    email_from_Eaddr <> email_from_FIO
