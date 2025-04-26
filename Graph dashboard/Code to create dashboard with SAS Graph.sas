data _null_;
h1=time();
time1="&sysdate._"||translate(put(h1,time8.0),"_",":");
call symput("time",time1);
run;
 
proc printto log="/prod/user1/uff597/BB/BB_&time..log";
run;
 
%put &time;
 
 
/* ALL FILES */
%let arq1=ich628_web_stats_visitors;
%let arq2=ich628_web_stats_pv;
%let arq3=ich628_web_stats_link;
%let arq4=ich628_web_stats_sessions;
%let arq5=ich628_web_stats_apps_started;
%let arq6=ICH628_WEB_STATS_APPS_SUBED;
/* VARS */
%let vari1=visitors;
%let vari2=pageviews;
%let vari3=clicks;
%let vari4=sessions;
%let vari5=apps;
%let vari6=apps;
 
%macro files;
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
%do i=1 %to 6;
create table &&arq&i as
select * from connection to teradata
(
select *
from ud155.&&arq&i
);
%end;
quit;
%mend;
%files;
 
 
%macro summa;
%do i=1 %to 6;
%let date_var=web_actvy_dt;
%if &i=6 
    %then %let date_var=DATE_APPLICATION_RECEIVED;
 
proc means data=&&arq&i noprint nway;
var &&vari&i;
class &date_var week day;
output out=&&arq&i(drop=_type_ _freq_ rename=(&date_var=Date_var)) sum=value;
run;
%end;
%mend;
%summa;
 
%macro une;
data all;
length Metric $29. file $13.;
set %do i=1 %to 6; &&arq&i(in=a&i) %end;
;
%do i=1 %to 6;
if a&i 
   then file=compress(tranwrd(lowcase("&&arq&i"),"ich628_web_stats_",""));
%end;
select ;
when (file="apps_subed") Metric="Apps subed";
when (file="visitors") Metric="Visitors";
when (file="pv") Metric="Page views";
when (file="link") Metric="Clicks";
when (file="sessions") Metric="Sessions";
when (file="apps_started") Metric="Apps started";
end;
 
keep Date_var week day Metric value File;
run;
%mend;
%une;
 
/* week 1: current week 
   week 2: last week */
%macro percs;
%global day1 day2 day3 day4 day5 day6 day7;
/* GETS THE MIN DAY */
proc sql noprint;
select min(Date_var)-min(day) as min_date
into :min_date
from all
where metric="Visitors" and week=1;
quit;
 
proc sql;
create table percs as
select Metric,
day_num,
case (day_num+1)
when (1) then "Sun"
when (2) then "Mon"
when (3) then "Tue"
when (4) then "Wed"
when (5) then "Thu"
when (6) then "Fri"
when (7) then "Sat" 
else "" end as Day_aux,
calculated day_aux||put(&min_date+day_num,date6.0) as Day,
sum(case when week=0 then value else 0 end) as Last_week,
sum(case when week=1 then value else 0 end) as This_week,
case when (calculated This_week ne 0 and calculated Last_week ne 0) 
then calculated This_week/calculated Last_week-1 
else . end as Perc_real /*format=percentn12.1*/,
case when calculated perc_real=. then .
when calculated perc_real>0 then min(calculated perc_real,0.30) 
else max(calculated perc_real,-0.30) end as Perc /*format=percentn12.1*/,
case 
when abs(calculated Perc)=. then "n/a"
when abs(calculated Perc)>0.25 then "red"
when 0.15<abs(calculated Perc)<=0.25 then "yellow"
when abs(calculated Perc)<=0.15 then "green"
else "n/a" end as flag_color
from all(rename=(day=Day_num))
group by 1,2
order by 1,2;
quit;
 
/* CREATES THE 7 DAYS OF THE WEEK: week day+month/day */
proc sql noprint;
select distinct day into :day1-:day7
from percs
where metric in ("Visitors","Apps subed")
order by Day_num;
quit;
%put &day1;
%mend;
%percs;
 
%put &day1 &day2 &day3 &day4 &day5 &day6 &day7;
 
/* RECOLOR THE BARS */
%macro bars;
proc sql noprint;
select metric,day,put(case 
when perc=. then .
when perc>0 then min(perc,0.40) 
else max(perc,-0.40) end,12.5) as Perc,flag_color 
into :Group1-:Group14,:midpoint1-:midpoint14,:Y1-:Y14,:cor1-:cor14
from percs
where metric in ("Apps subed","Visitors")
order by metric,day;
quit;
 
data gbars;     
/* declare variables */                                                                                                                 
length function $8. style Group $20. color $8. text $30.;
retain hsys '3' xsys ysys '2' ord 0;
 
