--SELECT DISTINCT 
--  Имя
--FROM (
SELECT b."№ счета"
    ,b."Дата счета"
    ,f.Название AS Компания
    ,e.Имя МенеджерСчета
    ,e.email
FROM Счета b,
    Сотрудники e,
    Фирма f
WHERE 
  b.Отменен = 'f'
  AND b.Хозяин = e.Менеджер
  AND b.фирма = f.КлючФирмы
  AND b."Дата счета" > '2013-01-01'
  AND e.Имя LIKE 'Бонд%'
--  ) AS bfm
  ;
