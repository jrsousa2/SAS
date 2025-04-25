/* THIS IS FOR THE MAIN REPORT */
/* Creating the excel file for the final report out */
/* This macro sets the formatting style as well as the capablility to use RGB
/* to align with the company's brand center*/
%macro Hex2(n);
%local digits n1 n2;
%let digits = 0123456789ABCDEF;
%let n1 = %substr(&digits, &n / 16 + 1, 1);
%let n2 = %substr(&digits, &n - &n / 16 * 16 + 1, 1);
&n1&n2
%mend Hex2;
 
%macro RGB(R,G,B);
        %cmpres(CX%hex2(&R)%hex2(&G)%hex2(&B))
%mend RGB;
 
/* CREATES the DATES */
%let Today=%sysfunc(today(),worddate20.);
%let FontType = Calibri;
%let Cor=%RGB(0,145,204);
%put &Cor;
 
/* PROC REPORT */
%macroproc_rep(Arq,Start,End,Titu1=,Titu2=,Thresho=,Foot=);
%let Ctcs_Start_txt=%form_date(&Ctcs_Per_Beg);
%let Ctcs_End_txt=%form_date(&Ctcs_Per_End);
%put ### Ctcs_Start_txt=&Ctcs_Start_txt Ctcs_End_txt=&Ctcs_End_txt;
%put &Ctcs_Per_Beg &Ctcs_Per_End;
 
%letCtc_FS_Thresho_perc=%sysevalf(100*&Ctc_FS_Thresho);
%letAg_FS_Thresho_perc=%sysevalf(100*&Ag_FS_Thresho);
%put &Ctc_FS_Thresho_perc &Ag_FS_Thresho_perc;
 
/* TITLES */
title1 j=left font=&FontType height=16pt bcolor=wh bold color=&Cor &Titu1;
title2 j=left font=&FontType height=14pt bcolor=wh bold color=&Cor &Titu2;
 
%if %sysfunc(lowcase(&arq))=met2
    or %sysfunc(lowcase(&arq))=met3
    or %sysfunc(lowcase(&arq))=met6
    %then %let Metric=returned;
     %else %if %sysfunc(lowcase(&arq))=met7
               %then %let Metric=fully_sub;
              %else %let Metric=comm;
%put ### Arq=&arq Metric=&metric;
 
/* REPORT TYPE */
%if &metric=returned
    %then %do;
             %let Extra=%str(Fully_Sub_Ctcs Book_Sub_Perc &Ctcs_CY);
                footnote font=&FontType j=left bcolor=wh color=black height=9pt "Source Systems: EDW, AgentPoint, Dataland and Sales InfoBank";
                footnote2 font=&FontType j=left bcolor=wh color=black height=9pt "Prepared on &Today for mail returned between &Ctcs_Start_txt and &Ctcs_End_txt";
             %end;
     %else %if &metric=fully_sub
              %then %do;
                       %letExtra=%str(Fully_Sub_Ctcs Book_Sub_Perc &Ctcs_CY ratio);
                           footnote font=&FontType j=left bcolor=wh color=black height=9pt "Source Systems: EDW, AgentPoint, Dataland and Sales InfoBank";
                           footnote2 font=&FontType j=left bcolor=wh color=black height=9pt "Prepared on &Today for contracts effective between &Ctcs_Start_txt and &Ctcs_End_txt";
                       %end;
              %else %do;
                       %let Extra=%str(&Total_CY &Total_PY Change Pct_Chg);
                           footnote font=&FontType j=left  bcolor=wh color=black height=9pt "Source Systems: Callidus and AgentPoint";
                           footnote2 font=&FontType j=left bcolor=wh color=black height=9pt "Prepared on &Today for the &Ctcs_Start_txt thru &Ctcs_End_txt Compensation Period";
                       %end;
 
/* PRIOR PERIOD */
%if &metric=comm
%then %do;
           %letPY_CM=%eval(14+%sysfunc(intnx(month,&End,-12)));
           %letTrailStrt2=%eval(14+%sysfunc(intnx(month,&End,-23)));
           %let PY_CM_txt=%form_date(&PY_CM);
           %letTrailStrt2_txt=%form_date(&TrailStrt2);
           %put ### START=&TrailStrt2_txt END=&PY_CM_txt;
      %end;
 
/* FOOTNOTES */
%if &Foot ne %str()
    %then %do; footnote3 font=&FontType j=left bcolor=wh color=black height=9pt &Foot; %end;
 
