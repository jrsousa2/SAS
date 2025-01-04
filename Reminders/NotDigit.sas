data test;
   do x='123','a','a1a','1a1', '1 1'; 
   y=notdigit(compress(x));
   put x= @10 y=;
  end;
run;