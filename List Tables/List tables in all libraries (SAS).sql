-- LIST ALL TABLES IN ALL SELECTED SAS LIBRARIES
-- ALONG WITH THEIR LAST MODIFIED DATES
-- THIS IS NOT AS SMART AS USING DICTIONARY.TABLES

libname _all_ list;

proc contents data=jose._all_ out=a1 memtype=data nods;
run;

ods output Members=Members;
    proc datasets library=Jose memtype=data;
    run;
quit;

ods output Members=Members1;
    proc datasets library=AFFMARK memtype=data;
    run;
quit;

%let Lib1=AFFMARK;
%let Lib2=AFFNB;
%let Lib3=AGAUDIT;
%let Lib4=AGT_LIC;
%let Lib5=APFMTLIB;
%let Lib6=BI_DEV;
%let Lib7=CENTNAT;
%let Lib8=CLMCMN;
%let Lib9=COLLECT;
%let Lib10=CORPAN;

%macro roda;
%do i=1 %to 47;
    ods output Members=Members&i;proc datasets library=&&Lib&i memtype=data;run;
	/* adds name */
	data Members&i;
        length Library $10.;
        set Members&i;
        Library="&&lib&i";
	run;
%end;
quit;
%mend;
%roda;

options mprint;
%macro roda;
    data Final;
        length Name $32.;
        set %do i=1 %to 10; Members&i %end;
        ;
        LastModified=datepart(LastModified);
        format Num best12. LastModified yymmdd10.;
    run;
    quit;
%mend;
%roda;


proc freq data=final;
table memtype;
run;

proc contents data=work._all_ out=vars;
run;

proc sql;
select count(*)
from clmcmn.CLMCMN_TU_SIEBEL;
quit;