/* data to draw the legend labels, top label first */
/* Visitors. Here only midpoint, Group and last Y has to change */
%do i=1 %to 14;
if input(&&y&i,12.) ne .
then do;
ord=ord+1;
function='move';xsys='2';midpoint="&&midpoint&i";Group="&&group&i";y=0;output;     
function='move';xsys='A';x=-2.5;y=0;output;
function='bar';x=+5;y=&&y&i;color="&&cor&i";style='solid';output;     
end;
%end;
run;
%mend;
%bars;
 
/****************************************************************/
/****************************************************************/
%macro legen;
%let metric1=%str(|Perc|>25%%);
%let metric2=%str(15%%<|Perc|<25%%);
%let metric3=%str(|Perc|<15%%);
%let leg_cor1=red;
%let leg_cor2=yellow;
%let leg_cor3=green;
 
%let x_c=77;
%let y_c=25;
data legen;
/* declare variables */
length function $8. style $20. color $8. text $30.;
retain hsys xsys ysys '3';
/* data to draw a RECTANGLE around the legend bars */
line=0;size=1;
x=&x_c-2; y=&y_c-8; function='move'; output;
x=&x_c+16; y=&y_c+3; function='bar'; color='black';  output; /*style='empty';*/
 
/* data to draw the legend labels, top label first */
/* position determines the placement (left, right, center, etc.) */
%do i=1 %to 3;
function='label';style="'Albany AMT'";
x=&x_c+2;y=&y_c+3*&i-9+0.9; position='6'; text="&&metric&i";color='black';size=2.2;output;
%end;
 
/* data to draw the legend bars, top label first */
%do i=1 %to 3;
size=.;
x=&x_c; y=&y_c+3*&i-10+0.5; function='move'; output; 
x=&x_c+1.1; y=&y_c+3*&i-10+0.5+2; function='bar'; color="&&leg_cor&i"; style='solid'; output; 
%end;
 
/* data to DRAW BORDERS AROUND THE LEGEND BARS: TO DO THAT, MOVE x,y=-0.2+0.2,  */
%do i=1 %to 3;
size=1.0;x=&x_c-0.2; y=&y_c+3*&i-10+0.5-0.2; function='move'; output; 
x=&x_c+1+0.2; y=&y_c+3*&i-8+0.5+0.2; function='bar'; color='black'; style='empty'; output; 
%end;
run;
%mend;
%legen;
 
/****************************************************************/
/****************************************************************/
/****************** END OF LEGEND CREATION ************************/
 
%macro mini_dash;
/* CREATES THE OVERALL SUMMARY STATUS BY METRIC */
proc sql;
create table sum as
select Metric length=12,
sum(Last_week ne . and This_week ne .) as valid_days,
sum(Last_week) as Last_week,
sum(This_week) as This_week,
calculated This_week/calculated Last_week-1 as Perc format=percentn12.1,
case 
when abs(calculated Perc)>0.25 then "red"
when 0.15<abs(calculated Perc)<=0.25 then "yellow"
when abs(calculated Perc)<0.15 then "green"
else "n/a" end as flag_color
from percs
group by 1
order by 1 desc;
quit;
 
proc sql;
create table sum_over as
select "OVERALL" as Metric length=12,. as valid_days,. as Last_week,. as This_week,
mean(abs(Perc)) as Perc format=percentn12.1,
case 
when 0.20<abs(calculated Perc) then "red"
when 0.10<abs(calculated Perc)<=0.20 then "yellow"
when abs(calculated Perc)<=0.10 then "green"
else "n/a" end as flag_color
from sum;
quit;
 
data sum_fin;
set sum_over sum;
run;
 
proc sql noprint;
select flag_color,trim(metric),put(this_week,8.0),put(perc,percentn7.1)
into :leg_cor1-:leg_cor7, :metric1-:metric7, :value1-:value7, :perc1-:perc7
from sum_fin;
quit;
 
%put &leg_cor1 &leg_cor2 &leg_cor3 &leg_cor4 &leg_cor5 &leg_cor6;
%put &metric1 &metric6;
 
%let x_c=14;
%let y_c=10;
 
data mini_dash;
/* declare variables */
length function $8. style $20. color $8. text $30.;
retain hsys xsys ysys '3';
/* data to draw a RECTANGLE around the legend bars */
line=0;size=1;
x=&x_c-2; y=&y_c-8; function='move'; output;
x=&x_c+16+11; y=&y_c+3+15; function='bar'; color='black';  output; /*style='empty';*/
 
