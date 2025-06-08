%Epic;

LIBNAME PLEOMADH SQLSVR  Datasrc=PLEOMADH  SCHEMA=dbo  USER=SAS_Reader  
PASSWORD="{SAS002}5BC89D535C235F65357898EF14F105042E4C9AD6" ;

/* PULLS THE AUTOMATIC DATA THAT GOES INTO THE LEDGER */
/* company codes */
proc sql;
create table Ref_Comp as 
select distinct UW_CMPY_CD,UW_CMPY_NAIC_NBR,UW_CMPY_ABBR
from refdata.wrd_uw_cmpy
where UW_CMPY_ABBR in ("AIE","MVIC","NJSI","NJSIA");
quit;

proc sql;
create table dupes as 
select *
from Ref_Comp
group by UW_CMPY_CD
having count(distinct UW_CMPY_NAIC_NBR)>1;
quit;

/* BY ASL */
proc sql;
create table GL_SAS as
select ASLOB,srcsyscode
,sum(case 
when TransactionType in ('Loss Paid','ALAE','ULAE') then TransactionAmount
when TransactionType in ('Salvage Received','Subrogation',
     'Loss Credit Recovery','ALAE Recovery','ULAE Recovery') then -TransactionAmount
else 0 end)/1000 as Paids
from PLEOMADH.EomLossData a, Ref_Comp b
where 
case when input(a.Company,6.) ne . then put(input(a.Company,6.),z2.) else a.Company end=
case when input(b.UW_CMPY_CD,6.) ne . then put(input(b.UW_CMPY_CD,6.),z2.) else b.UW_CMPY_CD end and
"01jan2019"d<=datepart(EomDate)<="30jun2019"d 
group by 1,2;
quit;

data xxx;
set PLEOMADH.EomLossData(obs=10);
run;

/* LEDGER DATA (final query) */
proc sql;
create table GL_SAS as
select put(year(datepart(EomDate)),z4.)||"Q"||put(ceil(month(datepart(EomDate))/3),z1.) as As_of_Qtr
,case 
 when b.UW_CMPY_ABBR in ("AIE","MVIC") then "AIE"
 when b.UW_CMPY_ABBR in ("NJSI","NJSIA") then "NJS"
 when b.UW_CMPY_ABBR in ("CNIC") then "CNIC" end as Company
,sum(((TransactionType='Loss Paid')-
      (TransactionType in ('Salvage Received','Subrogation','Loss Credit Recovery')))*TransactionAmount)/1000 as Paid_Loss_GL_SAS format=comma12.
,sum(((TransactionType='ALAE')-(TransactionType='ALAE Recovery'))*TransactionAmount)/1000 as Paid_ALAE_GL_SAS format=comma12.
,sum(((TransactionType='ULAE')-(TransactionType='ULAE Recovery'))*TransactionAmount)/1000 as Paid_ULAE_GL_SAS format=comma12.
,sum((month(datepart(EomDate)) in (3,6,9,12))*(TransactionType='Reserve')*TransactionAmount)/1000 as Loss_Res_GL_SAS format=comma12.
from PLEOM.EomLossData a, Ref_Comp b
where 
case when input(a.Company,6.) ne . then put(input(a.Company,6.),z2.) else a.Company end=
case when input(b.UW_CMPY_CD,6.) ne . then put(input(b.UW_CMPY_CD,6.),z2.) else b.UW_CMPY_CD end and
"01jan2019"d<=datepart(EomDate)<="30jun2019"d 
group by 1,2;
quit;

proc freq data=PLEOM.EomLossData;
table EomDate;
run;


proc sql;
create table test as
select datepart(EomDate) as EomDate format=yymmdd10.,count(*)
from PLEOM.EomLossData a
group by 1;
quit;

/* DISCO */

proc sql;
create table GL_SAS as
select put(year(datepart(EomDate)),z4.)||"Q"||put(ceil(month(datepart(EomDate))/3),z1.) as As_of_Qtr,ASL
,case 
 when b.UW_CMPY_ABBR in ("AIE","MVIC") then "AIE"
 when b.UW_CMPY_ABBR in ("NJSI","NJSIA") then "NJS"
 when b.UW_CMPY_ABBR in ("CNIC") then "CNIC" end as Company
,sum(((TransactionType='Loss Paid')-
      (TransactionType in ('Salvage Received','Subrogation','Loss Credit Recovery')))*TransactionAmount)/1000 as Paid_Loss_GL_SAS format=comma12.
,sum(((TransactionType='ALAE')-(TransactionType='ALAE Recovery'))*TransactionAmount)/1000 as Paid_ALAE_GL_SAS format=comma12.
,sum(((TransactionType='ULAE')-(TransactionType='ULAE Recovery'))*TransactionAmount)/1000 as Paid_ULAE_GL_SAS format=comma12.
,sum((month(datepart(EomDate)) in (3,6,9,12))*(TransactionType='Reserve')*TransactionAmount)/1000 as Loss_Res_GL_SAS format=comma12.
from PLEOM.EomLossData a, Ref_Comp b
where 
case when input(a.Company,6.) ne . then put(input(a.Company,6.),z2.) else a.Company end=
case when input(b.UW_CMPY_CD,6.) ne . then put(input(b.UW_CMPY_CD,6.),z2.) else b.UW_CMPY_CD end and
"01jan2019"d<=datepart(EomDate)<="30jun2019"d 
group by 1,2;
quit;