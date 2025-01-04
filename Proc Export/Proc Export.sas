proc export data=ALL_UP
    outfile = "/home/apps/File.xlsx";
    label dbms=xlsx replace;
    sheet="ALL_UP";
run;    