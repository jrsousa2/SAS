/* Adapted from Layouts/Pulls table layouts from dictionary.sas in         */
/* jrsousa2/SAS. Original technique preserved: a PROC SQL join of          */
/* dictionary.tables to dictionary.columns to pull a table's full layout.  */
/*                                                                          */
/* Substitutions applied:                                                  */
/*  - libname/memname EDW.FIND_ACCTS (external library) replaced with a    */
/*    small mock WORK.FIND_ACCTS table built from the script's own column  */
/*    naming (find_accts / acct-oriented fields) so the join runs against  */
/*    real data instead of an inaccessible external library.               */
/*  - Dropped datarep/num_character/num_numeric from the SELECT list --    */
/*    these are not actual dictionary.tables columns in SAS 9.4 (the       */
/*    dictionary.tables layout is libname/memname/memtype/.../nvar/...,    */
/*    no per-type variable counts); the join + ordering technique itself   */
/*    is unchanged.                                                        */

data work.find_accts;
    length acct_name $20;
    acct_id = 1001; acct_name = "Alpha Corp"; balance = 15000.50; output;
    acct_id = 1002; acct_name = "Beta LLC";   balance =  8250.00; output;
    acct_id = 1003; acct_name = "Gamma Inc";  balance = 42010.75; output;
run;

proc sql;
create table All_layouts as
    select a.libname, a.memname, nobs, crdate, modate, b.*
    , nvar
    from dictionary.tables a
    left join dictionary.columns b
         on a.libname = b.libname and a.memname = b.memname
    where a.libname = "WORK" and a.memname = "FIND_ACCTS";
quit;

proc print data=All_layouts noobs;
    var libname memname name type length varnum;
run;
