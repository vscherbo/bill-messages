SELECT 
 Наименование
 , COUNT(*)
FROM
(SELECT 
  КодТК AS tcode
FROM
  Счета
WHERE
  КодТК IS NOT NULL
  AND "Дата счета" > '2014-01-01' ) AS TK2014
JOIN vwТранспортныеКомпании t ON tcode = t.КодТК
GROUP BY Наименование
ORDER BY 2 DESC