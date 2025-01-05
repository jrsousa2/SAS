/* COPIES ONLY NEW TABLES (MODIFIED TABLES SINCE LAST BACKUP) */

/* SUPPOSE TABLES HAVE BEEN PREVIOUSLY BACKED UP IN LIB BAK */
/* CHECKS WHICH WORK LIB TABLES HAVE A NEW MODIFIED DATE OR ARE NEW */
/* ONLY THEY WILL BE BACKED UP AGAIN                                */
/* IF TABLES CHANGED NAMES AND MODIFIED, BOTH VERSIONS WILL BE IN BAK */
proc sql;
    select a.memname
    ,cur.modate as CUR_MODIF
    ,sav.modate as SAVED_MODIF
    ,count(distinct cur.memname) as Tables
    into :to_copy separated by "", :None1, :None2, :Nbr_tables
    from dictionary.tables cur
    left join dictionary.tables sav
         on cur.memname = sav.memname and sav.libname = "BAK"
    where cur.libname = "WORK" 
    and (sav.memname = "" or cur.modate>sav.modate);
quit;
/* DISPLAYS MSG IN THE LOG */
%put ### &Nbr_tables tables will be backed up;
%put TO COPY=&to_copy;

/* NOW COPY SELECTED */
proc copy in=WORK out=BAK memtype=data;
    select &to_copy;
run;