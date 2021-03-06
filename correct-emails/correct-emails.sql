UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, '¬', '@') 
WHERE position('¬' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, ' @ ', '@') 
WHERE position(' @ ' in ЕАдрес) > 0;	

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, '@ ', '@') 
WHERE position('@ ' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ФИО=regexp_replace(ФИО, ' *@ *', '@', 'g') 
WHERE ФИО ~* ' *@ *';

UPDATE 
Работники 
SET ФИО=regexp_replace(ФИО, ' *\. *', '.', 'g') 
WHERE ФИО ~* '[\w\-\. ]+@[\w\-\. ]+';

UPDATE 
Работники 
SET ЕАдрес=array_to_string(regexp_matches(lower(ФИО), '([\w\-.]+@[\w\-.]+)', 'i'), ','), 
    ФИО=regexp_replace(regexp_replace(regexp_replace(regexp_replace(ФИО, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g') 
WHERE (ЕАдрес IS NULL) AND (ФИО ~* '[\w\-\.]+@[\w\-\.]+');

UPDATE 
Работники
SET 
 ЕАдрес = ЕАдрес ||','|| array_to_string(regexp_matches(lower(ФИО), '([\w\-.]+@[\w\-.]+)', 'i'), ','),
 ФИО=regexp_replace(regexp_replace(regexp_replace(regexp_replace(ФИО, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
WHERE ФИО ~* '[\w\-\.]+@[\w\-\.]+';

UPDATE 
Работники
SET 
  ЕАдрес = array_to_string(regexp_matches(lower(Телефон), '[\w\-.]+@[\w\-.]+', 'i') , ','),
  Телефон = regexp_replace(regexp_replace(regexp_replace(regexp_replace(Телефон, '[\w\-.]+@[\w\-.]+', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
WHERE ЕАдрес IS NULL AND Телефон ~* '[\w\-\.]+@[\w\-\.]+';

UPDATE 
Работники
SET 
  ЕАдрес = ЕАдрес ||','|| array_to_string(regexp_matches(lower(Телефон), '[\w\-.]+@[\w\-.]+', 'i'), ','),
  Телефон = regexp_replace(regexp_replace(regexp_replace(regexp_replace(Телефон, '[\w\-.]+@[\w\-.]+', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
WHERE Телефон ~* '[\w\-\.]+@[\w\-\.]+';

UPDATE 
Работники
SET 
  ЕАдрес=array_to_string(regexp_matches(lower(Факс), '([\w\-.]+@[\w\-.]+)', 'i'), ','),
  Факс=regexp_replace(regexp_replace(regexp_replace(regexp_replace(Факс, '([\w\-.]+@[\w\-.]+)', ''), '\(\)', '', 'g'), '<>', '', 'g'), '\s+', ' ', 'g')
WHERE ЕАдрес IS NULL AND Факс ~* '[\w\-\.]+@[\w\-\.]+';

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, '@@', '@', 'g') 
WHERE ЕАдрес ~* '@@';

UPDATE 
Работники 
SET ЕАдрес='rootoaosvet@vladimir.su' 
WHERE ЕАдрес = 'rootoaosvet,vladimir,su';

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, 'mailto:', '', 'ig') 
WHERE position('mailto:' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, ' и ', ',', 'ig') 
WHERE position(' и ' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, ' или ', ',', 'ig') 
WHERE position(' или ' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ЕАдрес=regexp_replace(ЕАдрес, ';', ',', 'ig') 
WHERE position(';' in ЕАдрес) > 0;

UPDATE 
Работники 
SET ЕАдрес=trim(regexp_replace(ЕАдрес, '[\s]{2,}', ' ', 'ig')) 
WHERE ЕАдрес ~* '[\s]{2,}';

UPDATE 
Работники 
SET ЕАдрес=trim(ЕАдрес) 
WHERE ЕАдрес <> trim(ЕАдрес);

SELECT dupl_emails();

UPDATE 
Работники 
SET Примечание = ЕАдрес, ЕАдрес = NULL 
WHERE ЕАдрес !~* '.*@.*' AND Примечание IS NULL;

UPDATE 
Работники 
SET Примечание = Примечание || ', ' || ЕАдрес, ЕАдрес = NULL 
WHERE ЕАдрес !~* '.*@.*' AND Примечание IS NOT NULL;

UPDATE 
Работники 
SET ЕАдрес = regexp_replace(ЕАдрес, '(\w)[:\.][ ]*(.*)\.@([a-zA-Z]{2,7})', '\1@\2.\3') 
WHERE ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})';

UPDATE 
Работники 
SET ЕАдрес = replace(ЕАдрес, ',', '.') 
WHERE ЕАдрес ~* '.*@.*,ru$';

-- "мусор" в Примечание
UPDATE 
Работники 
SET Примечание = ЕАдрес, ЕАдрес = NULL 
WHERE ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})' AND Примечание IS NULL;

UPDATE 
Работники 
SET ЕАдрес = regexp_replace(ЕАдрес, '(.*)\s+(<.+@.+>)(.*)', '"\1\3" \2', 'g') 
WHERE ЕАдрес ~* '.*\s+<.+@.+>' AND ЕАдрес !~* '".*"\s+<.+@.+>';

-- следующие 2 подряд
UPDATE Работники 
SET 
ЕАдрес=regexp_replace(ЕАдрес, '(.*[, .]+)([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', '\2')
,Примечание=Примечание || ', ' || regexp_replace(ЕАдрес, '(.*[, .]+)([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})', '\1')
WHERE 
ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})(,)([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})'
AND ЕАдрес !~* '(".*"[ <]*([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7}))'
AND ЕАдрес ~* ',';

UPDATE Работники 
SET 
ЕАдрес=regexp_replace(ЕАдрес, '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})(.*)', '\1')
WHERE 
ЕАдрес !~* '([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})([, ]+)([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7})'
AND ЕАдрес !~* '(".*"[ <]*([\w\-+]+(?:\.[\w\-+]+)*@(?:[\w\-]+\.)+[a-zA-Z]{2,7}))'
AND ЕАдрес ~* ',';
-- 2



