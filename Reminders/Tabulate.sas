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

