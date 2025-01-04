/* Test the tables that I may have to have access to */
/*%let arq11=u62262_capstone_rpt_spool; => does not exist */
%let arq1=ich628_web_stats_date;
%let arq2=ich628_web_stats_pv;
%let arq3=ich628_web_stats_link;
%let arq4=ich628_web_stats_visitors;
%let arq5=ich628_web_stats_sessions;
%let arq6=ich628_web_stats_apps_started;
%let arq7=ich628_web_stats_apps_subed;
%macro testa;

%do i=1 %to 7;
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table x&i as
select * from connection to teradata
(
select count(*) as n
from ud155.&&arq&i;
);
quit;
%end;
%mend;
%testa;


%macro une;
data xxx;
length name $32.;
set %do i=1 %to 7; x&i(in=a&i) %end;
;
%do i=1 %to 7; 
if a&i then ord=&i;
if a&i then name="&&arq&i";
%end;
run;
%mend;
%une;


proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
select * from connection to teradata
(
select *
from ud155.u99202_c_customer
sample 1;
);
quit;

proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table visitors as
select * from connection to teradata
(
select *
from ud155.ich628_web_stats_visitors;
);
quit;

/*grant all on UD156.u99202_temp_cust_list to userid;*/
/*grant all on ud155.u99202_c_customer to userid;*/
/*ich628_web_stats_date	7*/
/*ich628_web_stats_pv	7615*/
/*ich628_web_stats_link	53397*/
/*ich628_web_stats_visitors	42*/
/*ich628_web_stats_sessions	42*/
/*ich628_web_stats_apps_started	35*/
/*ich628_web_stats_apps_subed	55*/

%let arq1=ich628_web_stats_date;
%let arq2=ich628_web_stats_pv;
%let arq3=ich628_web_stats_link;
%let arq4=ich628_web_stats_visitors;
%let arq5=ich628_web_stats_sessions;
%let arq6=ich628_web_stats_apps_started;
%let arq7=ich628_web_stats_apps_subed;
%macro testa;

%do i=1 %to 7;
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table &&arq&i as
select * from connection to teradata
(
select *
from ud155.&&arq&i;
);
quit;
%end;
%mend;
%testa;

