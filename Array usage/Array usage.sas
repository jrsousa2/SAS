/** COUNTS HOW MANY VALUES FROM 6405 COLS ARE IN A GIVEN RANGE **/
data stu2.x;
   set stu2.saida4;
   /* ARRAY */
   array conta{6405} col1-col6405;

   cont1=0;
   cont2=0;
   do i=1 to 6405;
      cont1=cont1+(-1.104000<=conta{i}<=6.005000);
      cont2=cont2+(-1.397813<=conta{i}<=7.097871);
   end;

   perc1=cont1/6405;
   perc2=cont2/6405;
   keep cont1 cont2 Replicate perc1 perc2;
   label Replicate="";
   format perc1 perc2 12.5;
run;
