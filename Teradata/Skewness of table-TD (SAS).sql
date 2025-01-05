/* Check the skewness of a table: */

SELECT DATABASENAME, CREATORNAME, TABLENAME
       ,SUM(CURRENTPERM)/1024/1024  (DECIMAL(18,2))     SPACE_USED
       ,SUM(SKEWSIZE)/1024/1024        (DECIMAL(18,2))  SKEW_SIZE
       ,SUM(SKEWSIZE)/SUM(CURRENTPERM) (DECIMAL(18,2))  Skew_Ratio
       ,space_used+skew_size TOTAL_SIZE
       FROM  SYSDBA.SKEWINFO
       WHERE DATABASENAME ='UD155'
       and creatorname = 'u96220'
GROUP BY 1,2,3
order by skew_size;

/* this command on sql TD assistant is also useful */
/* this command is the one that runs faster */

select * 
from dbc.tables 
where creatorname='uff597';

/* USING SAS CONNECTION */
proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table Tables as
select * 
from connection to teradata
(
 select DATABASENAME,CREATORNAME,TABLENAME
 from SYSDBA.SKEWINFO
 where DATABASENAME ='UD156'
 and tablename in ('u99202_decl_driver','u99202_resus_cdw')
 group by 1,2,3
);
quit;

