%macro tabulate(outfile);
%let dsid=%sysfunc(open(&table_name,i));
%let nvars=%sysfunc(attrn(&dsid,nvars));
%let nvars=%eval(&nvars-1);

%do i=1 %to &nvars;
%let variav&i=%sysfunc(varname(&dsid,&i));
%put ### var &i=&&variav&i;
%end;

data freq2;
retain var_num &nvars;
set &table_name;
by _type_;
length variav $32. value $60.;
if first._type_
   then do;
          var_num=var_num-1;
        end;
select;
%do i=1 %to &nvars;
when (&i=var_num) do; variav="&&variav&i"; value=trim(left(&&variav&i)); end;
%end;
otherwise;
end;
freq=_freq_;
keep freq variav value;
run;

proc sql;
create table &outfile as
select variav, value, freq, count(*) as n_class, sum(freq) as n_rows
from freq2
group by variav
order by n_class, variav, freq desc, value;
quit;
%let rc=%sysfunc(close(&dsid));
proc sql;
drop table freq2, &table_name;
quit;
%put ### RESULTADO: &dsid;
%mend;

%let table_name=freq;
proc means data=danaly.SAMPLE_JAC missing noprint;
var AP_V_ITEM_NO;
ways 1;
class _all_;
output out=&table_name(DROP=num) n=num;
run;

%tabulate(tab_samp);

%let table_name=freq_2;
proc means data=danaly.sef missing noprint;
var sess_key;
ways 1;
class _all_;
output out=&table_name(DROP=num) n=num;
run;

%tabulate(tab_sef);

%let table_name=freq_2;
proc means data=danaly.sample missing noprint;
var AS_PMS_AGENCY;
ways 1;
class _all_;
output out=&table_name(DROP=num) n=num;
run;
%tabulate(tab_samp);

proc sql;
create table match as 
select b.variav as var_samp,a.variav as var_sef, 
b.n_class as n_class_samp,a.n_class as n_class_sef, 
count(*) as n,
a.value as value_sef, b.value as value_samp,
count(distinct a.value) as ndist_sef, count(distinct b.value) as ndist_samp,
count(*)/n_class_samp as match format=12.2
from tab_sef a, tab_samp b
where 
input(compress(a.value),12.)=input(compress(b.value),12.) 
and input(compress(a.value),12.) ne . 
group by 
var_sef, 
var_samp,
n_class_sef,
n_class_samp
having 
count(distinct a.value)>1 and
count(distinct b.value)>1
order by match desc, n desc,
var_samp,var_sef,n_class_samp desc,n_class_sef desc, 
ndist_samp desc,ndist_sef desc,value_samp,value_sef;
quit;

/*
lowcase(a.variav)="policy_nbr" and 
lowcase(b.variav)="as_cede_policy_no" and 

data xxx;
set final_sef;
where variav="AP_S_SERIAL";
teste=input(compress(value),12.);
run;

*/
