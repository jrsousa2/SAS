/* THIS ONE IS WORKING !!! */
proc import out=BF datafile="C:\My Documents\&File..xlsx" dbms=excelcs replace;
    sheet="DATA";
    server="A7S659Y1.Anyserver.com"; 
    /*port=9621;*/
    SERVERUSER="i804745";
    SERVERPASS="???";
run;
