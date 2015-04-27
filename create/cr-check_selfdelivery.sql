SELECT "№ счета",
       --"Дата счета",
        --Хозяин, 
        --fn_bill_payment("№ счета") AS Paym, 
        Сумма
FROM Счета
WHERE 
  Готов = 't'
  AND Отгружен = 'f'
  AND Отменен = 'f'
  AND Отгрузка = 'Самовывоз'
  AND Накладная IS NULL
  AND Фактура IS NULL
  AND фирма <> 'АРКОМ'
  AND "Дата счета" > '2014-06-01'
  AND Хозяин <> 91
  AND Сумма = fn_bill_payment("№ счета")
  ORDER BY "Дата счета"