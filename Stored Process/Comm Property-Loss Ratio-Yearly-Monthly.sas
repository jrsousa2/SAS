/* this line tells EG to not display some specific log information */
/*options nosource nosource2 nomprint nomlogic nomacrogen nosymbolgen notes=0;*/
options nosource nosource2 nomprint nomlogic nomacrogen nosymbolgen notes=0;
/* MACRO */
%macro prop_entry_indic;
%local filter_variav;
/* appends the username to the filename */
%let default_lib=comuser;
/*THESE MACROVARS TELL WHETHER TO RUN PREMIUM AND/OR CLAIM*/
%let run_premium=1;
%let run_claim=1;

data _null_;
lib=scan("&outfile",1,".");
if lowcase(lib)="&default_lib"
   then call symput("assign",1);
   else call symput("assign",0);
name=scan("&outfile",2,".");
newname=compress(lib||"."||"&_metauser"||"_"||"&sysdate"||"_"||name);
newname=substr(newname,1,32);
call symput("outfile",compress(newname));
run;

%if &assign
%then %do;
libname &default_lib Base "/sasdata/comuser";
%end;

/* tests if the provided outfile is error free */
data &outfile;
run;

/* if no error with specified output file do */
%if &syserr=0
%then %do;
proc sql;
drop table &outfile;
quit;

%lib_actcom;

%let selec=%str(AS_CEDE_POLICY_NO SS_TRANSACTION_CODE1 SS_SYUS_COMPANY1);

/* FILTER CRITERIA */
/* this part handles specifically the creation of the multiple filters */
/* property filter */
%let name_filter1=business_indicator;
%let name_filter2=product_major_line;
%let name_filter3=SS_SYUS_COMPANY;/* exception */
%let name_filter4=risk_province;
%let name_filter5=product_line_desc;
%let name_filter6=SS_SYUS_BRANCH;/* exception */
%let name_filter7=OFFICE_CODE;
%let name_filter8=SS_PL5_FORM;
%let name_filter9=kpnwl_code;/* 2 exceptions */
%let name_filter10=SS_RISK_NUMBER;/* exception */
%let name_filter11=property_industry_code;

%let filter_comp=1;
%do i=1 %to 11;
/* name of the filter criteria variable */
%let variav=&&name_filter&i;
%let filter_variav=&variav;

/* exceptions for Property */
data _null_;
select (upcase("&variav"));
when ("SS_RISK_NUMBER") /* SS_RISK_NUMBER */
do; 
 call symput("filter_variav","SS_RISK_NUMBER1");
 call symput("actual_variav","SS_RISK_NUMBER1");
end;
when ("SS_PL5_FORM") /* SS_PL5_FORM */
do; 
 call symput("filter_variav","compress(SS_PL5_FORM1)");
 call symput("actual_variav","SS_PL5_FORM1");
end;
when ("SS_SYUS_COMPANY") /* SS_SYUS_COMPANY */
do; 
 call symput("filter_variav","SS_SYUS_COMPANY1");
 call symput("actual_variav","SS_SYUS_COMPANY1");
end;
when ("SS_SYUS_BRANCH") /* SS_SYUS_BRANCH */
do; 
 call symput("filter_variav","SS_SYUS_BRANCH1");
 call symput("actual_variav","SS_SYUS_BRANCH1");
end;
when ("KPNWL_CODE") /* KPNWL_CODE */
do;
 call symput("filter_variav","put(KPNWL_CODE1,z4.)");
 call symput("actual_variav","KPNWL_CODE1");
end;
when ("PROPERTY_INDUSTRY_CODE") /* PROPERTY_INDUSTRY_CODE */
do; 
 call symput("filter_variav","compress(PROPERTY_INDUSTRY_CODE)");
 call symput("actual_variav","PROPERTY_INDUSTRY_CODE");
end;
otherwise 
do; 
 call symput("filter_variav","&variav");
 call symput("actual_variav","&variav");
