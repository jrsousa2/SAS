/* OLEDB TO SQL SERVER */
LIBNAME My_connect Oledb init_string="Provider=SQLNCLI11;Integrated Security=SSPI;Persist Secruity Info=True;
Initial Catalog=RCM;Data Source=Server name,Port#" schema=anySchema;