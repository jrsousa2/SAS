/* LOADS AND STACKS FILES PROC IMPORTED INTO TABLES */
/* FILES HAVE THE SAME LAYOUT BUT PROC IMPORT DOESN'T CONTROL TYPES OF THE COLS */
/* THEREFORE A MACRO IS NEEDED TO CHECK WHICH COLS HAVE CONFLICTING TYPES */
%macro update1;
options validvarname = v7 mprint;
/* FILES TO LOAD */
%let arq1=AAIC;
%let arq2=INIC;
%let arq3=MICGIC;
%let arq4=NGIC;
%let arq5=NGPIC;
%let arq6=PRAIC;
%let arq7=QBEIC;
%let arq8=QBESP;
%let as_of_date=07-31-19;

%let Aba1=Paid;
%let Aba2=Reserves;

%do i=1 %to 8;
%do j=1 %to 2;
/* data */
%let Arq=Ryan_NonMga_&&arq&i.._&&Aba&j;
%let Tab=&&Aba&j;
%let Fullname=&as_of_date - &&arq&i...xlsx;
%let Path=/16actcorp/i804745/Ryan/201907;
%let Exist=%sysfunc(fileexist("&Path/&Fullname"));
%put ### Path=&Fullname Exist: &exist;

%if %eval(&Exist)
	%then %do;
		/* I ONLY HAD TO APPEND SEP/2016 */
		proc import out=&Arq
		 datafile="&Path/&Fullname" dbms=xlsx replace;
		 sheet="ITD &Tab";
		run;

		%let vars=zzz_&Arq;
        proc contents data=&Arq out=&Vars(keep=memname name type length nobs varnum format) noprint;
        run;

		%let Cmds=;
		%let Varis=;
		proc sql noprint;
		select trim(name)||"="||trim(name)||"-21916;" 
		,trim(name) as Nome
        into :Cmds separated by " ",:Varis separated by " "
		from &vars
		where upcase(name) in ('CHECK_DATE','FILE_ACTIVITY_DATE') 
        and format="BEST";
		quit;

		data &Arq;
		 retain obs 0;
		 length File $8. Tab $13.;
		 set &Arq;
		 obs=obs+1;
		 File="&&arq&i";
		 Tab="&Tab";
		 &Cmds;
		 /* FORMAT */
		 %if &varis ne %str()
		     %then format &varis yymmdd10.;;
		 rename File_Activity__Date=File_Activity_Date Claim__=Claim
         idemnity_reserve_amount=Indemnity_reserve_amount;
		run;
	%end;
%end;
%end;
options validvarname = any;
%mend;
%update1;

/* TEST FILES */
proc contents data=_all_ out=vars(keep=memname name type length nobs format informat varnum) noprint;
run;

/* Test types */
proc sql;
create table Vars2 as
select upcase(Name) as Name
		,max(varnum) as Varnum2
		,count(distinct Type) as Dist_Type
		,max(length) as Max_Len,*
from vars
where substr(memname,1,11)="RYAN_NONMGA" and nobs>0
group by 1
order by 2,1;
quit;

/* TRANSPOSE BY FIELD */
/*
proc sql;
create table Vars2_2 as
select upcase(Name) as Name
        ,max(varnum) as Varnum2
        ,max(length) as Max_Len,*
from vars
where substr(memname,1,11)="RYAN_NONMGA"
group by 1
order by memname,name;
quit;

proc transpose data=Vars2_2 out=Vars_trans2;
var Length;
by memname;
id name;
run;

proc transpose data=Vars2_2 out=Vars_trans2;
var format;
by memname;
id name;
run;
*/

/****************************************************************************/
/****************************************************************************/
/* SETS THE LENGTHS FOR VARS WITH SAME TYPE */
proc sql;
create table Vars3 as
select varnum2,name,dist_type,type,Max_Len
 ,case 
  when Dist_type>1 and type=2 then trim(substr(Name,1,30))||"_2"
  else trim(name) end as New_Name
 ,case when type=1 then "008" else "$"||put(Max_Len,z3.) end||"." as Len
 ,case when type=2 then trim(calculated new_name)||" $"||put(Max_Len,z3.)||"." end as Formats
  ,max(length) as Max
