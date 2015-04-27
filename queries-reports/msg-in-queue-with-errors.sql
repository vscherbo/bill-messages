SELECT 
b."№ счета"
, e.ФИО, e.ЕАдрес, length(e.ЕАдрес)
--, f.Предприятие
FROM 
   Счета b
 , Работники e
--, Предприятия f
WHERE 
  b.КодРаботника = e.КодРаботника
   --AND e.Код = f.Код
  AND e.ЕАдрес IS NOT NULL
 AND b."№ счета" IN (SELECT "№ счета" FROM СчетОчередьСообщений 
                     WHERE msg_status > 0 AND msg_status < 998 AND msg_count <= 3)