end;
end;
run;

%put ### i=&i filter_variav=&filter_variav;

/*HANDLES THE CREATION OF THE TWO PARAMETERS*/
data pmts_&i;
variavel="&actual_variav";
/*TEST IF NUMBER OF PICKS FOR VAR ACTUAL_VARIAV EXIST*/
%if %symexist(&&variav.0)
    %then %do;
			 number_picks_a="&&&variav.0";
			 if input(number_picks_a,12.)>0
			    then number_picks=input(number_picks_a,12.);
			    else number_picks=0;
		  %end;
	%else number_picks=0;;

/*TEST IF FIRST PICK FOR VAR ACTUAL_VARIAV EXIST*/
%if %symexist(&&variav)
    %then first_pick="&&&variav";
	%else first_pick="";;

if first_pick ne "" and number_picks=0 
   then number_picks=1;
call symput("&&variav.0",compress(number_picks));
run;

%put variable=&actual_variav number_picks=&&&variav.0;

%if &&&variav.0>0
    %then %let &variav.1=&&&variav;

%if &&&variav.0>0
    %then %do;
	        %let filter="&&&variav.1";
			/*THIS IS USED TO TROUBLESHOOT DIFFERENT BEHAVIOUR ON THE STORED PROCESS ENVIROMENT*/
			%put Filter step=&i%str(:) added &actual_variav to "SELEC";
			%let selec=%str(&selec &actual_variav);
          %end;
	%else %let filter="";

%do j=2 %to &&&variav.0;
%let filter=%str(&filter,"&&&variav&j");
%end;
%if &filter ne ""
    %then %let filter_comp=%str(&filter_comp and &filter_variav in (&filter));
/* prints the filter step by step */
/*%put ### i=&i &filter_comp;*/
%end;

/*THIS PART SUMMARIZES THE NUMBER OF FILTER PICKS*/
data /*comuser.*/picks;
length variavel first_pick $32.;
set %do i=1 %to 11; pmts_&i %end;;
run;

/* handles the policy number filter, if any */
%if &AS_CEDE_POLICY_NO ne all
%then %let filter_comp=%str(&filter_comp and AS_CEDE_POLICY_NO="&AS_CEDE_POLICY_NO");

proc contents data=actcom.PREMIUM_PROPERTY out=contents(keep=name) noprint;
run;
proc contents data=actcom.CLAIM_POLICY_PROPERTY out=aux(keep=name) noprint;
run;

proc sql;
create table contents as
select name
from contents
where lowcase(name) in (select lowcase(name) from aux);
quit;

/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/
%put ######### BEFORE TRANSFORMATION: pick_var0=&pick_var0;
%if %symexist(pick_var0)
    %then %do;
              %if &pick_var0=
	          %then %if "&pick_var" ne ""
                         %then %let pick_var0=1;
                         %else %let pick_var0=0;
		  %end;
	%else %if "&pick_var" ne ""
               %then %let pick_var0=1;
	           %else %let pick_var0=0;

%if &pick_var0=0
    %then %let pick_var1=;

%if &pick_var0=1
    %then %let pick_var1=&pick_var;
%put ### pick_var0=&pick_var0;
%put ### pick_var1=&pick_var1;

/* THIS PART INCLUDES THE VARIABLES PICKED SECONDLY */
%if %symexist(sec_pick_var0)
    %then %do;
              %if &sec_pick_var0=
	          %then %if "&sec_pick_var" ne ""
                         %then %let sec_pick_var0=1;
                         %else %let sec_pick_var0=0;
		  %end;
	%else %if "&sec_pick_var" ne ""
               %then %let sec_pick_var0=1;
	           %else %let sec_pick_var0=0;

%if &sec_pick_var0=1
    %then %let sec_pick_var1=&sec_pick_var;