from vars2
/*where length(name)>2*/
group by 1,2,3,4,5,6,7,8;
quit;

proc sql noprint;
select distinct trim(new_name)||" "||trim(Len) as Len,Formats 
		into :Lengths separated by " ",:Formats separated by " "
from vars3
order by varnum2;
quit;
%put Len="&lengths" ;
%put formats="&Formats";

/* Unique */
/*
proc sql;
select distinct name,type
from Vars2
group by 1 
having count(distinct type)=1;
quit;
*/

/* Variables that will have _2 var created */
/* THE BELOW INCOMPATIBLE FIELDS WILL BE CONVERTED TO TEXT */
proc sql;
create table Vars4 as
select *
from Vars2
group by name 
having count(distinct type)>1
order by memname;
quit;

/* BELOW LENGTHS AND FORMATS for _2 VARIABLES (TEXT) */
/* transpose TYPE */
proc transpose data=Vars4 out=Types1;
where type=2;
var name;
by memname;
id varnum;
run;

/* Collects variables */
data Types2;
retain MEMNAME _NAME_ Stri Len;
set Types1;
/* 60 is the number of variables */
/* SPECIAL COL NAMES SYNTAX */
array Names{*} $ "1"n-"60"n;
length Stri $800.;
Stri="";

do i=1 to 60;
   if Names[i] ne ""
      then Stri=trim(Stri)||" "||trim(Names[i])||"="||trim(substr(Names[i],1,30))||"_2";
end;
Stri=left(right(compbl(stri)));
Len=length(Stri);
run;

/*
proc sql;
select max(length(trim(Stri))) as Max
from Types2;
quit;
*/

/* COLS TO KEEP */
proc sql noprint;
select distinct trim(a.name) as Cols into :Cols separated by " "
from vars2 a;
quit;
%put ### LENGTH=%length(&Cols) "Cols=&Cols";

/* TABLES TO BE STACKED */
%let Cols=_all_;
proc sql noprint;
select distinct trim(a.memname)||"(keep=&Cols "||
case when b.stri is not null then " rename=("||trim(b.stri)||")" else "" end||")" as Arqs1 
into :Arqs1 separated by " "
from vars2 a left join Types2 b on a.memname=b.memname;
quit;
%put ### %length(&Arqs1) "Arqs1=&Arqs1" ;

/*************************************************************************************************************/
/*************************************************************************************************************/
options mprint;
data Final;
retain File Tab obs PRODUCTION_YEAR PRODUCTION_MONTH;
length &Lengths;
format &Formats;
set &Arqs1;
run;

/* Records */
proc sql;
select File
,sum(tab='Paid') as Paid
,sum(tab='Reserves') as Reserves
,count(*) as N
from Final
group by 1;
quit;

/* TEST FILES */
proc contents data=Final out=vars_new(keep=memname name type length nobs varnum) noprint;
run;

/* DROP */
proc sql noprint;
select distinct "(not missing("||trim(a.name)||"))" as Test_Miss_All into :Test_Miss_All separated by " or "
from vars_new a
where lowcase(name) not in ('file','tab','obs')
order by varnum;
quit;
%put ### "Test_Miss_All=&Test_Miss_All";

/* REMOVE RECORDS WITH ALL MISSING */
data Final;
set Final;
if (&Test_Miss_All);
run;

/* Var_2 that are all missing */
%let Test_Miss_All=;
proc sql noprint;
select distinct ",sum(not missing("||trim(a.name)||")) as "||trim(a.name) as Test_Miss
into :Test_Miss separated by " "
from vars_new a
where lowcase(name) not in ('file','tab','obs') 
and substr(lowcase(name),1,index(name,"_2")-1) in
(select substr(lowcase(name),1,index(name,"_2")-1) as Vari
 from vars_new
 group by 1 
 having count(*)>1 and sum(index(name,"_2")>0)>0)
order by varnum;
quit;
%put ### "Test_Miss=&Test_Miss";

