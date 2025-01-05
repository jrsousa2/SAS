/* This should be SQL Server */
proc sql;
create table Indexes as
connect using EDWPVW ;
    select *
    from connection to EDWPVW (
    select *
    from syscat.indexes
    where table_name='xxx' and table_schema='xxx'
);
quit;

