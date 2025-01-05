 
/* SCANS DIRECTORY */
%macro Scan_drive(dir,ext,Output,Init=0);
%local filrf rc did memcnt name i;
/* Assigns a fileref to the directory and opens the directory */
%let rc=%sysfunc(filename(filrf,&dir));
%let did=%sysfunc(dopen(&filrf));

/* INITIALIZES TABLE */
/* CREATES TABLE ONLY IN FIRST ITERATION, SINCE IT'S RECURSIVE */
%if &Init
    %then %do;
            data &Output;
            length Filename $200.;
            if Filename ne "";
            run;
          %end;

/* Make sure directory can be open */
/* if you want to see messages about directories that cannot be */
/* opened, uncomment the next line */
%if &did eq 0 
    %then %do;
            %put Directory &dir cannot be open or does not exist;
            %return;
          %end;

/* Loops through entire directory */
%do i=1 %to %sysfunc(dnum(&did));
    /* Retrieve name of each file */
    %let name=%qsysfunc(dread(&did,&i));

    /* Checks to see if the extension matches the parameter value */
    /* If condition is true, inserts value into output table      */
    %if %qupcase(%qscan(&name,-1,.))=%upcase(&ext)
        %then %do;
                /* %put &dir/&name; */
                proc sql;
                    insert into &Output(Filename)
                    values ("&name");
                quit;
              %end;
        /* If directory name call macro again */
        %else %if %qscan(&name,2,.) =
                  %then %drive(&dir/%unquote(&name),&ext,&Output);
%end;

/* Closes the directory and clears the fileref */
%let rc=%sysfunc(dclose(&did));
%let rc=%sysfunc(filename(filrf));

/* GETS MODIFIED DATE AND SIZE OF THE FILES */
data &Output;
    length Path $255. Full_Filename $200.;
    set &Output;
    PATH = "&DIR";
    FULLFILENAME = "&DIR/"||trim(Filename);
    RC=filename("FileRf",trim(Full_Filename));
    Fid=fopen("FileRf");
    Size_Kb=1*finfo(Fid,'File Size (bytes)')/1024;
    Modified_txt = finfo(Fid, "Last Modified");
    Modified_date = input(Modified_txt, datetime18.);
    FC=fclose(Fid);
    RC2=filename("FileRf");
    format Size_Kb comma12. Modified_date datetime18.;
    drop Modified_text;
run;

%mend Scan_drive;
/* SAMPLE Execution */
 
/* DRIVE */
/* 1st pmt is the directory of where the files are stored. */
/* 2nd pmt is the extension you are looking for.           */
/* 3rd pmt is the OUTPUT file */
%Scan_drive(/prod/SalesAnalytics/applications,xlsx,File_List);
 