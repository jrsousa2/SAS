/* CREATE A LIBRARY TO PLACE THE NEW TABLES */
%let Yr_qrtr=2012Q2_new;
libname prem "C:\Documents and Settings\josousa\My Documents\SAS\CRS_prem\&Yr_qrtr";

/*
options noxwait;
x "mkdir ""C:\Documents and Settings\josousa\My Documents\SAS\CRS_prem\&Yr_qrtr""";
*/

/* CREATES A BATCH FILE TO DOWNLOAD DIV6 AS BINARY WITH LOCAL FTP UTILITY */
%macro Read_all_prem();
options notes=0;
%do i=0 %to 99;

%let div_z2=%sysfunc(putn(&i,z2.));
/* TEST IF TABLE ALREADY EXISTS */
%let table_exist=%sysfunc(exist(prem.prem_div&div_z2));

%if %eval(&table_exist)
%then %do;
proc sql noprint;
select count(*) into :row_count
from prem.prem_div&div_z2;
quit;
%end;
%else %let row_count=0;

%let do_loop=0;
/* IF TABLE ALREADY EXISTS AND HAS ROWS=0 RUN AGAIN */
%if %eval(&table_exist and &row_count=0)
    %then %let do_loop=1;
/* IF TABLE DOESN'T EXIST RUN AGAIN */
%if %eval(not &table_exist)
    %then %let do_loop=1;

/*
data _null_;
if &i not in (6,8,9,13,15,17,18,21,26,27,29,30,32,33,38,43,46,50,54,55,58,59,64,66,68,75,80,81,82,85,86,87,89,91,92,97)
   then do_loop=1;
   else do_loop=0;
call symput("do_loop",do_loop);
run;
*/

/*%let test=1;*/
%put ############### loop=&do_loop;

%if &do_loop 
%then %do;

data _null_;
file "C:\temp\prem_cmds.txt";
put "user ACIJSO6 reset4me";
put "lcd C:\temp";
put "hash";
put "bin";
cmd="get 'AC.TD125Q.P010.M01.PREMITD.DIV"||put(&i,z4.)||"(0)' prem_file"||put(&i,z4.)||".dat";
put cmd;
put "quit";
run;

data _null_;
file_to_read="C:\Temp\prem_file"||put(&i,z4.)||".dat";
call symput("file_to_read",file_to_read);
run;

options noxwait;

x "ftp -v -n -i -s:""C:\temp\prem_cmds.txt"" aaaa";

%put input_file: "&file_to_read";
%put Creating file: &i;

filename FN&i "&file_to_read";

data prem.prem_div&div_z2(compress=yes);

infile FN&i recfm=N;

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
TRANS_PREM $ebcdic2.

TRANS_EFF_YR s370ff4.
TRANS_EFF_MM s370ff2.
TRANS_EFF_DAY s370ff2.
TRANS_EXP_YR s370ff4.
TRANS_EXP_MM s370ff2.
TRANS_EXP_DAY s370ff2.
POL_EFF_DAY s370ff2.
POL_EXP_YR s370ff4.
POL_EXP_MM s370ff2.
POL_EXP_DAY s370ff2.
FILLER_1 $ebcdic33.

SEG_CNTR s370fpd2.
;

do i=1 to SEG_CNTR;

input
ACCTG_YR s370ff4.
ACCTG_QTR s370ff1.
EARNED s370fpd8.2
WRTN s370fpd8.2
COMM s370fpd8.2
FILLER_3 s370fpd8.2
;
if not (EARNED=0 and WRTN=0 and COMM=0) then output;
end;


drop dept_fill policy_fill kind_fill rec_id filler_1 i seg_cntr filler_3;
run;

%end;
/* fim do IF */
%end;
options notes=1;
%mend;
%read_all_prem;

