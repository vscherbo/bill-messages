SELECT 
   ФИО 
   ,Телефон
   ,Факс
   --, regexp_replace(regexp_replace(regexp_replace(regexp_replace(lower(Факс), '[\w\-.]+@[\w\-.]+', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g') AS clean_Fax
   --, regexp_matches(ФИО, '([\w\-. ]+@[\w\-. ]+)', 'i') AS email_from_FIO
  --, array_to_string(regexp_matches(lower(Факс), '[\w\-.]+@[\w\-.]+', 'i')    , ','  ) AS email_from_Fax
  
      --,Факс
   ,ЕАдрес
FROM
    Работники
WHERE
   ЕАдрес IS NULL
