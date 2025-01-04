libname TD teradata user=&uid. pw=&pwd. database=ud155 server=oneview;

proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute (
    delete from ud155.uff597_test
    where rownum=8
) by TD;
quit;

/* DROP TABLE */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
    execute (drop table ud155.uff597_PUBLIC_SECT_SALARY2) by TD;
quit;

/* QUERY SAMPLE ROWS */
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table my_table as 
select * from connection to teradata
(
    select *
    from ud155.uff597_PUBLIC_SECT_SALARY
    sample 10;
/*ud155.u99202_c_customer;*/
);
quit;
