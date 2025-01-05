/* GRABS ORACLE TABLE INDEX */
proc sql;
connect using sys;
create table Index as
select *
from connection to sys (
    select ind.table_owner, ind.table_name,
    ind.index_name, ind.index_type, ind.uniqueness
    ,LISTAGG(ind_col.column_name, ',')            
    WITHIN GROUP(order by ind_col.column_position) ascolumns
    from sys.all_indexes ind
    join sys.all_ind_columns ind_col  
    on ind.owner = ind_col.index_owner
    and ind.index_name = ind_col.index_name
    where ind.table_name = 'table name'
group by ind.table_owner,ind.table_name,ind.index_name, ind.index_type,ind.uniqueness
);
quit;
