SELECT 
(date_trunc('day', changed) - ДокТКДата) AS "Дельта"
, ДокТКДата "ДокТКДата    "
 ,changed AS "Дата сообщения"
-- ,date_trunc('day', changed) "Дата сообщения"
, Наименование
 , bill_no AS "№ счета     "
FROM
  Счета b
JOIN bill_status_history h ON bill_no = "№ счета"
JOIN vwТранспортныеКомпании t ON b.КодТК = t.КодТК
WHERE 
  ДокТКДата >= '2014-07-24'
AND changes LIKE '%=10;'
AND (date_trunc('day', changed) - ДокТКДата) > '3 days'::interval
ORDER BY 
-- ДокТКДата, Наименование
"Дельта" DESC
