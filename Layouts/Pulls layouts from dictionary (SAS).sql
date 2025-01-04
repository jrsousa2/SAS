proc sql;
    select libname, memname, name
    from dictionary.columns
    where libname = "XXX" and memname ="FIND_ACCTS";
quit;
