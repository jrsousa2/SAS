/* create a NEW table in the TD database */
/* DEFINE INDEX COLS AT THE SAME TIME */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute (
CREATE TABLE Schema.Table_name AS
    (
    SEL *
    from ud155.c_solicitation
    )
WITH DATA PRIMARY INDEX (ACCT_NUM);
) by TD;
quit;

/* CHECK LOAD */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
create table Check_load as 
select
from connection to teradata
(
    SEL count(*) as N
    from Schema.Table_name
)
disconnect from teradata;
quit;