/* _2 Fields with all nulls */
proc sql;
create table nulos as
select 1 as Flag &Test_Miss
from Final;
quit;
/* transpose */
proc transpose data=nulos out=nulos2(rename=(_name_=New_Name));
run;

/* adds Flag */
proc sql;
create table nulos2 as
select substr(New_Name,1,index(New_Name,"_2")-1) as Name
        ,index(New_Name,"_2")>0 as Var_2 length=3
        ,sum(col1>0)=2 as Both_Pop,*
from nulos2
group by 1;
quit;

/* List variables with more than one type and how many rows per type */
proc sql;
select Name
    ,sum((Var_2=1)*col1) as Char
    ,sum((Var_2=0)*col1) as Num
from nulos2
where Name ne "Flag"
group by 1;
quit;

/* CHAR FIELDS TO DROP (_var_2) */
%let Cols_to_drop=;
proc sql;
select distinct trim(New_Name) as Cols_to_drop 
into :Cols_to_drop separated by " "
from nulos2 a
where col1=0 and Var_2=1;
quit;
%put ### "Cols_to_drop=&Cols_to_drop";

/* FIELDS w/ CONFLICT, that I need to analyze */
%let Class=;
proc sql;
select distinct trim(New_Name) as Class into :Class separated by " "
from nulos2 a
where Both_Pop;
quit;
%put ### "Class=&Class";

/* CHECK WHAT VALUES TO FIX */
proc means data=Final missing n;
var obs;
class &class;
ways 1;
/*output out=test n=Freq;*/
run;

/* CONVERSION: ALPHA to NUMERIC */
%let Alpha2Num=;
%let Drop_Aft_Converted=;
proc sql;
select distinct "if not missing("||trim(New_Name)||") then "
||trim(name)||"=input("||trim(New_Name)||",12.);" as Cmds,New_Name as Drop_Aft_Converted
into :Alpha2Num separated by " ",:Drop_Aft_Converted separated by " "
from Nulos2 a
where Both_Pop and Var_2=1;
quit;
%put ### "Alpha2Num=&Alpha2Num" "Drop_Aft_Converted=&Drop_Aft_Converted";

/* FINAL FILE */
%let Arq=ZRYAN_NonMGA_201907;
data jose.&Arq;
set Final;
/*if (&Test_Miss_All);*/
if PRODUCTION_Year ne .;
/* Moneys */
Paid_Loss=1*sum(Indemnity_Amount_Paid,MEDICAL_PAYMENTS_AMOUNT_PAID);
SS=1*Salvage_Subro;
Paid_LAE=1*AO_ALAE_PAID;
Paid_ALAE=1*DCC_ALAE_PAID;
Paid_ULAE=1*AO_ULAE_PAID;
Loss_Res=1*sum(Indemnity_Reserve_Amount,MEDICAL_PAYMENTS_RESERVE_AMOUNT);
LAE_Res=1*sum(ALAE_Reserve_Amount,ULAE_RESERVE_AMOUNT);
/* ALPHA to Numeric */
&Alpha2Num;
/* ALPHA to DATE */
/*&Cmds2;*/
/* NUMERIC to Alpha */
/*&Cmds3;*/
format Paid_loss SS Paid_LAE Paid_alae Paid_Ulae Loss_Res LAE_Res comma12.;
drop &Cols_to_drop;
drop &Drop_Aft_Converted;
drop BF BG;
drop Indemnity_Amount_Paid MEDICAL_PAYMENTS_AMOUNT_PAID Salvage_Subro;
drop ALAE_Expense_Amount_Paid ULAE_EXPENSE_AMOUNT_PAID; /* These don't seem to exist */
drop AO_ALAE_PAID DCC_ALAE_PAID AO_ULAE_PAID;
drop Indemnity_Reserve_Amount MEDICAL_PAYMENTS_RESERVE_AMOUNT ALAE_Reserve_Amount ULAE_RESERVE_AMOUNT;
run;

proc sql;
select 
sum(Paid_Loss) as PL
,sum(SS) as SS
,sum(Paid_LAE) as LAE
,sum(Paid_ALAE) as ALAE
,sum(Paid_ULAE) as ULAE
,sum(Loss_Res) as LR
,sum(LAE_Res) as LAER
from jose.ZRYAN_NonMGA_201901;
quit;

