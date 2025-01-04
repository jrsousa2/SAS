/*create a table in TD */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute
(
CREATE TABLE ud155.c_sol AS
(
SEL *
from ud155.c_solicitation
where SOLICITATION_ID in (11801)
)
WITH DATA
PRIMARY INDEX (SOLICITATION_ID,TEST_CELL_ID);
) 
by TD;
quit;

