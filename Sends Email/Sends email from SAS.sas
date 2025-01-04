%macro xsend_mail;
%if %eval( "%trim(%substr(%sysfunc(time(),time8.),2,1))" eq ":" ) %then %do;
%let Hour=%substr(%sysfunc(time(),time8.),1,1);
%end;
%else %do;
%let Hour=%substr(%sysfunc(time(),time8.),1,2);
%end;
%if &Hour >=12 %then %let Greeting=Good Afternoon;
%else %let Greeting=Good Morning;
 
%let imagefile=/prod/user1/uff597/SASchart.html;
%let Sender=Jose;
%let SenderEmail=jose.sousa@capitalone.com;
%let SendEmails=%str("jose.sousa@capitalone.com");
 
/*%let SendEmails=%str("jose.sousa@capitalone.com" "haritha.sharma@capitalone.com");*/
 
filename outbox email emailid="&SenderEmail"; 
data _null_;
file outbox
to=(&SendEmails.)
subject="BB dashboard"
attach=("&imagefile" content_type='html' extension='html' );
          put "&Greeting.,";
put;
put "The graph is attached.";
put "Let me know if you have any questions.";
put;
put 'Thanks,';
put "&Sender.";
run;
%mend xsend_mail;
%xsend_mail;

