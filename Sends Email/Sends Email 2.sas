%macro xsend_mail;
%global subj;
%if &failure_test=1
    %then %let subj=%str(Online batch has succeeded);
    %else %let subj=%str(Online batch has failed);
 
%put &subj &failure_test &SYSERRORTEXT;;
 
/*%let imagefile=/prod/user1/uff597/sasgraph.gif;*/
%let Sender=Jose;
%let SenderEmail=jose.sousa@capitalone.com;
%let SendEmails=%str(jose.sousa@capitalone.com);

filename outbox email emailid="&SenderEmail"; 
data _null_;
set recs;
file outbox
to="&SendEmails."
subject="&subj";
/*attach=("&imagefile" content_type='image/gif' extension='gif' );*/
if _n_=1
then do;
if &failure_test=1
    then put "&SYSERRORTEXT";
put;
put "Let me know if you have any questions.";
put;
put "&Sender.";
put;
put "Record counts of TD and SAS files:";
put;
put " GO129 SAS_recs    TD_recs";
end;
put GO129 9. SAS_recs 10. TD_recs 10.;
run;
 
%mend xsend_mail;
%xsend_mail;

