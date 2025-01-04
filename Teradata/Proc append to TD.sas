/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Wednesday, September 07, 2011     TIME: 3:56:43 PM
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

/*   START OF NODE: Proc append to TD   */
%LET _CLIENTTASKLABEL='Proc append to TD';
%LET _CLIENTPROJECTPATH='/prod/user1/uff597/Check tables and owners on TD.egp';
%LET _CLIENTPROJECTNAME='Check tables and owners on TD.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
%include "/prod/user1/uff597/.saspwd";
libname TD teradata user=&uid. pw=&pwd. database=ud155 server=oneview;

/* INSERT NEW DATA POINT INTO VENDORS TABLE */
data local;
Vendor_id=21;
description="Booth application";
vendor_type="Mail";
run;

/*(bulkload=yes) cannot be used with non-empty tables */
proc append base=TD.u62262_vendor_list data=local;
run;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
