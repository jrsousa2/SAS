/* LISTS SAS TABLES IN A GIVEN LIBRARY IN AN OUTPUT TABLE */
/* DISPLAYS SIZES AND LAST MODIFIED DATE */
%macro owner(library);
proc sql;
drop table EngineHost, Members;
quit;
ods output EngineHost=EngineHost Members=Members;
proc contents data=&library.._all_ memtype=data nodetails;
run;
ods output close;

proc sql noprint;
create table table_info as
    select distinct trim(scan(a.member,1,".")) as lib, 
    trim(scan(a.member,2,".")) as Dataset,
    max(case when label1="Owner Name" then cValue1 else "" end) as Owner,
    sum(nValue1)/1024**2 as File_size_Mb, 
    datepart(b.LastModified) as LastModified_date format=ddmmyy10.,
    timepart(b.LastModified) as LastModified_time format=tod8.0
    from EngineHost a left join members b
        on compress(scan(a.member,2,"."))=compress(b.name)
    where label1 in ("File Size (bytes)","Owner Name")
    group by Dataset
    order by Filesize desc, owner;
quit;
%mend;

%owner(Jose);
