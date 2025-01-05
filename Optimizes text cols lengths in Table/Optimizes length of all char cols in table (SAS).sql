/* THIS MACRO SHRINKS A TABLE SIZE BY RESIZING ALL CHAR COLS IN THE TABLE        */
/* COL LENGTHS ARE RESIZED TO THEIR OPTIMAL SIZE                                 */
/* (I.E., THE MINIMUM LENGTH NEEDED THAT WILL NOT CUT-OFF VALUES UNDER THE COLS) */

/* 1st MACRO (DISPLAYS TABLE SIZE) */
%macro Table_size(Table);
proc sql;
drop table EngineHost, Members;
quit;
 
ods select none;
ods output EngineHost=EngineHost Members=Members;
    proc contents data=&Table memtype=data nodetails;
    run;
ods output close;
ods select all;
 
/*proc printto;*/
/*run;*/
 
proc sql;
    select distinct
    trim(scan(a.member,1,".")) as Lib
    ,trim(scan(a.member,2,".")) as Dataset
    ,max(case when label1="Owner Name" then cValue1 else "" end) as Owner
    ,sum(nValue1)/1024**2 as File_size_Mb
    ,datepart(b.LastModified) as LastModified_date format=mmddyy10.
    ,timepart(b.LastModified) as LastModified_time format=tod8.0
    from EngineHost a left join members b
    on compress(scan(a.member,2,"."))=compress(b.name)
    where label1 in ("File Size (bytes)","Owner Name")
    group by Dataset
    order by File_size_Mb desc, owner;
quit;
%mend;
 
/*****************************************************************/
/*****************************************************************/

/* 2nd MACRO (COMPRESSES THE TABLE) */
%macro shrinks_tbl(Table);
 
/* DISPLAYS TABLE SIZE */
%Table_size(&Table);
 
/* THIS WILL TRIM THE CALLIDUS TABLE TO MAKE IT SMALLER */
%let Vars_Tab=%sysfunc(tranwrd(&Table,.,_))_vars;
 
proc contents data=&Table out=&Vars_Tab(keep=name length type format varnum) noprint;
run;
 
/* DOING ALL THE COLS. */
proc sql noprint;
    select count(*) into :Rows trimmed
from &Vars_Tab;

select case
    when type ne 1 then"max(length('"||trim(name)||"'n)) as '"||trim(name)||"'n"
    else "8"||" as '"||trim(name)||"'n"
    end as Col
    into :Cmds1-:Cmds&Rows
from &Vars_Tab
order by varnum;
quit;
 
%put CMDS1=&cmds1;
%put CMDS2=&cmds2;
%put LAST CMD=&&cmds&Rows;
 
%local i;
proc sql noprint;
    create table Zlens as
    select &cmds1
    %do i=2 %to &Rows;
        ,&&cmds&i
    %end;
from &Table;
quit;
 
/* TRANSPOSES */
proc transpose data=Zlens out=Zlens2;
run;
 
/* ATTACHES TYPE/SHOWS COMPARE */
proc sql;
create table Zlens3 as
    select a.*,b.Type,b.Length
    from Zlens2 a left join &Vars_Tab b
    on a._name_=b.Name
    order by b.varnum;
quit;
 
/* CREATE LENGTHS */
proc sql noprint;
select "'"||trim(_name_)||trim(case
    when type=2
    then "'n $"||compress(put(col1+1,best12.))||"."
    else "'n 8." end) as Len
    into :Lens separated by " "
from Zlens3;
quit;
 
%put LENGTHS=&Lens;
 
/* TRIMS THE TABLE */
/*(compress=binary)*/
data &Table(compress=binary);
    length &Lens;
    format &Lens;
    set &Table;
run;
 
%Table_size(&Table);
%mend;
 
%shrinks_tbl(jose.ZCALLIDUS_210415);


