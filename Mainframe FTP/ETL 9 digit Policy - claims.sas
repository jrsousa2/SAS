/* CREATE A LIBRARY TO PLACE THE NEW TABLES */
%let Yr_qrtr=2012Q2;

%let Yr_qrtr=12Q2_test;

options noxwait;
x "mkdir ""C:\Documents and Settings\josousa\My Documents\SAS\CRS_claim\&Yr_qrtr""";

libname claim "C:\Documents and Settings\josousa\My Documents\SAS\CRS_claim\&Yr_qrtr";

/* CREATES A BATCH FILE TO DOWNLOAD DIV6 AS BINARY WITH LOCAL FTP UTILITY */
%macro Read_all_claim();
options notes=1 errors=1;
%do i=75 %to 75;

%let div_z2=%sysfunc(putn(&i,z2.));
/* TEST IF TABLE ALREADY EXISTS */
%let table_exist=%sysfunc(exist(claim.claim_div&div_z2));

%if %eval(&table_exist)
%then %do;
proc sql noprint;
select count(*) into :row_count
from claim.claim_div&div_z2;
quit;
%end;

%let do_loop=0;
/* IF TABLE ALREADY EXISTS AND HAS ROWS=0 RUN AGAIN */
%if %eval(&table_exist and &row_count=0)
    %then %let do_loop=1;
/* IF TABLE DOESN'T EXIST RUN AGAIN */
%if %eval(not &table_exist)
    %then %let do_loop=1;

/*
data _null_;
if &i in (6,8,9,13,15,17,18,21,26,27,29,30,32,33,38,43,46,50,54,55,58,59,64,66,68,75,80,81,82,85,86,87,89,91,92,97)
   then do_loop=1;
   else do_loop=0;
call symput("do_loop",do_loop);
run;
*/


/*%let test=1;*/
%put ##### i=&i do_loop=&do_loop row_count=&row_count;
%if &do_loop
%then %do;


data _null_;
file "C:\temp\claim_cmds.txt";
put "user acijso6 just4fun";
put "lcd C:\temp";
put "hash";
put "bin";
cmd="get 'AC.TD070Q.P050.M01.LOSSITD.DIV"||put(&i,z4.)||"(0)' claim_file"||put(&i,z4.)||".dat";
put cmd;
put "quit";
run;

data _null_;
file_to_read="C:\Temp\claim_file"||put(&i,z4.)||".dat";
call symput("file_to_read",file_to_read);
run;

options noxwait;
x "ftp -v -n -i -s:C:\temp\claim_cmds.txt aaaa";

%let div_z2=%sysfunc(putn(&i,z2.));
data claim.claim_div&div_z2(compress=yes);

infile "&file_to_read" recfm=N;

input
DIV $ebcdic4.
DEPT_FILL $ebcdic1.
DEPT $ebcdic1.
SECT $ebcdic1.
PU $ebcdic4.
DSP_DIV $ebcdic4.
DSP_SECT $ebcdic3.
DSP_PU $ebcdic4.
COMPANY $ebcdic3.
BRANCH $ebcdic4.
PRODUCER $ebcdic7.
POLICY_FILL $ebcdic1.
POLICY $ebcdic9.
MJC $ebcdic4.
TAX_STATE $ebcdic3.
KIND $ebcdic1.
KIND_FILL $ebcdic1.
REINS $ebcdic6.
TRTY_UW_YR $ebcdic4.
TRTY_LYR_NO $ebcdic2.
TRTY_DOM_STC_CD $ebcdic1.
TRTY_SECTION $ebcdic2.
ASL $ebcdic2.
ASL_DECIMAL $ebcdic1.
POL_EFF_YR s370ff4.
POL_EFF_MO s370ff2.
POL_EFF_QT s370ff1.
STATPLAN $ebcdic2.
REC_ID $ebcdic1.
CLAIM_OFF $ebcdic4.
CASE_NO $ebcdic8.
SYMBOL $ebcdic3.
HANDL_OFF $ebcdic4.
RESV_TYPE $ebcdic1.
CATASTROPHE $ebcdic5.
ACCDNT_YR s370ff4.
ACCDNT_MM s370ff2.
ACCDNT_QRTR s370ff1.
REPT_YR s370ff4.
REPT_QRTR s370ff1.
TPA_IND $ebcdic1.
SUB_TRNS $ebcdic2.
FILLER $ebcdic20.
CASE_FIX_I $ebcdic1.
SEG_CNTR s370fpd2.
;

if SEG_CNTR ne .
   then cont=SEG_CNTR;
   else cont=1;

do i=1 to cont by 1;

input
ACCTG_YR s370ff4.
ACCTG_QTR s370ff1.
PAID s370fpd8.2
OS s370fpd8.2
ALAE s370fpd8.2
ULAE s370fpd8.2
;
if not (PAID=0 and ALAE=0 and ULAE=0 and OS=0) 
   then output;
end;

drop DEPT_FILL POLICY_FILL KIND_FILL FILLER SEG_CNTR i cont rec_id HANDL_OFF;
run;

%end;

%end;
%mend;
%read_all_claim;

/* STACK ALL THE FILES INTO ONE */
/*(where=(div="%sysfunc(putn(&i,z4.))"))*/
%macro une_new;
data crsnew.claim_all(compress=yes);
set 
%do i=0 %to 99;
crsnew.claim_div%sysfunc(putn(&i,z2.))
%end;
;
run;
%mend;
/*%une_new;*/

/******************************************************************************************/
/******************************************************************************************/
/* INSERTS HANDLING OFFICE */
/******************************************************************************************/
/******************************************************************************************/

/* DOES cdw Tcase have dupe handling office by case,brch? */
proc sql;
create table dupes as
select branch_cd,case_no,handling_office
from cdw.tcase
group by branch_cd,case_no
having count(*)>1;
quit;


/* INSERTS THE HANDLING OFFICE INTO the claims file */
proc sql;
create table crsnew.claim_all(compress=yes) as
select a.*,b.HANDLING_OFFICE label=""
from CRSnew.Claim_all a left join cdw.tcase b
on input(a.CASE_NO,12.)=b.case_no and input(a.claim_off,12.)=b.branch_cd;
quit;

PROC DATASETS LIB=crsnew NOLIST;
modify claim_all;
INDEX CREATE DIV;
quit;

/* HANDLING OFFICES ID'ED */
proc sql;
create table test as
select HANDLING_OFFICE,count(*) as n
from claim
group by 1;
quit;


/* TESTE */
proc sql;
create table new.aaa as
select acctg_yr,acctg_qtr, count(*) as n
from new.claim_div00
group by 1,2;
quit;


proc sql;
create table crsc.counts as
select div, count(*)
from crsc.claim_all
group by 1;
quit;


PROC export data=loc.aaa outfile="C:\Documents and Settings\josousa\My Documents\aaa.xls" 
DBMS=EXCELCS;
RUN;