/* data to draw the legend labels, top label first */
/* position determines the placement (left, right, center, etc.) */
function='label';style="'Albany AMT/bold'";
x=&x_c+2;y=&y_c+3*8-9+0.9; position='6'; text="Metrics Status";color='black';size=2.2;output;
 
%do i=1 %to 7;
function='label';style="'Albany AMT'";
x=&x_c+2;y=&y_c+3*&i-9+0.9; position='6'; text="&&metric&i";color='black';size=2.2;output;
x=&x_c+2+11;y=&y_c+3*&i-9+0.9; position='6'; text=compress("&&value&i");color='black';size=2.2;output;
x=&x_c+2+19;y=&y_c+3*&i-9+0.9; position='6'; text=compress("&&perc&i");color='black';size=2.2;output;
%end;
 
/* data to draw the legend bars, top label first */
%do i=1 %to 7;
size=.;
x=&x_c-0.1; y=&y_c+3*&i-10+0.5; function='move'; output; 
x=&x_c+1.1; y=&y_c+3*&i-10+0.5+2+0.1; function='bar'; color="&&leg_cor&i"; style='solid'; output; 
%end;
 
/* data to DRAW BORDERS AROUND THE LEGEND BARS: TO DO THAT, MOVE x,y=-0.2+0.2,  */
%do i=1 %to 7;
size=1.0;x=&x_c-0.2; y=&y_c+3*&i-10+0.5-0.2; function='move'; output; 
x=&x_c+1+0.2; y=&y_c+3*&i-8+0.5+0.2; function='bar'; color='black'; style='empty'; output; 
%end;
run;
%mend;
%mini_dash;
 
data anno;
set legen gbars mini_dash;
run;
 
/* use coutline to put black borders around the main bars */
goptions reset=all ctext=black htext=0.8 cells; 
title height=1 font="Albany AMT/bold" "Web Tracker Dashboard";
footnote h=12 " ";
goptions device=PNG;
pattern value=solid value=empty;
axis1 label=(angle=0 h=1.0 font="Albany AMT/bold" "Day") SPLIT=" " 
order=("&day1" "&day2" "&day3" "&day4" "&day5" "&day6" "&day7");/*justify=right*/
axis2 order=("Visitors" "Apps subed") label=(angle=0 h=1.0 font="Albany AMT/bold" "Metric");
axis3 order=(-0.40 to 0.40 by 0.10) label=(angle=0 h=1.0 font="Albany AMT/bold" "Perc");
 
