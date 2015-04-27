SELECT SUM(cnt_mgr)
FROM (
SELECT 
  "Сотрудники"."Имя",
  COUNT("Сотрудники"."Имя") as cnt_mgr
FROM 
  arc_energo."Счета", 
  arc_energo."Сотрудники"
WHERE 
  "Счета"."Хозяин" = "Сотрудники"."Менеджер" AND
  "Счета"."КодРаботника" IS NULL AND
  "Счета"."Дата счета" > '2014-04-01' AND
  "Счета"."фирма" <> 'АРКОМ' AND
  --"Счета"."Отменен" = 'f'
  "Счета"."Готов" = 't'
GROUP BY "Сотрудники"."Имя"
ORDER BY 2 DESC
) AS foo
;