%put ### sec_pick_var0=&sec_pick_var0;
%put ### sec_pick_var1=&sec_pick_var1;

%do j=1 %to &sec_pick_var0;
%let index=%eval(&pick_var0+&j);
%put ### SECOND VAR LIST j=&j index=&index;
%let pick_var&index=&&sec_pick_var&j;
%put ### j=&j pick_var&index=&&sec_pick_var&j;
%end;

%let pick_var0=%eval(&pick_var0+&sec_pick_var0);
%put ######### AFTER TRANSFORMATION: pick_var0=&pick_var0;
/**********************************************************/
/**********************************************************/
/**********************************************************/
/**********************************************************/

%let group_selec=&pick_var1;
%do i=2 %to &pick_var0;
%let group_selec=%str(&group_selec,&&pick_var&i);
%end;

/* THIS FIXES POSSIBLE PROBLEMS WITH COMMAS IF GROUP SELECT IS BLANK */
%if &group_selec ne %str()
    %then %let group_selec=%str(,&group_selec);

/* this creates the selected variables without the commas */
%let group_selec_nocomma=%sysfunc(tranwrd(&group_selec,%str(,),%str( )));

/* this part drops variables that were picked duplicately from the variables picklist */
/* by setting them to 'none' if they're duplicate                                     */
/*ADD VARIABLES ON THE PICK LIST TO THE SELECTION WHICH IS THE "SELEC" MACROVAR*/
%do i=1 %to &pick_var0;
data _null_;
text=lowcase(compbl("@@@ &selec @@@"));
search=index(text,lowcase(" "||compress("&&pick_var&i")||" "));
if search ne 0
   then call symput("pick_var&i","none");
run;

proc sql noprint;
select count(*)>0 into :exist
from contents
where lowcase("&&pick_var&i") in (select lowcase(name) from contents);
quit;

%put step=&i%str(:) Testing if "&&pick_var&i" is added to "SELEC";
%if "&&pick_var&i" ne "none" and &exist
    %then %do;
             %let selec=%str(&selec &&pick_var&i);
			 %put step=&i%str(:) Added "&&pick_var&i" to "SELEC";
		  %end;
%end;

%let selec=%str(&selec entered_date effective_date_of_policy transaction_date policy_expiry_date written_exposure written_premium);
proc sql;
drop table contents;
quit;

%let claims_as_of_aux=&claims_as_of;
data _null_;
start=input("&start",yymmn6.0);
call symput("start_date",start);
call symput("start_date_disp",put(start,date9.0));
end=input("&end",yymmn6.0);
end=intnx('month',end,1)-1;
call symput("end_date",end);
call symput("end_date_disp",put(end,date9.0));
claims_as_of=input("&claims_as_of",yymmn6.0);
call symput("claims_as_of",claims_as_of);
format start end claims_as_of ddmmyy10.;
run;

%put ### ;
%put ### Filter=&filter_comp;
%put ### Selec=&selec;
%put ### Group_selec=&Group_selec;
%put ### group_selec_nocomma=&group_selec_nocomma;
%put ### start_date=&start_date_disp end_date=&end_date_disp;

/*SHOULD THE PART THAT CREATES PREMIUM TABLES BE RUN? YES=1 N0=0*/
%if &run_premium
%then %do;
%put ### 1. CREATING PREMIUM DATASET...;
data premium;
retain &selec;
set actcom.PREMIUM_PROPERTY(keep=&selec /*obs*/);
where &filter_comp and 
(max(transaction_date,&start_date)<=min(policy_expiry_date,&end_date) or 
 &start_date<=entered_date<=&end_date) and
 SS_TRANSACTION_CODE1 not in ("3","7") and
 SS_SYUS_COMPANY1 not in ("05","08");
run;

/**********************************************************************/
/******************************* PREMIUMS *****************************/
/**********************************************************************/
%put ### 2. COMPUTING EARNED PREMIUM...;
data earned;
set PREMIUM;
where max(transaction_date,&start_date)<=min(policy_expiry_date,&end_date);

