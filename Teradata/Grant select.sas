/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Wednesday, September 07, 2011     TIME: 3:56:31 PM
PROJECT: Check tables and owners on TD
PROJECT PATH: /prod/user1/uff597/Check tables and owners on TD.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data
 set. */
	    /* Construct dsn that will be unique for each concurrent session under a
 particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		Note:  This does NOT support users who do not have an HFS home directory.
		It also may not support multiple simultaneous sessions under the same account.
		*/
		filename egtmpdir './';                          
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
        %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide

ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport12(ID=EGSRX) FILE=EGSRX STYLE=Analysis STYLESHEET=(URL=
"file:///C:/Program%20Files/SAS/SharedFiles/BIClientStyles/4.2/Analysis.css")
 NOGTITLE NOGFOOTNOTE GPATH=&sasworklocation ENCODING=UTF8 options(rolap="on");

/*   START OF NODE: Grant select   */
%LET _CLIENTTASKLABEL='Grant select';
%LET _CLIENTPROJECTPATH='/prod/user1/uff597/Check tables and owners on TD.egp';
%LET _CLIENTPROJECTNAME='Check tables and owners on TD.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
/* automatically executes code with cn_spar TD credentials */
%include "/prod/user1/uff597/.cn_spar";

PROC sql noprint;
SELECT PWD into :cn_pwd
FROM UD156.CN_SPAR_PWD;
quit;

proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&cn_user
 password=&cn_pwd);
execute
(
grant all on UD155.C_Daily_Fraud_flowdown to uff597;
) 
by TD;
quit;


proc sql;
connect to teradata as TD(mode=teradata server=oneview user=&uid.
 password=&pwd.);
execute
(
grant all on UD156.aml_master to fbq591;
) 
by TD;
quit;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
