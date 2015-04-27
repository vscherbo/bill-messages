SELECT COUNT(*), Имя  AS Менеджер
FROM
(SELECT 
  b."Оплачен", 
  b."Отгружен", 
  b."Отгрузка", 
  b."ОтгрузкаКем", 
  e."Имя",
  b."Хозяин"
FROM 
  "Счета" b,
  --Работники c,
  "Сотрудники" e
WHERE 
  b.Отменен <> 'f' AND 
  b."Дата счета" > '2013-01-01' AND 
  b."Интернет" = 'f' AND 
  --b."КодРаботника" = c.КодРаботника AND
  b."КодРаботника" IS NULL AND 
  --b."Оплачен" = 't' AND 
  --b."Отгружен" = 'f' AND
  b."Хозяин" = e."Менеджер" AND
  --c.ЕАдрес IS NULL AND 
  b.Код <> 223719
ORDER BY
  b."Дата счета" ASC ) AS no_contacts
  GROUP BY Имя
  ORDER BY 2
  ;
