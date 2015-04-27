SELECT e.Имя
,f.Предприятие
, q."№ счета"  --, q.msg_status
FROM 
vwDeferredMsg q, Сотрудники e, Счета b, Предприятия f
WHERE e.Менеджер = q."№ счета"/1000000
AND q.msg_status = 996
AND q."№ счета" = b."№ счета"
AND b.Код = f.Код
ORDER BY e.ФИО, q."№ счета"
