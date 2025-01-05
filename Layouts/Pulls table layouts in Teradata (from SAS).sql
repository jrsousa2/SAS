-- FROM SAS OF COURSE
-- TABLES
-- TableKind can be V or T (View or Table)
-- SYNTAX BELOW SHOULD BE RIGHT

PROC SQL;
CONNECT TO TERADATA(SERVER=BMG USER="k060..." PASSWORD="????");
create table Table_col_names as
    SELECT *
    FROM CONNECTION TO TERADATA
    (
        SELECT a.DatabaseName as Schema, a.TableName, b.TableKind, a.ColumnName, a.ColumnType 
        from DBC.ColumnsV a
        left join DBC.TablesV b
             on a.DatabaseName=b.DatabaseName and a.TableName=b.TableName
    );
DISCONNECT FROM TERADATA;
QUIT;


PROC SQL;
CONNECT TO TERADATA(SERVER=BMG USER="k060..." PASSWORD="????");
create table Table_names as
    SELECT *
    FROM CONNECTION TO TERADATA
    (
    SELECT DatabaseName as Schema, TableName, TableKind
    FROM DBC.TablesV a
    );
DISCONNECT FROM TERADATA;
QUIT;
