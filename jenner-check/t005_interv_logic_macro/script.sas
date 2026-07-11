/* %Interv_logic macro is byte-identical to the source, "Splits file    */
/* based on a Tuple with N numbers.sas" in jrsousa2/SAS. The source file */
/* defines the macro but never calls it (the "SAMPLE Execution" comment  */
/* block shows the intent: a tuple like (20, 34, 56) covering a table    */
/* of N rows). This caller uses that exact example from the source's own */
/* header comment as its Nobs/tuple values.                              */

%macro Interv_logic(Intervals);
%global Fcount;

/* COUNTS NUMBER OF DESIRED SPLITS */
%let Count=%sysfunc(countc(&Intervals, %str(,)));
%let Count=%eval(1+&Count);
%put ### INITIAL NUMBER OF SPLITS=&Count;

/* GRABS THE FILE SIZES */
%do i=1 %to &Count;
    %let Value=%sysfunc(scan(&Intervals,&i,%str(,)));
    %let Rows&i=&Value;
    %put ### I=&i VALUE=&Value ROWS=&&Rows&i;
%end;

/* ENSURES THAT FILE SIZES ENDS WHEN TABLE ENDS */
%let i=0;
%let Fcount=0;
%let Sum=0;
%let Continue=1;
%do %while(&Continue);
    %let i=%eval(&i+1);
    /* ENSURE MACRO VARS CREATED INSIDE MACRO ARE GLOBAL */
    %global START&i END&i;

    /* LOGIC */
    %let START&i=%eval(&Sum+1);
    %let Sum=%eval(&Sum+&&Rows&i);
    %let END&i=%sysfunc(min(&Sum,&Nobs));
    %let Fcount=%eval(&Fcount+1);
    %if (&Sum>=&Nobs) or (&i=&Count)
        %then %let Continue=0;
%end;

/* IF THE NUMBER OF ROWS PROVIDED ISN'T SUFFICIENT TO COVER THE TABLE */
%if &Sum<=&Nobs
    %then %do;
            %put ####;
            %put ### NOBS=&Nobs SUM=&Sum START=&&START&i ROWS=&&Rows&i;
            %let END&i=%eval(&Nobs-&Sum+&&START&i+&&Rows&i-1);
          %end;

%put #### ;
%put #### FINAL NUMBER OF SPLITS=&Fcount;
%put #### ;

/* CHECK IF THE VALUES ARE CORRECT */
%do i=1 %to &Fcount;
    %put ### I=&i START=&&START&i END=&&END&i ROWS=%eval(&&END&i-&&START&i+1);
%end;
%mend Interv_logic;

/* Caller: 110-row table split into (20, 34, 56) rows, matching the      */
/* source's own header-comment example verbatim. The tuple is passed as */
/* one %str()-quoted value since the macro reads it as a single embedded */
/* comma-list, not as separate positional macro parameters.              */
%let Nobs=110;
%Interv_logic(%str(20, 34, 56));

data splits;
    length Split_Num 8 Start_Row 8 End_Row 8 Row_Count 8;
    %do i=1 %to &Fcount;
        Split_Num=&i; Start_Row=&&START&i; End_Row=&&END&i; Row_Count=End_Row-Start_Row+1;
        output;
    %end;
run;

proc print data=splits noobs;
run;
