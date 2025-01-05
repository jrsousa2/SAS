/* The authentication is via DSN */

libname My_connect oledb 
init_string="Provider=SQLNCLI11;Integrated Security=SSPI; Persist Security Info=True;Initial Catalog=RCM;Data Source=DRQVRCMSQL01,AnyPort#" 
schema=anyschema access=readonly;
