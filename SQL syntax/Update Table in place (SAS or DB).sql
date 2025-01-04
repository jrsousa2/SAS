%let subquery=from Jose.MISSING_ADDRESS as B 
where a.ACCOUNT_ID=b.ACCOUNT_ID;

Proc Sql;
UPDATE finalpop5 as A
SET ADDRESS_ONE = (select ADDRESS_ONE &subquery)
,ADDRESS_TWO = (select ADDRESS_TWO &subquery)
,STATE = (select STATE &subquery)
,ZIP_5 = (select ZIP_5 &subquery)
WHERE a.ACCOUNT_ID in 
(select ACCOUNT_ID 
 from Jose.Missing_address);
 quit;
