/* MACRO READS A TUPLE WITH N ELEMENTS, E.G. -> (20, 34, 56)         */
/* CREATES A LIST OF THE END-POINTS TO SPLIT A GIVEN FILE            */
/* IN THIS CASE, 3 TIMES, WITH EACH FILE HAVING 20, 34 AND 56 ROWS   */
/* Nobs is the number of records of the table and is a %global var   */
/* that is available within the macro                                */
/* RETURNS N PAIRS (&&START&i, &&END&i) THAT COVER THE TABLE EXACTLY */

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

