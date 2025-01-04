/* Change some values on the test table */
proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute (
	update ud155.uff597_test
	set Surname='aaaa',Given_name='bbbb'
	where rownum=5;
) by TD;
quit;


/* TEST if the order of the variables matter */
data uff597_test;
set sal.PUBLIC_SECT_SALARY(obs=1);
run;

data insert;
	Surname='aaaa';
	rownum=5;
	Given_name='bbbb';
	Position='Deputy Director, Negotiations';
	Taxable_benefits=1;
	Employer='Aboriginal Affairs';
	Salary_Paid=1;
run;

libname TD teradata user=&uid. pw=&pwd. database=ud155 server=oneview;
/*(bulkload=yes) cannot be used with non-empty tables */
proc append data=insert base=TD.uff597_test;
run;



%let sol_id=11801;

proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid password=&pwd);
execute (
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
) by TD;
quit;

