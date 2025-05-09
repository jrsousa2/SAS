/* Test if exceptions are ok */
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table exc as
select * from connection to teradata
(
Select TC_DESC,SEG_DT,COUNT(*) as n
FROM ud156.AML_EXCEPTION_SEG_HIST 
where CQ is not null and SEG_DT >= '2011-07-01'
GROUP BY 1,2
union all
Select 'TOTAL',SEG_DT,COUNT(*) as n
FROM ud156.AML_EXCEPTION_SEG_HIST 
where CQ is not null and SEG_DT >= '2011-07-01'
GROUP BY 1,2
)
order by 1,2;
quit;
 
proc sql noprint;
select count(*)-9 into :min_row
from exc
where TC_DESC="TOTAL";
run;
 
data dates;
set exc;
where TC_DESC="TOTAL";
if _n_=&min_row;
run;
 
proc sql noprint;
select SEG_DT format=12.0 into :min_date
from dates;
run;
 
proc sql;
select "D"||put(SEG_DT,date9.),SEG_DT format=date6. into :date1-:date10,:head1-:head10
from exc
where SEG_DT>=&min_date and TC_DESC="TOTAL"
order by SEG_DT;
run;
 
/* HAVE TO FIX THE DATES HERE */
proc transpose data=exc out=exc2(drop=_name_ _label_) prefix=D;
where SEG_DT>=&min_date;
by TC_DESC;
var n;
id SEG_DT;
run;
 
%macro xsend_mail;
%global subj;
%let subj=%str(Exceptions Segmentation Report);
 
/*%let imagefile=/prod/user1/uff597/sasgraph.gif;*/
%let Sender=Jose;
%let SenderEmail=jose.sousa@capitalone.com;
%let SendEmails=%str(jose.sousa@capitalone.com);
%put &sendemails;
 
filename outbox email emailid="&SenderEmail"; 
data _null_;
set exc2;
file outbox
to="&SendEmails."
cc=('ian.robertson@capitalone.com' 'steve.frensch@capitalone.com')
subject="&subj";
/*attach=("&imagefile" content_type='image/gif' extension='gif' );*/
if _n_=1
then do;
put "Let me know if you have any questions.";
put;
put "&Sender.";
put;
put "Exceptions per segmentation date:";
put;
 
/* HEADERS*/
put "TC_DEC              "
 
%do i=1 %to 10; 
"    &&head&i" 
%end;
;
 
 
end;
 
put tc_desc $20. 
%do i=1 %to 10; 
&&date&i 9.
%end;
;
run;
 
%mend xsend_mail;
%xsend_mail;

