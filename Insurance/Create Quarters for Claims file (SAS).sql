%Epic;

%macro Qtrs;
data Qtrs;
%do Year=2006 %to 2019;
 %do Qtr=1 %to 4;
	 Month=mdy(3*&Qtr,1,&year);
     Next_Mo=intnx("month",Month,1)-1;
	 End_Date=Next_Mo;
	 count=0;
	 do until(count=2);
	   if weekday(End_Date)=6
	      then count=count+1;
	   if count<2 then End_Date=End_Date-1;
	 end;
	 Acctg_Yr=&Year;
	 Acctg_Qtr=&Qtr;
     Cut_Off=mdy(3*Acctg_Qtr,1,Acctg_Yr);
     Acct_YYYYMM=100*Acctg_Yr+3*Acctg_Qtr;
	 Aux=End_Date;
     if 100*Acctg_Yr+Acctg_Qtr in (201804,201902)
	    then output;
 %end;
%end;
format Month Next_Mo End_Date Aux Cut_Off yymmdd10.;
drop count;
run;
%mend;
%Qtrs;

/* Create begin cut-offs for MTD pull */
%let Beg_Date=14609;/* EQUIVALE A "01jan2000"-1*/
data Qtrs2;
	retain Month Next_Mo Beg_Date End_Date;
	set Qtrs;
	format Beg_Date yymmdd10.;
	Beg_Date=coalesce(1*symget("Beg_Date")+1,month);
	call symput("Beg_Date",End_Date);
	Acctg_Yr=year(month);
	Acctg_Qtr=ceil(month(month)/3);
	Acctg_Quarter=put(year(Month),z4.)||"Q"||put(ceil(month(Month)/3),z1.);
run;

