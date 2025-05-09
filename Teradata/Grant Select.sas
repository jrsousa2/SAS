/* GRANT PERMISSION TO USER */
/* automatically executes code with cn_spar TD credentials */
%include "/prod/user1/uff597/.cn_spar";

PROC sql noprint;
SELECT PWD into :cn_pwd
FROM UD156.CN_SPAR_PWD;
quit;

proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&cn_user password=&cn_pwd);
execute(
    grant all on UD155.C_Daily_Fraud_flowdown to uff597;
) by TD;
quit;


proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid. password=&pwd.);
execute (
    grant all on UD156.aml_master to fbq591;
) by TD;
quit;