/* JOINS 2 OTHER FIELDS */
proc sql;
create table jose.&Arq as
select a.*,substr(a.policy_number,1,3) as Prefix,b.segment,c.reserve_group
from jose.&Arq a
left join jose.Ref_Ryan_Segment b on substr(a.policy_number,1,3)=b.Prefix and a.REO=b.REO
left join jose.Ref_Ryan_Res_Group c on a.policy_type=c.policy_type and a.REO=c.REO and b.segment=c.segment
order by a.File,a.Tab,a.Obs;
quit;

proc sql;
create table Miss1 as
select substr(a.policy_number,1,3) as Pol3,a.REO,count(*) as N
from jose.&Arq a
left join jose.Ref_Ryan_Segment b on substr(a.policy_number,1,3)=b.Prefix and a.REO=b.REO
left join jose.Ref_Ryan_Res_Group c on a.policy_type=c.policy_type and a.REO=c.REO and b.segment=c.segment
where b.segment is null
group by 1,2;
quit;

data xxx;
set jose.Ref_Ryan_Segment;
where compress(Prefix)="AA";
run;

proc sql;
create table Miss2 as
select distinct substr(a.policy_number,1,3) as Pol3,a.REO
substr(a.policy_number,1,3) as Prefix,b.segment,c.reserve_group
from jose.&Arq a
left join jose.Ref_Ryan_Segment b on substr(a.policy_number,1,3)=b.Prefix and a.REO=b.REO
left join jose.Ref_Ryan_Res_Group c on a.policy_type=c.policy_type and a.REO=c.REO and b.segment=c.segment
where b.segment is null;
quit;


proc sql;
select substr(policy_number,1,3) as Pref,count(*) as N
from jose.ZRYAN_NonMGA_201804
group by 1;
quit;

proc freq data=jose.Ref_Ryan_Segment;
table Prefix;
run;

/* Test */
proc sql;
select year(loss_date) as AY, year(Loss_Report_Date) as RY
,sum(sum(Paid_Loss,SS,Paid_Alae)) as Paid format=comma12.
,sum(loss_res) as LR format=comma12.
,count(*) as N
,sum(PRODUCTION_PERIOD=.) as Miss
,sum(PRODUCTION_Year=.) as Miss
from jose.ZRYAN_NonMGA_201804
group by 1,2;
quit;

/* REC */
proc sql;
create table New as
select File
,sum(sum(Paid_Loss,SS,Paid_Alae)) as Paid1 format=comma12.
,sum(loss_res) as LR1 format=comma12.
from jose.ZRYAN_NonMGA_201807
group by 1;
quit;

proc sql;
create table Old as
select File
,sum(sum(Paid_Loss,SS,Paid_Alae)) as Paid2 format=comma12.
,sum(loss_res) as LR2 format=comma12.
from jose.ZRYAN_NonMGA_201804
group by 1;
quit;

data Joine;
merge New Old;
by File;
run;

/*
Prefix is substr(policy,1,3)

Segment is based on Prefix
MT	Mortgage
CO	Collateral
GA	Contractual Liability (GAP)
TL	Tenant Liability
TD	Tenant Deposit
LI	Liability
FL	Flood
ST	Storage

Reserve Grp is based on Policy type-REO and segment:
*/

/*
proc sql;
select File,tab
,sum(CHECK_DATE=.) as Miss
,sum(year(CHECK_DATE)>2018) as Invalid
,count(*) as N
from Final
group by 1,2;
quit;

proc sql;
select File,tab
,sum(FILE_ACTIVITY_DATE=.) as Miss
,sum(year(FILE_ACTIVITY_DATE)>2018) as Invalid
,count(*) as N
from Final
group by 1,2;
quit;
*/

/* CHECK WHAT VALUES TO FIX */
/*
proc means data=Final missing n;
var obs;
class CHECK_DATE FILE_ACTIVITY_DATE;
ways 1;
run;

*/
