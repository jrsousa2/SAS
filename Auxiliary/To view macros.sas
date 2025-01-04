proc catalog catalog=zzz.sasmacr; 
contents; 
run; 

%lib_actcom;

proc catalog catalog=SOURCE.sasmacr; 
contents; 
run; 

/* TO STORE THE MACROS */
/* libname zzz "/sasarea/danalytics/jsousa/Commercial";
options mstored sasmstore=zzz;*/