%let sol_id=11801;

proc sql;

connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);

execute

(

 

update ud155.c_sol from

(

SELECT &sol_id as SOLICITATION_ID, test_cell as TEST_CELL_ID, count(*) as mail_volume

FROM psol.solicitee_info_00&sol_id

GROUP BY 1,2

) r

set mail_volume = r.mail_volume

where 

c_sol.SOLICITATION_ID = r.SOLICITATION_ID and 

c_sol.TEST_CELL_ID=r.TEST_CELL_ID;

 

) 

by TD;

quit;

