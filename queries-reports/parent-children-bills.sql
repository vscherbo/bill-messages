SELECT b."№ счета" AS parent, b."Дата счета", b.Отгружен parent_Отгружен
, b1."№ счета" AS child 
, b.Хозяин AS parent_mgr
, b1.Хозяин AS child_mgr
, b.КодРаботника AS parent_contact
, b1.КодРаботника AS child_contact
, b.фирма AS parent_firm
, b1.фирма AS child_firm
--, b1.Накладная child_Накладная
--, b1.Отгружен child_Отгружен
FROM Счета b
INNER JOIN Счета b1 ON b1.предок = b."№ счета"
WHERE b1."№ счета" <> b1.предок
--AND b."№ счета" = 12172140
AND b.Отменен = 'f'
AND b1.Накладная > '2014-01-01'
ORDER BY parent