if transaction_date ne . and policy_expiry_date ne . and (policy_expiry_date-transaction_date) ne 0 
then full_term_wp=written_premium*(policy_expiry_date-effective_date_of_policy)/(policy_expiry_date-transaction_date);
else full_term_wp=0;

/* compute the number of months exposed on the transaction */
begin_mth=max(transaction_date,&start_date);
end_mth=min(policy_expiry_date,&end_date);
n_month=(year(end_mth)-year(begin_mth))*12+month(end_mth)-month(begin_mth)+1;
month=.;
next_month=.;
begin_day=.;
end_day=.;
sign=SIGN(written_premium);

/* these vars are placed here just so they show up orderly on the table,*/
/* not needed though */
length earned_month $6.;
earned_month="";
earned_exposure=0;
earned_premium=0;

do i=0 to n_month-1;
month=intnx('month',begin_mth,i);
next_month=intnx('month',begin_mth,i+1)-1;
earned_month=put(month,yymmn6.); 

/* restrict the calculation to the months that fall onto the interval */
if "&start"<=earned_month<="&end"
then do;
begin_day=max(month,transaction_date);
end_day=min(next_month,policy_expiry_date);

earned_exposure=round((end_day-begin_day+1)/365.25*sign,.001);
earned_premium=round(full_term_wp*round((end_day-begin_day+1)/(policy_expiry_date-effective_date_of_policy),.001),.01);

IF -0.001<earned_exposure<0.001
    then earned_exposure=0;

IF -0.01<earned_premium<0.01 or earned_premium=.
    then earned_premium=0;

/* GENERATES ONE RECORD FOR EACH earned MONTH */
output;

end;/* end of if &start<=earned_month<=&end */
end;/* end of the "do i=0 to n_month-1" */

format month next_month begin_day end_day begin_mth end_mth ddmmyy10.;
/*drop month next_month begin_day end_day begin_mth end_mth;*/
format written_premium full_term_wp 12.2;
drop i sign;
run;
/* END MONTH EARNED */

%if &period=monthly
    %then %do;
            %let prem_var1=earned_month;
			%let prem_var2=put(entered_date,yymmn6.0);
			%let clm_var=put(CR_LOSS_DATE,yymmn6.0);
			%let rename_cmd=%str(year=year_month);
		  %end;
   %else %do;
            %let prem_var1=input(substr(earned_month,1,4),12.);
			%let prem_var2=year(entered_date);
			%let clm_var=year(CR_LOSS_DATE);
			%let rename_cmd=%str(year=Year);
		  %end;

%put ### 3. SUMMARIZING EARNED PREMIUM;
proc sql;
create table earned_sum as
select &prem_var1 as Year &group_selec, 
sum(earned_exposure) as earned_exposure format=12.3,
sum(earned_premium) as earned_premium format=12.0
from earned
group by Year &group_selec
order by Year &group_selec;
quit;

%put ### 4. COMPUTING WRITTEN PREMIUM...;
proc sql;
create table written_sum as
select &prem_var2 as Year &group_selec, 
sum(written_exposure) as written_exposure format=12.3,
sum(written_premium) as written_premium format=12.0
from premium
where &start_date<=entered_date<=&end_date
group by Year &group_selec
order by Year &group_selec;
quit;

data premium_sum;
/*retain Year &group_selec_nocomma written_exposure earned_exposure written_premium earned_premium;*/
merge earned_sum written_sum;
by year &group_selec_nocomma;
if written_exposure=. then written_exposure=0;
if earned_exposure=. then earned_exposure=0;
if written_premium=. then written_premium=0;
if earned_premium=. then earned_premium=0;
format 
written_exposure earned_exposure 12.2 
written_premium earned_premium 12.0;
run;

/*END OF %if 1 %then %do */
%end;

