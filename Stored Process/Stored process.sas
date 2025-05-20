options validvarname=any;
 
/* LOG/OUTPUT FOLDERS */
%global Path_Code Path_Log Today_Attach_File Today_Dt;
%let Folder=Active;
%let Path_Out=/u/&SYSUSERID/sasuser.v94;
%let Path_Log=/u/&SYSUSERID/Log;
/* DATES */
%letToday_Dt=%sysfunc(putn(%sysfunc(date()),yymmddn8.));
%put #### &Today_Dt;
%let Hora=%sysfunc(putn(%sysfunc(time()),time12.));
%put #### &Hora;
%let Today_Dt=&Today_Dt._%trim(&Hora);
%let Today_Dt=%sysfunc(tranwrd(&Today_Dt,:,_));
%put #### Today_Dt=&Today_Dt;
%let Today_Attach_File = %quote(&SYSUSERID (Run &Today_Dt).xlsx);
%put #### Today_Attach_File=&Today_Attach_File;
%letToday_Output=&SYSUSERID._run_%sysfunc(tranwrd(&Today_Dt,:,_));
%put #### Today_Output=&Today_Output;
 
/* E-MAIL */
/* SENDS EMAILS */
%let Run_Check=TRUE;
%let Subject=Stored Process;
%let Path_Log;
%let Error_report_file=;
%let Yester_Attach_File=@@@;
%let Log_file=;
%let Some_Not_Empty=1;
%let RC=0;
%let RUN_TIME=0;
%let NO_MSGS=0;
%let Path_Xlsb=%str(\\somecompany.com\xdivision\Apps-Shared Data\Apps-Compensation\IC-Business\Monthly Automated Tasks\AMF Reconciliation);
 
data _null_;
User=compress(&_METAPERSON,"");
User_first=scan(User,2,",");
User_Last=scan(User,1,",");
Email=trim(User_first)||"."||trim(User_last)||"@somecompany.com";
call symput("UserEmail2",Email);
run;
/* CREATES EMAIL ADDRESS */
%let Email=%str(&UserEmail)@somecompany.com;
 
/* ORDER VARIABLES */
%let Ret_Vars=
;
 
/* RENAME AND EXPORT MACRO */
%macroExporta(Input,Outfile,Format=xlsx,Templa=data,proc_exp=1);
%global Not_Empty;
 
%if %sysfunc(exist(&Input))
%then %do;
         options nomprint;
           /* PROC EXPORT */
         proc export data=&Input outfile="&Path_Out/&Outfile"
         dbms=xlsx label replace;
           sheet="&Templa";
         run;
           options nomprint;
      %end;
 
/* CHECK IF EXCEL FILE IS BIGGER THAN 18MB */
%global SizeMb FileTooBig;
data _null_;
length FileSizeStr $40.;
FE=fileexist("&Path_Out/&Today_Attach_File");
Rc = filename("Filerf","&Path_Out/&Today_Attach_File");
Fid=fopen("Filerf");
FileSizeStr=finfo(Fid,'File Size (bytes)');
SizeMb=round(FileSizeStr/1024**2,0.01);
FileTooBig=(SizeMb>18);
call symput("SizeMb",SizeMb);
call symput("FileTooBig",FileTooBig);
run;
 
/* CLEANS-UP */
%let SizeMb=%trim(&SizeMb);
%let FileTooBig=%trim(&FileTooBig);
%put EXCEL_FILE_SIZE="&SizeMb" FileTooBig="&FileTooBig";
%mend;
 
/*Change the macro racf to be your racf*/
%macro send_email(Subj=,Recips=,CC=,Attach=);
%local i Error_Rep;
 
/* if 2nd run, don't send to everybody */
%if%sysfunc(fileexist("&Path_Out/&Yester_Attach_File"))
    %then %let Recips=%str(jose.sousa@somecompany.com);
/* IF RUN_CKECK FALSE DON'T SEND TO EVERYBODY */
%if &Run_Check=FALSE
    %then %let Recips=%str(jose.sousa@somecompany.com);
/* IF FILE NOT FOUND DON'T SEND TO EVERYBODY */
%if not%sysfunc(fileexist(&Path_Out/&Today_Attach_File))
    %then %let Recips=%str(jose.sousa@somecompany.com);
 
%if %sysfunc(index(%quote(&Subj),Error))>0
    or %sysfunc(index(%quote(&Subj),Log))>0
    %then %let Error_Rep=1;
     %else %let Error_Rep=0;
 
