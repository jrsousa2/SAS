PROC IMPORT OUT=test
DATAFILE="C:\Documents and Settings\josousa\My Documents\Requests\Lin\dist.xls" 
DBMS=EXCELCS 
REPLACE;
RUN;

proc sql;
create table test as
select *
from test
group by ;
quit;

proc sql;
create table test as
select distinct Pol_ID3,count(distinct insd_name) as N_dist,insd_name
from contract_link3
group by Pol_id3
having N_dist=2;
quit;

data test2;
retain ord 0;
set test;
by pol_id3;
if first.pol_id3
   then ord=1;
   else ord=2;
run;

proc sql;
create table test3 as
select Pol_ID3,
max(case when ord=1 then insd_name end) as name1,
max(case when ord=2 then insd_name end) as name2
from test2
group by Pol_id3;
quit;

proc sql;
create table prem as
select distinct Pol_ID,count(distinct lowcase(compress(insured_name,"&'(),-./01245678`"))) as N_dist,
lowcase(compress(insured_name,"&'(),-./01245678`")) as insd_nm,
sum(wrtn) as WP
from div59_3
group by Pol_id
order by n_dist desc;
quit;

PROC export data=prem
Outfile="C:\Documents and Settings\josousa\My Documents\Requests\Lin\prem.xls"
DBMS=EXCELCS
REPLACE;
RUN;



proc sql;
select distinct Pol_ID,pol_eff_yr,count(distinct lowcase(compress(insured_name,"&'(),-./01245678`"))) as N_dist,
lowcase(compress(insured_name,"&'(),-./01245678`")) as insd_nm,contract_no
from contract_link3
where pol_id=786;
quit;
