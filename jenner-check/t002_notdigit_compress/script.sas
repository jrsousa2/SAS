/* Byte-identical to Reminders/NotDigit.sas in jrsousa2/SAS.        */
/* Added a trailing PROC PRINT so the run produces an observable    */
/* listing (the original just wrote to the log via PUT).            */

data test;
   do x='123','a','a1a','1a1', '1 1';
   y=notdigit(compress(x));
   put x= @10 y=;
  end;
run;

proc print data=test noobs;
run;