/* E-MAIL */
Filename MYEMAIL Email
   Subject = "&Subj"
   To      = (&Recips)
   From    = (jose.sousa@somecompany.com)
   CC      = (&CC)
   Type = "text/html"
   Attach = (
   %if (not &Error_rep)
       and &Some_Not_Empty
       and%sysfunc(fileexist(&Path_Out/&Today_Attach_File))
        and (not &FileTooBig)
       %then "&Path_Out/&Today_Attach_File"content_type="application/vnd.ms-excel";
 
   %if &Error_rep
       %then %do;
                   %if%sysfunc(fileexist(&Path_Log/&Error_report_file))
                      %then"&Path_Log/&Error_report_file"content_type="application/vnd.ms-excel";
                  %if%sysfunc(fileexist(&Path_Log/&Log_file))
                       %then "&Path_Log/&Log_file"content_type="application/vnd.ms-excel";
             %end;
  "/prod/SalesAnalytics/appdata/shared/Images/TeamLogo.png");
 
/* MESSAGES */
Data _Null_ ;
  File MYEMAIL;
  put '<body style=font-size:11pt;font-family:Times New Roman>';
 
  /* LOG/ERROR REPORT */
  if &Error_rep
     then do;
            put "Code has taken <b>&run_time.</b> (H:M:S) to run (max RC=&RC).";
               if fileexist("&Path_Log/&Error_report_file")
                  then put "<p><i>Error report attached.</i>";
                   else put "<p><i>Error report not found.</i>";
               if fileexist("&Path_Log/&Log_file")
                  then put "<p><i>Log file attached.</i>";
                   else put "<p><i>Log file not found.</i>";
             end;
 
  /*OUTPUT */
  if not &Error_rep
     then if fileexist("&Path_Out/&Today_Attach_File") and (not &FileTooBig)
             then if &Some_Not_Empty
                     then do;
                                 %do i=1 %to&No_Msgs;
                                 put &&Msg&i; 
                             %end;;
                          end;
                          else put "<p><i>The file is empty, so there is no attachment.</i>";
              else if &FileTooBig
                     then do;
                                   put "<b>Period:</b> N/A";
                                put "<p>File is too big for attachment (&SizeMb.Mb)</i>";
                               end;
 
  select;
  when (&Error_rep);
  when ("&Run_Check"="FALSE")
        do;
          put "<b>The data is not ready.</b>";
        end;
  when ((not &Error_rep) and "&Run_Check"="TRUE"and fileexist("&Path_Out/&Yester_Attach_File"))
        do;
          put "<b>The code has already run yesterday.</b>";
        end;
  otherwise;
  end;
 
  put "<p><img src=""TeamLogo.png"" width=160 height=60></img>";
run;
Filename MYEMAIL Clear;
%mend;
 
/* QUERY */
%macro Pmts;
%global Filter Var_List Var_List_NoComma No_of_Vars;
 
/* AGENCY COL. */
%let Agency_Col=%str(case
     when s.COMPENSATIONDATE >= '01-OCT-2019'
     then s.genericattribute1
     else s.genericattribute2 end);
 
/* AGENT COL. */
%let Agent_Col=%str(case
     when S.COMPENSATIONDATE >= '01-OCT-2019'
     then s.genericattribute2
     else s.genericattribute4 end);
 
/* AOR SWITCH */
%if &AOR_Type = Y
    %then %let AOR_Col=&Agency_Col;
    %else %let AOR_Col=%str(pa.GENERICATTRIBUTE1);
 
/* PREM SWITCH */
%if &Prem_Type = T
    %then %let Prem_Col=%str(s.VALUE);
    %else %if &Prem_Type = C
              %then %let Prem_Col=%str(c.VALUE);
                  %else %let Prem_Col=%str(CASE
                                        WHEN S.GENERICBOOLEAN1 = 1 THEN 0
                                        WHEN S.GENERICBOOLEAN3 = 1 THEN 0
                                        WHEN C.VALUE IS NULL THEN 0
                                       ELSE C.VALUE
                                       END);
 
/* EVAL MONTH */
%let Filter=S.COMPENSATIONDATE>=&EvalMonth;
 
/* CONTRACTS */
%if &Contracts ne %str()
    %then %let Filter=&Filter and s.genericattribute26 in (&Contracts);
 
/* GROUPS */
%if &Groups ne %str()
    %then %let Filter=&Filter and s.genericattribute12 in (&Groups);
 
/* AOR CODES */
%if &AOR_Codes ne %str()
    %then %let Filter=&Filter and trim(&AOR_Col) in (&AOR_Codes);
 
/* AGENCY/AGENT */
%if %quote(&Agency_Agent) ne %str()
    %then %let Filter=&Filter and trim(&AOR_Col)||'-'||trim(&Agent_Col) in (%quote(&Agency_Agent));
 
/* DIM. VARIABLES */
%let DimVars1=&DimVars;
 