/*SHOULD THE PART THAT CREATES CLAIM TABLES BE RUN? YES=1 N0=0*/
%if &run_claim
%then %do;
/* THIS PART HANDLES THE CLAIMS TABLE CREATION */
%put ### RUNNING THE CLAIMS PART...;
proc sql;
create table claims as
select &clm_var as Year, 
/* variables that determine the claim count and capping */
LINE,CLAIMSYM,CR_CLAIM_NO,CR_LOSS_DATE,CR_OCCURANCE,
fclas3,tou,CR_AUTO_DRIVER_REC_SECA,
cr_fire_class,cr_coverage_cd,kol
/* end of vars */
&group_selec, 
1 as claim_cnt,
sum(p_amt+e_amt+s_amt+(cr_generate_trans="0" and 
year(cr_transaction_date)=year(&claims_as_of) and 
month(cr_transaction_date)=month(&claims_as_of))*reserve) as gross_incurred format=12.0,
case when calculated gross_incurred>&caploss then &caploss else calculated gross_incurred end as caploss format=12.0,
case when calculated gross_incurred>&caploss then 1 else 0 end as capcount,
sum(p_amt) as Paid
from actcom.CLAIM_POLICY_PROPERTY
where &filter_comp and &start_date<=CR_LOSS_DATE<=&end_date and 
product_major_line in ("B","C","P") and
cr_transaction_date<=intnx('month',&claims_as_of,1)-1 and
rectype=1
/* HERE THE EQUIVALENT TO SS_CLASS_TYPE1=fclas3 */
group by LINE,CLAIMSYM,CR_CLAIM_NO,CR_LOSS_DATE,CR_OCCURANCE,
fclas3,tou,CR_AUTO_DRIVER_REC_SECA,cr_fire_class,
cr_coverage_cd,kol;
quit;

proc sort data=claims nodupkey;
by LINE CLAIMSYM CR_CLAIM_NO CR_LOSS_DATE CR_OCCURANCE 
fclas3 tou CR_AUTO_DRIVER_REC_SECA cr_fire_class 
cr_coverage_cd kol;
run;

proc sql;
create table claims_sum as
select Year &group_selec, 
sum(claim_cnt) as claim_cnt,
sum(paid) as paid,
sum(gross_incurred) as gross_incurred,
sum(capcount) as capcount,
sum(caploss) as caploss
from claims
group by Year &group_selec
order by Year &group_selec;
quit;

