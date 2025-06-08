/*******************************************************************/
/*******************************************************************/
/* TABLE METADATA */

proc sql;
select count(distinct memname)
from vars1
where lowcase(memname) in ("wcr_claim","wcl_expo_tran","wcl_clm","wcl_expo");
quit;

proc contents data=_all_ out=xxx noprint;
run;

data vars1;
set vars1;
where lowcase(memname) in ("wcr_claim","wcl_expo_tran","wcr_claim","wcl_expo");
run;

proc contents data=epic._all_ out=vars1(keep=libname memname varnum name type length format informat) noprint;
run;

proc contents data=RefData._all_ out=vars2(keep=libname memname varnum name type length format informat) noprint;
run;

/* VARS FINAL */
proc sql;
    create table vars as
    select *
    from
    (select *
    from vars1
    union all
    select *
    from vars2)
    where lowcase(memname) in 
    ("wcr_claim" "wcl_expo_tran" "wcl_clm" "wcl_expo"
    'wrd_src_sys' 'wrd_clm_actv_typ ' 'wrd_covg ' 'wrd_st' 'wrd_uw_cmpy_map' 
    'wrd_uw_cmpy' 'wrd_lob_map' 'wrd_lob' 'wrd_chnl' 'wrd_asl_covg');
quit;

-- COPY QUERY HERE
data Str;
length Str $10000.;
str="Qtrs.Month,Qtrs.Beg_Date,Qtrs.End_Date,BAD_DAT_IND
,wcl_expo_tran.clm_nbr,wcl_expo_tran.expo_nbr,wcl_expo_tran.actv_amt,wcl_expo_tran.TWR_MGRT_IND
,wcr_claim.UW_CO,wcr_claim.DOL,wcr_claim.DOR,UW_CMPY_ABBR
,Case
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'LOS' THEN 'Paid Loss'
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'LCR' THEN 'LCR'
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'LAE' AND wcl_expo_tran.alae_ulae_cd = 'A' THEN 'ALAE Rec'
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'LAE' AND wcl_expo_tran.alae_ulae_cd = 'U' THEN 'ULAE Rec'
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'SAL' THEN 'SAL'
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'SUB' THEN 'SUB'
 WHEN wrd_clm_actv_typ.actv_typ_cd IN ('PMT', 'SBX', 'SLX') AND wcl_expo_tran.alae_ulae_cd = 'A' THEN 'ALAE'
 WHEN wrd_clm_actv_typ.actv_typ_cd IN ('PMT', 'SBX', 'SLX') AND wcl_expo_tran.alae_ulae_cd = 'U' THEN 'ULAE'
END as TRANS_CD
,case when wrd_uw_cmpy.uw_cmpy_cd='BAD!!' then 'XX' else wrd_uw_cmpy.uw_cmpy_cd end AS Uw_Cmpy_Cd
,wrd_st.st_cd
,wcl_clm.ls_rept_dt,wcl_clm.pol_nbr,wcl_clm.ls_dt,wcl_clm.src_sys_orgn_cd
,wrd_covg.covg_cd,wrd_covg.gl_covg_cd,wrd_covg.covg_typ_cd,wrd_covg.asl_covg_id

,wcl_expo.LGCY_ASLOB_CD,ASL_COVG_CD
,wrd_clm_actv_typ.actv_typ_cd
,wrd_lob.lob_cd
,wrd_chnl.chnl_cd
case when chk_nbr is null then temp_chk_nbr else chk_nbr end as Check_Number,
,case 
  when wrd_clm_actv_typ.actv_typ_cd='LOS' then wcl_expo_tran.actv_amt 
  when wrd_clm_actv_typ.actv_typ_cd='LCR' then -wcl_expo_tran.actv_amt 
  else 0 end as Paid_Loss
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('SAL','SUB') then -wcl_expo_tran.actv_amt else 0 end as Rec_Loss
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('PMT','SBX','SLX') and wcl_expo_tran.alae_ulae_cd='A' then wcl_expo_tran.actv_amt else 0 end as Paid_ALAE
 ,case when wrd_clm_actv_typ.actv_typ_cd='LAE' and alae_ulae_cd='A' then -wcl_expo_tran.actv_amt else 0 end as Rec_ALAE
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('PMT','SBX','SLX') and wcl_expo_tran.alae_ulae_cd='U' then actv_amt else 0 end as Paid_ULAE
 ,case when wrd_clm_actv_typ.actv_typ_cd='LAE' and wcl_expo_tran.alae_ulae_cd='U' then -wcl_expo_tran.actv_amt else 0 end as Rec_ULAE
FROM Qtrs2 as Qtrs,
     Epic.wcl_expo_tran as wcl_expo_tran,
     Epic.wcl_clm as wcl_clm,
	 Epic.wcr_claim as wcr_claim, 
     Epic.wcl_expo as wcl_expo,
     RefData.wrd_src_sys as wrd_src_sys,
     RefData.wrd_clm_actv_typ as wrd_clm_actv_typ,
     RefData.wrd_covg as wrd_covg,
     Refdata.wrd_st,
     Refdata.wrd_uw_cmpy_map,
     Refdata.wrd_uw_cmpy,
     Refdata.wrd_lob_map as wrd_lob_map,
     Refdata.wrd_lob as wrd_lob,
     Refdata.wrd_chnl
