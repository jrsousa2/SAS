/* LIBNAME AND PASS-THRU OR NATIVE */

libname TD teradata user=&uid. pw=&pwd. database=ud155 server=oneview;

proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
select * 
from connection to teradata
(
 select DatabaseName,TableName,CreatorName
 from dbc.tables 
 where TableName in ('u95110_br5_retro_scores');
);
quit;

proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table tables as
select * 
from connection to teradata
(
 select DatabaseName,TableName,Version,TableKind,ProtectionType,JournalFlag,
 CreatorName,CommentString,ParentCount,ChildCount,NamedTblCheckCount,UnnamedTblCheckExist,
 PrimaryKeyIndexId,RepStatus,CreateTimeStamp,LastAlterName,LastAlterTimeStamp,AccessCount,
 LastAccessTimeStamp,UtilVersion,QueueFlag,CommitOpt,TransLog,CheckOpt
 from dbc.tables 
 where DatabaseName='ud156' 
 and substr(TableName,1,23)='ich628_sc_dep_reminder_' 
 and CreateTimeStamp >= '2009-01-01 00:00:00'
 and CreatorName = 'uff597';
);
quit;

proc sql;
connect to teradata(mode=teradata server=oneview user=&uid password=&pwd);
create table tab as
select * from connection to teradata
(
select *
from dbc.databases
where CommentString='Jose Sousa';
);
quit;
