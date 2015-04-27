SELECT "Дельта", count("Дельта")
FROM
(SELECT 
 date_trunc('day', changed) "Дата сообщения"
 , bill_no AS "№ счета     "
 , ДокТКДата "ДокТКДата    "
,(date_trunc('day', changed) - ДокТКДата) "Дельта"
FROM
  Счета b
JOIN bill_status_history h ON bill_no = "№ счета"
WHERE 
  ДокТКДата >= '2014-07-01'
AND changes LIKE '%=10;'
--ORDER BY "Дельта" DESC
) AS Deltas
GROUP BY "Дельта"
ORDER BY 1 DESC