/* PROC REPORT */
proc report data=&Arq /*style=monochromeprinter */split='|'
style(header)=[font=("&fonttype",14pt) vjust=middle just=center background=&Cor foreground=whitesmoke font_weight=bold]
style(column)=[font=("&fonttype",11pt) vjust=middle background=wh foreground=bl];
cols  
   AOR
   NPN
   Agency
   Agent
   Ctcs
   &Extra
   FFM_Start_&CY_minus_2
   FFM_Start_&CY_minus_1
   AGENT_START
   LICENSE
   OWNER_IND
   Comments
;
define AOR / left "AOR" style=[cellwidth=1.3in];
define NPN / left "NPN" style=[cellwidth=1.3in];
define Agency / left "Agency" style=[cellwidth=3.5in] ;
define Agent / left "Agent" style=[cellwidth=2.1in] ;
define Ctcs / right "Current ctcs | &Ctcs_Start_txt | - &Ctcs_End_txt" style(column)=[cellwidth=1.6in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
 
%if &metric=returned
%then %do;
           define Fully_Sub_Ctcs / right "Fully subsidized| ctcs (&Ctc_FS_Thresho_perc.%) | &Ctcs_Start_txt | - &Ctcs_End_txt" style(column)=[cellwidth=1.5in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
           define Book_Sub_Perc / right "% of Fully|subsidized|ctcs" style(column)=[cellwidth=1.3in TAGATTR='format:#,###.0%;[Red]\(#,###.0)%'];
           define &Ctcs_CY / right "Ctcs w/ | returned mail |&Ctcs_Start_txt | - &Ctcs_End_txt"style(column)=[cellwidth=1.3in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
      %end;
 
%if &metric=fully_sub
%then %do;
           define Fully_Sub_Ctcs / right "Fully subsidized| ctcs (&Ctc_FS_Thresho_perc.%) | &Ctcs_Start_txt | - &Ctcs_End_txt" style(column)=[cellwidth=1.5in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
           define Book_Sub_Perc / right "% of Fully|subsidized|ctcs" style(column)=[cellwidth=1.3in TAGATTR='format:#,###.0%;[Red]\(#,###.0)%'];
           define &Ctcs_CY / right "Fully sub ctcs | wo/ claims |&Ctcs_Start_txt | - &Ctcs_End_txt"style(column)=[cellwidth=1.3in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
      %end;
 
%if &metric=comm
%then %do;
        %if %sysfunc(lowcase(&arq))=met4
               %then %let Aux=Ctcs;
                %else %let Aux=$;
           %if %sysfunc(lowcase(&arq))=met1
               %then %do;
                     %let Per_Ini=%str(&PY_CM_txt | (&Aux));
                           %letPer_Fim=%str(%form_date(&End) | (&Aux));
                        %end;
                %else %do;
                     %letPer_Ini=%str(&TrailStrt2_txt | - &PY_CM_txt | (&Aux));
                           %letPer_Fim=%str(%form_date(&Start) | - %form_date(&End) | (&Aux));
                        %end;
        define &Total_CY / right "&Per_Fim"style(column)=[cellwidth=1.3in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
        define &Total_PY / right "&Per_Ini"style(column)=[cellwidth=1.3in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
           define Change / right "Change | (&Aux)"style(column)=[cellwidth=1.3in TAGATTR='format:###,###,##0_);[Red]\(###,###,##0\)'];
           define Pct_Chg / format=percent12.1right "% of | Change" style(column)=[cellwidth=1.3in TAGATTR='format:#,###.0%;[Red]\(#,###.0)%'];
      %end;
 
define FFM_Start_&CY_minus_2 / format=e8601da10.center "FFM | Registration | Start Date | (&CY_minus_1)" style(column)=[cellwidth=1.3in tagattr="type:DateTime format:mm/dd/yyyy"];
define FFM_Start_&CY_minus_1 / format=e8601da10.center "FFM | Registration | Start Date | (&CY)"style(column)=[cellwidth=1.3in tagattr="type:DateTime format:mm/dd/yyyy"];;
define AGENT_START / format=e8601da10.  center"Agent | Effective | Date" style(column)=[cellwidth=1.3in tagattr="type:DateTime format:mm/dd/yyyy"];
 
define LICENSE / center "Florida | License No."style(column)=[cellwidth=1.3in];
define OWNER_IND / center "Agency | Owner | Indicator" style(column)=[cellwidth=1.3in];
 
%if %sysfunc(lowcase(&arq))=met2
%then %do;
           compute Book_Sub_Perc;
           if Book_Sub_Perc.sum>=0.95
              then call define(_row_,'style','style=[backgroundcolor=lightyellow foreground=black]');
           endcomp;
      %end;
 
%if %sysfunc(lowcase(&arq))=met7
%then %do;
        define ratio / noprint;
           compute ratio;
           if ratio.sum>=0.80
              then call define(_row_,'style','style=[backgroundcolor=lightyellow foreground=black]');
           endcomp;
      %end;
 
%if &metric=comm and &thresho ne %str()
%then %do;
           compute Change;
           if abs(Change.sum)>=&Thresho
              then call define(_row_,'style','style=[backgroundcolor=lightyellow foreground=black]');
           endcomp;
      %end;
 
define Comments / computed format=$10. "Comments"style(column)=[cellwidth=3in];
compute Comments / char;
       Comments="";
endcomp;
run;
title1;
title2;
footnote;
footnote2;
footnote3;
%mend;
 
/* CREATES EXCEL REPORTS */
ods tagsets.ExcelXP file="&Today_Attach_File"path="&Path_Out" 
options (embedded_titles='yes'                  
        frozen_headers='4'
           /*frozen_rowheaders="3"*/
        orientation='landscape' 
        autofilter="all" 
        page_order_across='Yes' 
        autofit_height='Yes' 
        pages_fitwidth='1' 
           /* pages_fitheight='1'  */
        FitToPage='No' 
        index='no' 
        zoom='90' 
        suppress_bylines='yes' 
        rules='none' 
        /* sheet_name='Year View'  */
        gridlines='no' 
        pagebreaks='yes' 
        row_repeat='no' 
        embedded_footnotes='yes' 
           title_footnote_nobreak='yes'
           merge_titles_footnotes = 'yes')
        style=htmlblue;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* MET 1 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 1');
 
%proc_rep(Met1,&TrailStrt,&CY_CM
,Titu1="1) Year-over-Year Changes to Base Commission - Monthly"
,Titu2='Threshold: $15k in base commission'
,Thresho=30000
,Foot="Agents with a variation greater than $30k are highlighted.");
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* MET 2 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 2');
 
%proc_rep(Met2,&Ctcs_Per_Beg,&CY_CM
,Titu1="2) YTD Contracts with Returned Mail for &Ag_FS_Thresho_perc.% Subsidized Book Agents"
,Titu2='Threshold: 30 contracts'
,Foot="Agents with more than 95% subsidized contracts are highlighted");
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* METRIC 3 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 3');
 
/* PROC REPORT */
%proc_rep(Met3,&Ctcs_Per_Beg,&CY_CM
,Titu1='3) YTD Contracts with Returned Mail'
,Titu2='Threshold: 1,500 contracts');
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* METRIC 4 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 4');
 
%proc_rep(Met4,&TrailStrt,&CY_CM
,Titu1="4) Year-over-Year Changes to Contract Count - Rolling 12-month"
,Titu2='Threshold: 3,000 contracts'
,Thresho=4000
,Foot="Agents with a variation greater than 4,000 are higlighted.");
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* METRIC 5 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 5');
 
%proc_rep(Met5,&TrailStrt,&CY_CM
,Titu1="5) Year-over-Year Changes to Base Commission - Rolling 12-month"
,Titu2='Threshold: 250k in base commission'
,Thresho=500000
,Foot="Agents with a variation greater than $500k are highlighted.");
 
%put &TrailStrt &CY_CM;
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* METRIC 6 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 6');
 
/* PROC REPORT */
%proc_rep(Met6,&Ctcs_Per_Beg,&CY_CM
,Titu1='6) YTD Contracts with Service Requests with Fraud-Related Keywords'
,Titu2='Threshold: 20 contracts'
);
 
%error_check;
 
/********************************************************************/
/********************************************************************/
/********************************************************************/
/* METRIC 7 */
ods tagsets.ExcelXP options(sheet_interval='none'sheet_name='Metric 7');
 
%proc_rep(Met7,&Ctcs_Per_Beg,&CY_CM
,Titu1="7) &Ag_FS_Thresho_perc.% Subsidized Book - Claim Analysis"
,Titu2='Fully subsidized contracts without losses'
,Thresho=
,Foot="Ratio (sub contract wo/ claims)/(sub contracts)>=80% is highighted");
 
%error_check;
 
ods tagsets.ExcelXP close;


