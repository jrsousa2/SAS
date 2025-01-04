%let test=%sysfunc(exist(prem.prem_div06));
%put &test;

%macro check(dir= ) ;
%if %sysfunc(fileexist(&dir)) %then %do;
%put File Exists ;
%end;

%else %do ;
%put File doesn’t exist.;
%end ;

%mend ;
%check(dir="C:\Documents and Settings\sannapareddy\Desktop\Holidays 2009.docx");

%sysfunc option empowers me to use the same Data step functions outside the Data step. Almost all of the Data step functions are available to use outside the data step if we use %sysfunc.

fileexist option, verifies the existence of an external file. It can also verifies the SAS library.


Here is another simple technique to check.....

data _null_;
x=filexist('C:\Documents and Settings\sannapareddy\Desktop\Holidays 2009.docx');
call symput('myvar1',x);
run;

%put &myvar1; 