*** Produce bar charts ***;    
ods listing; 
filename grafout "/prod/user1/uff597/BB/BB_&sysdate..png"; 
goptions reset=goptions device=PNG gsfname=grafout gsfmode=replace;  
proc gchart data=percs;
where metric in ("Visitors","Apps subed");
format Perc percentn12.1;
vbar Day / description="Visitors"
sumvar = perc
outside=sum
frame
woutline=1
type=sum
group=Metric
coutline=black 
cframe=CXF7E1C2
nolegend
maxis=axis1 
gaxis=axis2
raxis=axis3
annotate=anno
;
run;
quit;
 
 
/**** END OF THE SAS PROGRAM THAT CREATES THE GRAPH *******/
/**** BEGINNING OF HARITHA'S MACRO ************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
 
*libname MAC_SAS;
*libname MAC_SAS '/prod/user2/canada/pri/non_npi/AML/macros/';
*options MSTORED SASMSTORE=MAC_SAS;
 
%macro SENDMAIL (IMGFILE=
, SUBJECT=
, FROM=
, TOLIST=
, CCLIST=) ;
 
  
%local NOTES SOURCE SOURCE2 MPRINT;
 
%let NOTES   = %sysfunc (getoption(NOTES));
%let SOURCE  = %sysfunc (getoption(SOURCE));
%let SOURCE2 = %sysfunc (getoption(SOURCE2));
%let MPRINT  = %sysfunc (getoption(MPRINT));
 
options NONOTES NOSOURCE NOSOURCE2 NOMPRINT;
 
%local THIS VERSION;
%local PERL_PGM PERL_RUN PERLPIPE;
 
%let THIS = SENDMAIL;
%let VERSION = 2011.06.30;
 
%*---------------------------------------------------------------------------
%* Check for Image File location;
 
%if (%nrbquote(&IMGFILE) eq )  %then %do;
%put ERROR: &THIS: No valid Image File location is provided;
%goto EndMacro;
%end;
 
%*---------------------------------------------------------------------------
%* Check that Image File exist;
%if (%sysfunc(fileexist("&IMGFILE")) = 0) %then %do;
%put ERROR: &THIS: Image File &&IMGFILE does not exist;
%goto EndMacro;
%end;
 
%*---------------------------------------------------------------------------
%* Check for To list;
 
%if (%nrbquote(&TOLIST) eq )  %then %do;
%put ERROR: &THIS: No email address to send to;
%goto EndMacro;
%end;
%*---------------------------------------------------------------------------
%* Set TMP default;
 
   %let TEMPDIR = /tmp;
 
%*---------------------------------------------------------------------------
%* Write first part of Perl program ;
 
%let PERL_PGM = _%substr (%sysfunc (ranuni(0), 9.7), 3);
%let PERL_RUN = _%substr (%sysfunc (ranuni(0), 9.7), 3);
 
filename &PERL_PGM "&TEMPDIR./&PERL_PGM..pl ";
 
%let PERLPIPE = %str( %sysfunc(pathname(&PERL_PGM)));
 
data _null_;
file &PERL_PGM recfm=N;
 
put '#!/usr/bin/perl -w'
'0A'X  "use lib '/prod/user2/canada/pri/non_npi/AML/modules/';"
'0A'X  'use MIME::Lite;'
'0A'X  '$msg = MIME::Lite->new('
'0A'X  "From => %sysfunc(compress("'&FROM'",%str(%"))),"
'0A'X  "To   =>%sysfunc(compress("'&TOLIST'",%str(%"))) ,"
%if (%nrbquote(&CCLIST) ne )  %then %do;
'0A'X  "cc      =>%sysfunc(compress("'&CCLIST'",%str(%"))),"
%end;
    '0A'X  "Subject => %sysfunc(compress("'&SUBJECT'",%str(%"))),"
    '0A'X  "Type    =>'multipart/related'"
    '0A'X  ');'
    '0A'X  '$msg->attach('
    '0A'X  "Type => 'text/html',"
    '0A'X  'Data => qq{'
    '0A'X  '<body>'
    '0A'X  "<br>"
    '0A'X  '<img src="cid:myimage.gif">'
    '0A'X  ' </body>'
    '0A'X  '},'
    '0A'X  ');'
    '0A'X  '$msg->attach('
    '0A'X  "Type => 'image/gif',"
    '0A'X  "Id   => 'myimage.gif',"
    '0A'X  "Path => %sysfunc(compress("'&IMGFILE'",%str(%"))) ,"
    '0A'X  ');'
    '0A'X  '$msg->send();'
;
run;
 
%if &SYSERR ne 0 %then %do;
%put ERROR: &THIS: An error occurred. &SYSERR;
%goto EndMacro;
%end;
 
 
 
%if &SYSERR ne 0 %then %do;
%put ERROR: &THIS: An error occurred.;
%goto EndMacro;
%end;
 
X "chmod +x &TEMPDIR./&PERL_PGM..pl";
 

 
filename &PERL_RUN PIPE "&PERLPIPE";
data _null_;
infile &PERL_RUN;
input;
put _infile_;
run;
 
%if &SYSERR ne 0 %then %do;
%put ERROR: &THIS: An error occurred.;
%end;
 
 
%EndMacro:
 
%if (&PERL_PGM ne ) %then %do;
%let RC = %sysfunc (fileref (&PERL_PGM));
%if &RC <= 0 %then %do;
%if &RC = 0 %then
%let RC = %sysfunc (fdelete (&PERL_PGM));
filename &PERL_PGM;
%end;
%end;
 
%if (&PERL_RUN ne ) %then %do;
%let RC = %sysfunc (fileref (&PERL_RUN));
%if &RC <= 0 %then %do;
filename &PERL_RUN;
%end;
%end;
 
options &NOTES &SOURCE &SOURCE2 &MPRINT;
 
%mend  SENDMAIL;
 
 
/*%SENDMAIL (IMGFILE=%str(/prod/user1/uff597/BB/BB_&sysdate..png)*/
/*,SUBJECT=%str(Web Tracker Dashboard)*/
/*,FROM=%str(jose.sousa@capitalone.com)*/
/*,TOLIST=%str(jose.sousa@capitalone.com)*/
/*,CCLIST=jose.sousa@capitalone.com);*/
 
%SENDMAIL (IMGFILE=%str(/prod/user1/uff597/BB/BB_&sysdate..png)
,SUBJECT=%str(Web Tracker Dashboard)
,FROM=%str(jose.sousa@capitalone.com)
,TOLIST=%str(Christopher.Xie@capitalone.com,Peter.Tanner@capitalone.com,Haritha.Sharma@capitalone.com)
,CCLIST=jose.sousa@capitalone.com);
 
proc printto;
run;

