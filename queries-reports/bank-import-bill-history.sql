SELECT bi.*, changed, changes, msg_id
FROM (SELECT 
 i.firma, i.Номер , i.Контрагент
 , i.Приход
 , p.Сумма , p.Счет
, b.Сумма AS bsum, b.Статус
FROM 
  БанкИмпорт i
INNER JOIN ОплатыНТУ p ON i.КодЗаписи = p.КодЗаписи
INNER JOIN  Счета b ON p.Счет = b."№ счета"
WHERE
(i.БанкСегодня BETWEEN '2014-04-24 00:00:00' AND '2014-04-24 23:59:59') AND i.firma IN ('КИПСПБ', 'ОСЗ') AND i.Субсчет = 'пр'
AND p.ДатаПоступления BETWEEN '2014-04-24 00:00:00' AND '2014-04-24 23:59:59'
--ORDER BY i.firma, i.Приход
) AS bi
INNER JOIN bill_status_history h ON bi.Счет = h.bill_no
WHERE h.changed BETWEEN '2014-04-24 00:00:00' AND '2014-04-24 23:59:59'
ORDER BY bill_no, changed