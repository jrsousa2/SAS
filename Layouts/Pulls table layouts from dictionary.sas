/* YOU CAN PROBABLY DROP 
/* informat idxusage sortedby xtype notnull */
/* precision scale transcode npos memtype   */
proc sql;
create table All_layouts as
    select a.libname, a.memname, nobs, crdate, modate, b.*
    , nvar, datarep, num_character, num_numeric
    from dictionary.tables a
    left join dictionary.columns b
         on a.libname = b.libname and a.memname = b.memname
    where a.libname = "EDW" and memname ="FIND_ACCTS";
quit;
