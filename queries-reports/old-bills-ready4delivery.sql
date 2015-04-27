SELECT "№ счета", предок,
                "Дата счета",
                fn_bill_payment("№ счета") AS Платежи, 
                Сумма,
                e.ФИО
            FROM Счета,
            Сотрудники e
            WHERE 
                Готов = 't'
                AND Отгружен = 'f'
                AND Отменен = 'f'
                AND Отгрузка = 'Самовывоз'
                AND Накладная IS NULL
                AND Фактура IS NULL
                AND фирма <> 'АРКОМ'
                AND "Дата счета" > '2013-01-01' -- Debug only
                AND "Дата счета" < '2014-07-01' -- Debug only
                AND Хозяин <> 91
                AND Сумма = fn_bill_payment("№ счета")
                AND Хозяин = e.Менеджер
ORDER BY "№ счета"