create or replace function addsub( in i1 int, in i2 int, 
 out o1 int, out o2 int) as 
$$ 
return i1 + i2, i1-i2 
$$  language plpythonu; 

