/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Wednesday, September 07, 2011     TIME: 3:57:05 PM
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

/*   START OF NODE: Datalines   */
%LET _CLIENTTASKLABEL='Datalines';
%LET _CLIENTPROJECTPATH='/prod/user1/uff597/Check tables and owners on TD.egp';
%LET _CLIENTPROJECTNAME='Check tables and owners on TD.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
/* INSERTS HISTORICAL SOLS.# PRINT COSTS */
/* this is done */
data print_costs;
infile datalines delimiter='09'x dsd firstobs=1;
input 
solicitation_id	
production_cell_id	
print	
inserts	
OE	
Postage	
BRE	
LL	
Postage_with_gst;
cards;
11572	18	37471.73	20616.66	117037.08	11789.51	0	0	0
11572	19	37611.06	50286.48	116356.56	11717.89	0	0	0
11572	20	37605.45	14341.95	116311.46	11716.14	0	0	0
11572	21	18622.32	10261.25	59240.93	5867.87	0	0	0
11572	22	14919.87	8108.08	47579.71	4636.56	0	0	0
11572	23	28151.73	12141.09	126212.08	12661.27	0	0	0
11572	24	4640.86	3911.30	26278.87	837.01	0	0	0
11572	25	48078.55	14981.79	214628.36	21684.26	0	0	0
11572	26	12210.67	6157.35	55255.43	5443.06	0	0	0
;
run;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
