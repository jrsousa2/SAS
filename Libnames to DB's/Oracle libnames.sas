/* ESTABLISH CONNECTION FROM SAS */
libname Epic oracle path=EdwClmPr01 schema=anyschema user=anyuser password="???";

libname RefData oracle path=EdwClmPr01 schema=anyschema user=anyuser password="???";

/* Production Environment: */
libname TC1 oracle schema=anyschema path="@ICOMPPC???" authdomain="DefaultAuth" access=readonly;
