/* PULL DATA FROM TD */
/* BY NOT SPECIFYING A SCHEMA TABLES FROM MULTIPLE SCHEMAS CAN BE USED AT THE SAME TIME */
/* USEFUL WHEN JOINING TABLES IN DIFFERENT SCHEMAS */
proc sql;
connect to teradata as TD(SERVER=oneview USER="&uid" PASSWORD="&pwd");
CREATE TABLE Test AS
select *
from connection to teradata
(
    SEL *
    from ud155.c_solicitation
    where SOLICITATION_ID in (11801)
);
disconnect from teradata;    
quit;

