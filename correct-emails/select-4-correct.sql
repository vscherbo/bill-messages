SELECT
ЕАдрес,regexp_replace(ЕАдрес, '¬', '@') 
FROM 
Работники 
WHERE position('¬' in ЕАдрес) > 0;

SELECT
ЕАдрес,regexp_replace(ЕАдрес, ' @ ', '@') 
FROM 
Работники 
WHERE position(' @ ' in ЕАдрес) > 0;	

SELECT
ЕАдрес,regexp_replace(ЕАдрес, '@ ', '@') 
FROM 
Работники 
WHERE position('@ ' in ЕАдрес) > 0;

SELECT
ФИО,regexp_replace(ФИО, ' +@ +', '@', 'g') 
FROM 
Работники 
WHERE ФИО ~* ' +@ +';

SELECT
ФИО,regexp_replace(ФИО, ' *\. *', '.', 'g') 
FROM 
Работники 
WHERE ФИО ~* '[\w\-\. ]+@[\w\-\. ]+';

SELECT
ЕАдрес,array_to_string(regexp_matches(lower(ФИО), '([\w\-.]+@[\w\-.]+)', 'i'), ','), 
    ФИО,regexp_replace(regexp_replace(regexp_replace(regexp_replace(ФИО, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g') 
FROM 
Работники 
WHERE (ЕАдрес IS NULL) AND (ФИО ~* '[\w\-\.]+@[\w\-\.]+');

SELECT
 ЕАдрес , ЕАдрес ||','|| array_to_string(regexp_matches(lower(ФИО), '([\w\-.]+@[\w\-.]+)', 'i'), ','),
 ФИО,regexp_replace(regexp_replace(regexp_replace(regexp_replace(ФИО, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
FROM 
Работники
WHERE ФИО ~* '[\w\-\.]+@[\w\-\.]+';

SELECT
  ЕАдрес , array_to_string(regexp_matches(lower(Телефон), '[\w\-.]+@[\w\-.]+', 'i') , ','),
  Телефон , regexp_replace(regexp_replace(regexp_replace(regexp_replace(Телефон, '[\w\-.]+@[\w\-.]+', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
FROM 
Работники
WHERE ЕАдрес IS NULL AND Телефон ~* '[\w\-\.]+@[\w\-\.]+';

SELECT
  ЕАдрес , ЕАдрес ||','|| array_to_string(regexp_matches(lower(Телефон), '[\w\-.]+@[\w\-.]+', 'i'), ','),
  Телефон , regexp_replace(regexp_replace(regexp_replace(regexp_replace(Телефон, '[\w\-.]+@[\w\-.]+', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
FROM 
Работники
WHERE Телефон ~* '[\w\-\.]+@[\w\-\.]+';

SELECT
  ЕАдрес,array_to_string(regexp_matches(lower(Факс), '([\w\-.]+@[\w\-.]+)', 'i'), ','),
  Факс,regexp_replace(regexp_replace(regexp_replace(regexp_replace(Факс, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
FROM 
Работники
WHERE ЕАдрес IS NULL AND Факс ~* '[\w\-\.]+@[\w\-\.]+';

SELECT
ЕАдрес,regexp_replace(ЕАдрес, '@@', '@', 'g') 
FROM 
Работники 
WHERE ЕАдрес ~* '@@';

SELECT
ЕАдрес,'rootoaosvet@vladimir.su' 
FROM 
Работники 
WHERE ЕАдрес =  'rootoaosvet,vladimir,su';

SELECT
ЕАдрес,regexp_replace(ЕАдрес, 'mailto:', '', 'ig') 
FROM 
Работники 
WHERE position('mailto:' in ЕАдрес) > 0;

SELECT
ЕАдрес,regexp_replace(ЕАдрес, ' и ', ',', 'ig') 
FROM 
Работники 
WHERE position(' и ' in ЕАдрес) > 0;

SELECT
ЕАдрес,regexp_replace(ЕАдрес, ' или ', ',', 'ig') 
FROM 
Работники 
WHERE position(' или ' in ЕАдрес) > 0;

SELECT
ЕАдрес,regexp_replace(ЕАдрес, ';', ',', 'ig') 
FROM 
Работники 
WHERE position(';' in ЕАдрес) > 0;

SELECT
ЕАдрес,trim(regexp_replace(ЕАдрес, '[\s]{2,}', ' ', 'ig')) 
FROM 
Работники 
WHERE ЕАдрес ~* '[\s]{2,}';

SELECT
ЕАдрес,trim(ЕАдрес) 
FROM 
Работники 
WHERE ЕАдрес <> trim(ЕАдрес);

SELECT
Примечание , ЕАдрес, ЕАдрес , NULL 
FROM 
Работники 
WHERE ЕАдрес !~* '.*@.*' AND Примечание IS NULL;

SELECT
Примечание , Примечание || ', ' || ЕАдрес, ЕАдрес , NULL 
FROM 
Работники 
WHERE ЕАдрес !~* '.*@.*' AND Примечание IS NOT NULL;

SELECT
ЕАдрес , regexp_replace(ЕАдрес, '(\w)[:\.][ ]*(.*)\.@([a-zA-Z]{2,7})', '\1@\2.\3') 
FROM 
Работники 
WHERE ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})';

SELECT
ЕАдрес , replace(ЕАдрес, ',', '.') 
FROM 
Работники 
WHERE ЕАдрес ~* '.*@.*,ru$';

SELECT
Примечание , ЕАдрес, ЕАдрес , NULL 
FROM 
Работники 
WHERE ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})' AND Примечание IS NULL;

SELECT
ЕАдрес , regexp_replace(ЕАдрес, '(.*)\s+(<.+@.+>)(.*)', '"\1\3" \2', 'g') 
FROM 
Работники 
WHERE ЕАдрес ~* '.*\s+<.+@.+>' AND ЕАдрес !~* '".*"\s+<.+@.+>';

-- SELECT
-- ЕАдрес 
-- FROM 
-- Работники 
-- WHERE ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})' ;

SELECT
КодРаботника
,ЕАдрес
--, Примечание
--, regexp_replace(ЕАдрес, '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})(.*)', '\1')
FROM 
Работники 
WHERE 
ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})([, ]+)([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})'
AND ЕАдрес !~* '(".*"[ <]*([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7}))'
AND ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})'
--AND ЕАдрес ~* ','
