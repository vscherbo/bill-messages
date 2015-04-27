SELECT nmsg.*, changed, changes
FROM (
SELECT bi.* --, msg, msg_status
FROM (SELECT 
 i.firma, i.Номер , i.Контрагент
 , i.Приход
 , p.Сумма , p.Счет
--, b.Сумма AS bsum, b.Статус
FROM 
  БанкИмпорт i
INNER JOIN ОплатыНТУ p ON i.КодЗаписи = p.КодЗаписи
--INNER JOIN  Счета b ON p.Счет = b."№ счета"
WHERE
(i.БанкСегодня BETWEEN '2014-04-21 00:00:00' AND '2014-04-21 23:59:59') AND i.firma IN ('КИПСПБ', 'ОСЗ', 'АРКОМ') AND i.Субсчет = 'пр'
AND p.ДатаПоступления BETWEEN '2014-04-21 00:00:00' AND '2014-04-21 23:59:59'
--ORDER BY i.firma, i.Приход
) AS bi
WHERE 
  bi.Счет 
   NOT IN (SELECT "№ счета" FROM СчетОчередьСообщений
   -- IN (SELECT "№ счета" FROM СчетОчередьСообщений
           WHERE
             msg_timestamp BETWEEN '2014-04-21 00:00:00' AND '2014-04-21 23:59:59'
             AND msg LIKE 'Заказ % оплачен.'
                  )
ORDER BY bi.Счет
) AS nmsg
-- INNER JOIN bill_status_history h ON nmsg.Счет = h.bill_no
, bill_status_history h 
WHERE 
 nmsg.Счет = h.bill_no
 AND h.changed BETWEEN '2014-04-21 00:00:00' AND '2014-04-21 23:59:59'
 -- для "правильных" сообщений   AND h.changes LIKE '%2;'
-- ORDER BY bill_no, changed, changes
ORDER BY Номер, changed, changes