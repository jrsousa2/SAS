%include "/prod/user1/uff597/.saspwd";
libname TD teradata user=&uid. pw=&pwd. database=ud155 server=oneview;

/* INSERT NEW DATA POINT INTO VENDORS TABLE */
data local;
Vendor_id=21;
description="Booth application";
vendor_type="Mail";
run;

/*(bulkload=yes) cannot be used with non-empty tables */
proc append base=TD.u62262_vendor_list data=local;
run;
