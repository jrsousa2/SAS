/* CREATES REMOTE ON A UNIX/LINUX FOLDER */
%macro create_dir(Folder_path);
%if not %sysfunc(fileexist(&Folder_path))
    %then %do;
            %put ### CREATING FOLDER;
            data _null_;
                x "mkdir 777 &Folder_path";
            run;
          %end;
    %else %put ### FOLDER ALREADY EXISTS;
%mend create_dir;
