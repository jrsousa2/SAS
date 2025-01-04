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