%do i=1 %to &DimVars_count;
    %if &i=1
        %then %let DimVars_List=&DimVars1;
           %else %letDimVars_List=%str(&DimVars_List,&&DimVars&i);
%end;
 
/* DIM. VARIABLES-NULL*/
%let NullVars1=&NullVars;
 
%do i=1 %to &NullVars_count;
    %letDimVars_List=%str(&DimVars_List,&&NullVars&i);
%end;
 
/* NUMERIC VARIABLES */
%let Metrics1=&Metrics;
 
%do i=1 %to &Metrics_count;
    %if &i=1
        %then %let Metrics_List=&Metrics1;
           %else %letMetrics_List=%str(&Metrics_List,&&Metrics&i);
%end;
 
/* UNITES DIM AND NUM VARIABLES */
%let Vars_List=%str(&DimVars_List,&Metrics_List);
%letVars_List_NoComma=%sysfunc(tranwrd(&Vars_List,%str(,), ));
 
/* LIST OF SUMMED UP VARS. */
%let Vars_Sum_List=;
%do i=1 %to &Metrics_count;
%if &i=1
    %then %let Vars_Sum_List=%str(,sum(&&Metrics&i) as &&Metrics&i);
    %else %letVars_Sum_List=%str(&Vars_Sum_List,sum(&&Metrics&i) as &&Metrics&i);
%end;
 
/* PROD DESC */
%let ProdDescs1=&ProdDescs;
 
%do i=1 %to &ProdDescs_count;
    %if &i=1
        %then %letProdDesc_List=%str(%')&ProdDescs1%str(%');
           %else %letProdDesc_List=%str(&ProdDesc_List,%str(%')&&ProdDescs&i%str(%'));
    %if &i=&ProdDescs_count
         %then %let Filter=&Filter and s.productdescription in (&ProdDesc_List);
%end;
 
/* PROD NAME */
%let ProdNames1=&ProdNames;
 
%do i=1 %to &ProdNames_count;
    %if &i=1
        %then %letProdName_List=%str(%')&ProdNames1%str(%');
           %else %letProdName_List=%str(&ProdName_List,%str(%')&&ProdNames&i%str(%'));
    %if &i=&ProdNames_count
         %then %let Filter=&Filter and s.productname in (&ProdName_List);
%end;
 
/* EVENTS */
%let Events1=&Events;
 
%do i=1 %to &Events_count;
    %if &i=1
        %then %letEvent_List=%str(%')&Events1%str(%');
           %else %letEvent_List=%str(&Event_List,%str(%')&&Events&i%str(%'));
    %if &i=&Events_count
         %then %let Filter=&Filter and e.eventtypeid in (&Event_List);
%end;
 
/* DISPLAY */
%put #### DimVars=&DimVars_count;
%put #### Metrics=&Metrics_count;
%put #### ProdDescs=&ProdDescs_count;
%put #### Prod Names=&ProdNames_count;
%put #### Events=&Events_count;
%put #### FILTER=&FILTER;
%put #### VARS_LIST=&VARS_LIST;
%put #### Vars_List_NoComma=&Vars_List_NoComma;
%put #### DimVars_List=&DimVars_List;
%put #### Metrics_List=&Metrics_List;
%put #### Vars_Sum_List=&Vars_Sum_List;
%put #### EMAIL=&Email;
%put #### SYSUSERID=&SYSUSERID;
%put #### VARNAME=%sysfunc(getoption(validvarname));
%put ### _all_;
/*%put MYNOTE: *** %sysfunc(getoption(config)) ***;*/
 
 
/* ORACLE QUERY */
%put BEGIN ORACLE QUERY;
 
/* MAIN QUERY */
proc sql;
connect to oracle as myconn(path='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)
(HOST=orap24)(PORT=1582))(CONNECT_DATA=(ORACLE_SID=?????)))' authdomain='DefaultAuth');
create table zComp as
select * from connection to myconn
(Query
WHERE &Filter
);
quit;
%put END ORACLE QUERY;
 
libname Mylib "&Path_Out";
 
/* SUMMARIZES THE DATA */
proc sql;
create table Mylib.&Today_Output as
select &DimVars_List &Vars_Sum_List
from zComp
group by &DimVars_List;
quit;
 
/* FINAL STEP */
options label;
data Mylib.&Today_Output;
%if &NullVars_count>0
    %then retain &Ret_Vars;;
set Mylib.&Today_Output;
Label &Labels;
keep &Vars_List_NoComma;
run;
%mend;
%pmts;
 
/* EXPORTS TO EXCEL */
%exporta(Mylib.&Today_Output,&Today_Attach_File,Templa=Data);
 
/* OUTPUT */
%send_email(
Subj=%quote(&Subject Output)
,CC=%str("&Email")
);


