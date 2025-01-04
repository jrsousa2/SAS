-- SAS MACRO LOGIC TO STACK MULTIPLE PROC IMPORTED EXCEL FILES WITH THE SAME LAYOUT
%macro roda;
%let sheet1=Reciprocals;
%let sheet2=P&C;
%let sheet3=A&H;
%let sheet4=P&C-QS;
%let sheet5=P&C-QS-by Seg;
%let sheet6=P&C-Tower;
%let sheet7=P&C-CNI;
%let sheet8=P&C-Std;
%let sheet9=P&C-DG;
%let sheet10=P&C-NatGen;
%let sheet11=P&C-NGLS;
%let sheet12=A&H-US;
%let sheet13=A&H-Europe;
%let sheet14=A&H-US-Assurant;
%let sheet15=A&H-US-Assurant-5200;
%let sheet16=A&H-US-Assurant-5201;
%let sheet17=ARS-4285;
%let sheet18=A&H-US-Self;
%let sheet19=A&H-US-Suppl;

%do i=1 %to 14;
    %do j=3 %to 4;
        proc import out=Tab%sysfunc(putn(&i,z2.))v&j
        datafile="/users/i804745/YTD Summary-2017Q4-by AY-v&j..xlsx" dbms=xlsx replace;
        sheet="&&sheet&i";
        run;

        data Tab%sysfunc(putn(&i,z2.))v&j;
        retain ord 0;
        length File $40.;
        set Tab%sysfunc(putn(&i,z2.))v&j;
        ord=ord+1;
        File="&&sheet&i";
        Ver=1*&j;
        %if "%sysfunc(putn(&i,z2.))"="09"
            %then rename "A&H-DG"n=S;;
        rename "Direct Written Premium"n=Money "Direct Written Premium_1"n=B;
        run;
    %end;
%end;
%mend;
%roda;


/**************************************************************************************/
/* TEST TYPES */
proc contents data=work._all_ out=vars0(keep=LIBNAME nobs memname name type length varnum) noprint;
run;

/* STACK THE TWO TABLES */
data vars1;
    set vars0;
    where substr(memname,1,3)="TAB";
run;

proc sort data=Vars1;
    by Name;
run;

proc transpose data=Vars1 out=Vars_transp;
    var Length;
    by name;
    id memname;
run;

proc transpose data=Vars1 out=Vars_transp2;
    var Type;
    by name;
    id memname;
run;

/************************************************************************************************/
/* TEST FILES */

/* Test types */
proc sql;
    create table Vars1 as
    select upcase(Name) as Name,*
    from vars1
    where nobs>0
    order by memname;
quit;

/* transpose TYPE */
proc transpose data=Vars1 out=Types;
    where upcase(name) not in ("FILE","MONEY","ORD","VER") and type=1;
    var name;
    by memname;
    id varnum;
run;

/* collects variables */
data Types;
    retain Stri ;
    set Types;
    length Stri $30.;
    Stri="";
    array Names{*} $ "1"n-"42"n;
    do i=1 to 42;
    if Names[i] ne ""
        then Stri=trim(Stri)||" "||trim(Names[i])||"="||trim(Names[i])||"2";
    end;
    Stri=compbl(stri);
run;

/* Tables */
proc sql noprint;
/*create table lenghts as*/
    select distinct trim(a.memname)||"(in="||trim(a.memname)||
    case when b.stri is not null then " rename=("||trim(b.stri)||")" else "" end||")" as Arqs 
    into :Arqs separated by " "
    from vars1 a left join Types b on a.memname=b.memname;
    select distinct Name into :Numeric_Cols_spac separated by " "
from vars1
where Nobs>0 and upcase(name) not in ("FILE","MONEY","ORD","VER");
quit;


/* below will change the type of some fields */
proc sql;
    select distinct "if "||trim(a.memname)||" then "||trim(tranwrd(b.stri,"=","=put("))||",32.15);" as Cmds 
    into :Cmds separated by " "
    from vars1 a left join Types b on a.memname=b.memname
    where  b.stri is not null;
quit;
%put ### "&Arqs" ;
%put ### "&Numeric_Cols_spac";
%put ### "&cmds" ;

/* STACK ALL files */
options mprint;
data zcmp;
    retain ord File Money;
    length &Numeric_Cols_Spac $32.;
    set &Arqs;
    &cmds;
run;

/* TREATIES (id's what col belongs to each treaty in each file) */
%macro Transp;
    %global Ini Fim;
    %let Ini=%sysfunc(rank(B));
    %let Fim=%sysfunc(rank(Z)); /* V is the last col I have */

    options mprint;
    proc sql;
    create table Zcmp2 as
        select ord,File,Ver,Money,upcase(byte(&Ini)) as Col,left(trim(%sysfunc(byte(&Ini)))) as Value
        from zcmp
        %do i=%eval(1+&Ini) %to &Fim;
            union all
            select ord,File,Ver,Money,upcase(byte(&i)) as Col,left(trim(%sysfunc(byte(&i)))) as Value
            from zcmp
        %end;
    ;
    quit;
%mend;
%Transp;

/* Final File */
proc sql;
create table Zcmp3 as
    select File,Col,ord,Money
    ,sum((Ver=3)*input(compress(Value),12.)) as V3 format=comma12.3
    ,sum((Ver=4)*input(compress(Value),12.)) as V4 format=comma12.3
    from zcmp2
group by 1,2,3,4;
quit;

data test;
    set zcmp3;
    if 1000*abs(sum(V3,-V4,0))>0.1;
run;

proc sql;
create table Test as
    select File,Col
    ,sum((Ver=3)*input(compress(Value),12.)) as V3 format=comma12.3
    ,sum((Ver=4)*input(compress(Value),12.)) as V4 format=comma12.3
    from zcmp2
group by 1,2;
quit;