WHERE Qtrs.Month=
and Qtrs.Beg_Date<wcl_expo_tran.tran_ld_dtm<=Qtrs.End_Date
AND wcl_expo_tran.clm_nbr = wcl_expo.clm_nbr = wcl_clm.clm_nbr = wcr_claim.clm_nbr
and wcl_expo.expo_nbr = wcl_expo_tran.expo_nbr
and wcr_claim.UW_CO in ()
AND wcl_clm.src_sys_orgn_cd in () or
AND wrd_src_sys.src_sys_id in (17,18) 
and wcl_expo_tran.TWR_MGRT_IND is null
AND wcl_clm.clm_eff_dtm <= Qtrs.End_Date and (wcl_clm.clm_exp_dtm IS NULL OR wcl_clm.clm_exp_dtm > Qtrs.End_Date)
AND wcl_clm.src_sys_id = wrd_src_sys.src_sys_id
AND wrd_clm_actv_typ.actv_typ_id = wcl_expo_tran.actv_typ_id
AND wrd_clm_actv_typ.actv_typ_id IN (30, 31, 32, 39, 48, 56, 62, 63)
AND wrd_clm_actv_typ.actv_typ_cd IN ()
AND wcl_expo.entps_covg_cd_id = wrd_covg.covg_id
AND wcl_expo.expo_eff_dtm <= Qtrs.End_Date and (wcl_expo.expo_exp_dtm IS NULL OR wcl_expo.expo_exp_dtm > Qtrs.End_Date)
AND wrd_covg.covg_unof_covg_ind = 
AND wcl_expo_tran.row_log_del_ind=wcl_expo.row_log_del_ind=wcl_clm.row_log_del_ind='N'
AND wcl_expo_tran.rec_src_cd = 
AND wcl_clm.uw_cmpy_map_id = wrd_uw_cmpy_map.uw_cmpy_map_id
AND wrd_uw_cmpy.uw_cmpy_id = wrd_uw_cmpy_map.entps_uw_cmpy_id
AND wcl_clm.rt_st_id = wrd_st.st_id
AND wcl_clm.lob_map_id = wrd_lob_map.lob_map_id
AND wrd_lob.lob_id = wrd_lob_map.entps_lob_id
AND wrd_chnl.chnl_id = wcl_clm.chnl_id";
run;

/* MAIN PART */
proc sql;
    create table Sel as
    select a.*
    from vars a, Str b
    where index(lowcase(b.Str),trim(lowcase(a.name)))>0;
quit;


/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/***************************************************************************************************/
/* CODE */
proc sql;
select 
    case when format="DATETIME" 
        then "datepart("||trim(name)||") as "||trim(name)||" format=yymmdd10." 
        else name end as Col
    ,Libname,Memname
    into :Cmds separated by ",",:Lib,:Tabe
    from Sel
    where lowcase(memname)="wcr_claim";
quit;

%put Cmds="&cmds";
%put Library=&Lib;
%put Table=&Tabe;

proc sql;
create table jose.&Tabe as
select &Cmds
    from &Lib..&Tabe
    where UW_CO in ('AIE','MVIC','NJSI','NJSIA');
quit;

%macro load;
%let Tab1=wcl_expo_tran;
%let Tab2=wcl_clm;
%let Tab3=wcl_expo;

%do i=1 %to 1;
    proc sql;
    select case when format="DATETIME" 
    then "datepart("||trim(name)||") as "||trim(name)||" format=yymmdd10." 
    else name end as Col,Libname,Memname
    into :Cmds separated by ",",:Lib,:Tabe
    from sel
    where lowcase(memname)=lowcase("&&Tab&i");
    quit;
    %put Cmds="&cmds";
    %put Library=&Lib;
    %put Table=&Tabe;

    proc sql;
    create table jose.&Tabe as
    select &Cmds
    from &Lib..&Tabe
    where clm_nbr in (select clm_nbr from jose.wcr_claim);
    quit;
%end;
%mend;
%load;

%macro load;
%let Tab1=wrd_src_sys;
%let Tab2=wrd_clm_actv_typ;
%let Tab3=wrd_covg;
%let Tab4=wrd_st;
%let Tab5=wrd_uw_cmpy_map;
%let Tab6=wrd_uw_cmpy;
%let Tab7=wrd_lob_map;
%let Tab8=wrd_lob;
%let Tab9=wrd_chnl;
%let Tab10=WRD_ASL_COVG;

%do i=1 %to 10;
    proc sql;
    select case when format="DATETIME" 
    then "datepart("||trim(name)||") as "||trim(name)||" format=yymmdd10." 
    else name end as Col,Libname,Memname
    into :Cmds separated by ",",:Lib,:Tabe
    from Sel
    where lowcase(memname)=lowcase("&&Tab&i");
    quit;
    %put Cmds="&cmds";
    %put Library=&Lib;
    %put Table=&Tabe;

    proc sql;
    create table jose.&Tabe as
    select &Cmds
    from &Lib..&Tabe;
    quit;
%end;
%mend;
%load;


