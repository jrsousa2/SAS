/* %tabulate macro adapted from Summarize vars univariately/Summarize    */
/* all vars in a table univariately.sas in jrsousa2/SAS. The macro body  */
/* is byte-identical to the source's %tabulate definition; only the      */
/* driving PROC MEANS call and its input are substituted (see below).    */

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
           Value=strip(&&Variab&i);
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

/* Substitutions applied to the driving code below (source used            */
/* AAC.tx_offbal_final_202105_20201012 from an external UNC-path libname): */
/*  - mock WORK.claims_sample (5 rows, region/status) replaces the         */
/*    external table.                                                     */
/*  - CLASS region status (explicit list) replaces the source's            */
/*    CLASS _all_ -- both are documented PROC MEANS CLASS forms; the       */
/*    explicit list keeps this bundle demonstrating the %tabulate macro's  */
/*    own logic (which the source itself defines and calls this way in    */
/*    Reminders/Tabulate.sas, its sibling file) rather than a separate     */
/*    CLASS _ALL_ expansion path.                                          */

data work.claims_sample;
    length region $10 status $10;
    region="East";  status="Open";   output;
    region="East";  status="Closed"; output;
    region="West";  status="Open";   output;
    region="West";  status="Open";   output;
    region="North"; status="Closed"; output;
run;

%let table_name=freq;
proc means data=work.claims_sample missing noprint;
var region;
ways 1;
class region status;
output out=&table_name(DROP=num) n=num;
run;

%tabulate(freq, tab_claims);

proc print data=tab_claims noobs;
run;
