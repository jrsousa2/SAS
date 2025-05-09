/* create a table */
CREATE TABLE ud155.u99202_decl_driver_jose  as 
(
    SELECT * 
    FROM ud155.u99202_decl_driver 
) 
with data 
primary index (SOL_REF_NUMBER);
;

/* rename a table */
rename table ud155.PUBLIC_SECT_SALARY to ud155.uff597_PUBLIC_SECT_SALARY;


/* view my tables on TD */
select * 
from dbc.tables where creatorname='uff597';

proc sql;
connect to teradata as TD(mode=teradata server=oneview user=CN_SPAR password=CNSPAR23);
exec (
    delete from table
    where xxx
) by TD;
quit;

/* delete from table */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
exec (
    delete from ud155.uff597_test
    where rownum=1
) by TD;
quit;

/* delete everything */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute (
    DELETE from UD156.xxx;
) by TD;
quit;


/* WITH GRANT OPTION */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&cn_user password=&cn_pwd);
execute (
    grant all on UD156.AML_MASTER_PROD to uff597 WITH GRANT OPTION;
) by TD;
quit;

/* grant all on UD156.C_Daily_Fraud_flowdown to uff597 WITH GRANT OPTION;*/
/* grant permissions */
grant all on ud155.PUBLIC_SECT_SALARY to u62262;