/*CREATES A LABEL ON THE YEAR VARIABLE TO INFORM THE CRITERIA AND CUT-OFF DATES*/
%let label=%sysfunc(compress(%superq(filter_comp),%str(%"))); 
%let label=criteria=%sysfunc(substr(&label,7)) start=&start
end=&end claims_as_of=&claims_as_of_aux;
%put Label=&label;

data &outfile;
merge premium_sum claims_sum;
by Year &group_selec_nocomma;
if claim_cnt=. then claim_cnt=0;
if paid=. then paid=0;
if gross_incurred=. then gross_incurred=0;
if capcount=. then capcount=0;
if caploss=. then caploss=0;
format 
written_exposure earned_exposure 12.2 
written_premium earned_premium gross_incurred caploss paid 12.0;
label Year="&label";
run;
%end;

/*DROPS THE INDIVIDUAL PARAMETER FILES*/
proc sql;
drop table aux %do i=1 %to 11; ,pmts_&i %end;;
quit;

/*proc sql;
drop table premium, premium2, premium3, claims, claims2, contents, aux;
quit;*/
%end;
/* User specified an invalid output filename or unaccessible library */
%else %do;
%put ### ERROR, INVALID OUTPUT FILE: %trim(&outfile);
%end;
options source source2;
%mend;

* %prop_entry_indic;

/* VARIABLES to pick and choose */
%let pick_var0=1;
%let pick_var1=product_major_line; /**/
%let pick_var2=product_line_desc; /*SS_SYUS_BRANCH1 AS_CEDE_POLICY_NO*/
%let pick_var3=division_desc;
%let pick_var4=OFFICE_DESC; /*SS_TRANSACTION_CODE1*/
%let pick_var5=AS_CEDE_POLICY_NO;
%let pick_var6=SS_RISK_NUMBER1;
%let pick_var7=product_line_desc;
%let pick_var8=OFFICE_CODE;
%let pick_var9=SS_PL5_FORM1;
%let pick_var10=kpnwl_code1;
%let pick_var11=business_indicator;
%let pick_var12=property_industry_code;
%let pick_var=&pick_var1;
/* SECOND LIST OF VARIABLES to pick and choose */
%let sec_pick_var0=0;
%let sec_pick_var1=SUB_BROKER_NO; /*SS_LINE_CODE1*/
%let sec_pick_var2=;
%let sec_pick_var=&sec_pick_var1;
/* 1. business indicator */
%let business_indicator0=0;
%let business_indicator1=Fastrax;/*Mid-Market*/
%let business_indicator2=;
%let business_indicator=&business_indicator1;
/* 2. product major line */
%let product_major_line0=0;
%let product_major_line1=P;
%let product_major_line2=C;
%let product_major_line=&product_major_line1;
/* 3. company_number */
%let SS_SYUS_COMPANY0=0;
%let SS_SYUS_COMPANY1=10;
%let SS_SYUS_COMPANY2=;
%let SS_SYUS_COMPANY=&SS_SYUS_COMPANY1;
/* 4. risk_province */
%let risk_province0=0;
%let risk_province1=ALTA;
%let risk_province2=;
%let risk_province=&risk_province1;
/* 5. product */
%let product_line_desc0=0;
%let product_line_desc1=;
%let product_line_desc2=;
%let product_line_desc=&product_line_desc1;
/* 6. branch */
%let SS_SYUS_BRANCH0=0;
%let SS_SYUS_BRANCH1=03;
%let SS_SYUS_BRANCH2=;
%let SS_SYUS_BRANCH=&SS_SYUS_BRANCH1;
/* 7. office code */
%let OFFICE_CODE0=0;
%let OFFICE_CODE1=46P;
%let OFFICE_CODE2=;
%let OFFICE_CODE=&OFFICE_CODE1;
/* 8. Form number */
%let SS_PL5_FORM0=0;
%let SS_PL5_FORM1=210;
%let SS_PL5_FORM2=31;
%let SS_PL5_FORM3=400;
%let SS_PL5_FORM4=;
%let SS_PL5_FORM=&SS_PL5_FORM1;
/* 9. Liability Industry Code */
%let kpnwl_code0=0;
%let kpnwl_code1=5513;
%let kpnwl_code2=;
%let kpnwl_code3=;
%let kpnwl_code=&kpnwl_code1;
/* 10. Risk number */
%let SS_RISK_NUMBER0=0;
%let SS_RISK_NUMBER1=002;
%let SS_RISK_NUMBER2=003;
%let SS_RISK_NUMBER3=004;
%let SS_RISK_NUMBER4=;
%let SS_RISK_NUMBER=&SS_RISK_NUMBER1;
/* 11. Property industry code */
%let property_industry_code0=0;
%let property_industry_code1=1812;/**/
%let property_industry_code2=5812;/*6670*/
%let property_industry_code3=003;
%let property_industry_code4=004;
%let property_industry_code=&property_industry_code1;
/* 12. Policy number 81207476 92200383*/
%let AS_CEDE_POLICY_NO=92200383;
/* cut-off dates */
%let start=200601;
%let end=200912;
%let caploss=100000;
%let claims_as_of=200912;
/* file name */
%let period=monthly;
%let _METAUSER=jsousa;
%let outfile=work.trouble;

%prop_entry_indic;


