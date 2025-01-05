/* PULLS DATA USING ISSUED LIBNAME */
/* THIS SHOULD BE A NON-PASS-THRU QUERY (NOT SURE) */
proc sql;
connect using sys;
    create table My_table as
    select *
    from connection to sys (
        select *
        from sys.all_indexes ind
    );
quit;