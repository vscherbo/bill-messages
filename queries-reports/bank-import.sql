SELECT 
 i.firma, i.Номер , i.Контрагент
 --, i.Основание
 , i.Приход
 , p.Сумма , p.Счет
--, p.ДатаПП, p.ДатаПоступления
, b.Сумма, b.Статус
--, q.msg, q.msg_status
--, h.changed, h.changes
FROM 
  БанкИмпорт i
INNER JOIN ОплатыНТУ p ON i.КодЗаписи = p.КодЗаписи
INNER JOIN  Счета b ON p.Счет = b."№ счета"
--INNER JOIN СчетОчередьСообщений q ON p.Счет = q."№ счета"
--INNER JOIN bill_status_history h ON q.id = h.msg_id
WHERE
(i.БанкСегодня BETWEEN '2014-04-24 00:00:00' AND '2014-04-24 23:59:59') AND i.firma IN ('КИПСПБ', 'ОСЗ') AND i.Субсчет = 'пр'
AND p.ДатаПоступления BETWEEN '2014-04-24 00:00:00' AND '2014-04-24 23:59:59'
--AND q.msg_timestamp BETWEEN '2014-04-17 00:00:00' AND '2014-04-17 23:59:59'
--AND q.msg_status <> 998

--AND q.msg_status = 998
--AND h.changed BETWEEN '2014-04-17 00:00:00' AND '2014-04-17 23:59:59'
--AND q.id IS NULL
--ORDER BY h.changes

--AND p.Счет IN
--(SELECT bill_no
--FROM bill_status_history
--WHERE changed BETWEEN '2014-04-17 00:00:00' AND '2014-04-17 23:59:59')

--(SELECT "№ счета"
--FROM СчетОчередьСообщений
--WHERE msg_timestamp BETWEEN '2014-04-17 00:00:00' AND '2014-04-17 23:59:59' 
--AND msg_status = 998
--)
ORDER BY 
--p.Счет
i.firma, i.Приход
--i.Номер
