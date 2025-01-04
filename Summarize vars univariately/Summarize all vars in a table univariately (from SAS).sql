/********* AIG CODE – LAST USED AT KEMPER ********************/

%macro tabulate(infile,outfile);
%let dsid=%sysfunc(open(&infile,i));
%let nvars=%sysfunc(attrn(&dsid,nvars));
%let nvars=%eval(&nvars-1);
 
%do i=1 %to &nvars;
    %let Variab&i=%sysfunc(varname(&dsid,&i));
    %put ### var &i=&&Variab&i;
%end;
 
data Freq2;
retain Var_num &nvars;
set &infile;
by _type_;
length Variab $32. Value $60.;
if first._type_
   then do;
          var_num=var_num-1;
        end;

/* DATA STEP SELECT WHEN SYNTAX */        
select;
%do i=1 %to &nvars;
    when (&i=var_num)
         do;
           Variab="&&Variab&i";
           Value=trim(left(&&Variab&i));
        end;
%end;
otherwise;
end;

Freq=_freq_;
keep freq Variab value;
run;
 
proc sql;
create table &Outfile as
select Variab, Value, Freq, count(*) as Dist_Values, sum(freq) as Total_Rows
from freq2
group by Variab
order by Dist_Values, Variab, Freq desc, Value;
quit;

/* CLOSES INPUT FILE */
%let rc=%sysfunc(close(&dsid));
 
/* DROPS TABLE */
proc sql;
drop table Freq2;
quit;
%put ### RESULTADO: &dsid;
%mend;

/*******************************************************************/
/*******************************************************************/
/*******************************************************************/
/* LIBNAMES */ 
libname EPICS "K:\Greg\EOEEPICS\AAC\TX\AAC OUTPUT";
 
%let MAIN_DIRECTORY = \\sliobtacuwrk800.unitrininc.unitrin.org\BDE\Greg;
LIBNAME ZAAC "&MAIN_DIRECTORY.\EOEEPICS\AAC\TX\AAC OUTPUT";
LIBNAME ZEPICS"&MAIN_DIRECTORY.\EOEEPICS\AAC\TX\AAC OUTPUT EPICS";
 
/* VARS AAC */
proc contents data=AAC.tx_offbal_final_202105_20201012
out=vars1(keep=name type length varnum) noprint;
run;
 
/* SELECTS VARS TO COUNT */
proc sql;
select ",count(distinct "||trim(name)||") as "||trim(name) as Col
into :Cmds separated by " "
from vars1;
quit;
%put CMDS=&Cmds;
 
%let table_name=ZAAC.tx_offbal_final_202105_20201012;
/* DISTINCT COUNTS */
proc sql;
create table Counts(drop=Type) as
select 1 as Type &Cmds
from &table_name;
quit;
 
/* TRANSPOSE */
proc transpose data=Counts out=Counts2;
run;
 
/* SELECT COLS */
proc sql;
select a._Name_,a.col1,b.type,count(*) as N into :Cols separated by " ",:Nulo1,:Nulo2,:Nulo3
from Counts2 a 
  left join vars1 b on a._name_=b.name
where a.col1<=300;
quit;
%put ### COLS=&Cols;
 
 
/* FREQS */
proc means data=&table_name SUMSIZE=max missingnoprint;
var policy_key;
ways 1;
class &Cols;
output out=Freqs_AAC(DROP=num) n=num;
run;
 
/* AAC SUMMARY */
%tabulate(Freqs_AAC,AAC);
 
/*******************************************************************/
/*******************************************************************/
/*******************************************************************/
/* EPICS */
/* SELECT COLS */
proc sql;
select a._Name_,a.col1,b.type,count(*) as N into:Cols separated by " ",:Nulo1,:Nulo2,:Nulo3
from Counts2 a left join vars1 b
on a._name_=b.name
where a.col1<=300 and _name_ not in("PRIOR6","PRIOR12");
quit;
%put ### COLS=&Cols;
 
/* FREQS */
proc means data=ZEPICS.tx_offbal_final_202105_20201012 SUMSIZE=max missing noprint;
var policy_key;
ways 1;
class &Cols;
output out=Freqs_EPICS(DROP=num) n=num;
run;
 
/* EPICS SUMMARY */
%tabulate(Freqs_EPICS,EPICS);
 
