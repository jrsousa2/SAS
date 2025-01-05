/* PROC EXPORT-UNIX TO WINDOWS-SERVER OPTION-XLSB */

/* EXPORT TO WINDOWS. IT'S WORKING */
/* CAN ONLY EXPORT AS XLSB (BINARY) */
data Qtrs;
Yr=2001;Qtr=1;output;
Yr=2001;Qtr=2;output;
Yr=2001;Qtr=3;output;
run;

proc export data=Qtrs dbms=excelcs replace outfile="C:\Users\I804745\Documents\Test1.xlsb"; 
sheet="jose";
server="A7S659Y1.AnyServer.com"; 
SERVERUSER="i804745";
SERVERPASS="AnyPwd";
run;



/* PROC EXPORT-UNIX TO WINDOWS-ACCESS DB */

/* THIS ALWAYS WORKS Proc Export */
proc export data=Tri_final outfile="/users/i804745/Tri_Final.xlsx" dbms=xlsx replace;
run;

/* THE BELOW IS USING WRONG SERVER? */
proc export data=Tri_final dbms=accesscs outtable="Test"; ;
database="/users/i804745/Jose.mdb"; 
server="Server\i804745";
SERVERPASS="pwd";
run;

/* EXPORT TO Linux */
proc export data=Tri_final dbms=Accesscs outfile="/users/i804745/HO_Prem_Data.mdb" replace;
run;

/********************************************************************/
/********************************************************************/
/********************************************************************/

data Qtrs;
Yr=2001;Qtr=1;output;
Yr=2001;Qtr=2;output;
Yr=2001;Qtr=3;output;
run;

/* USING THE IP NUMBER IS BETTER (PORT MAY BE NEEDED) */
proc export data=Qtrs dbms=Accesscs table="Test"; 
    database="C:\Users\My Documents\My_db.accdb";
    server="AnyServer"; 
    /*port=9621;*/
    SERVERUSER="i804745";
    SERVERPASS="pwd";
run;


proc product_status;
run;
