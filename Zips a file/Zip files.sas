%macro Zip(Filename);
%let Path=/home/apps/;
%let fullname=&Path/&Filename..xlsx;

ods package(ProdOutput) open nopf;
ods package(ProdOutput) add file="&fullname";
ods package(ProdOutput) publish archive
properties(archive_name="&Filename..zip" archive_path="&Path");
ods package(ProdOutput) close;
%mend;

%Zip(File1);
%Zip(File2);
%Zip(File3);

