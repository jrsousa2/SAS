/* DEEPU */

%Epic;

%macro Qtrs;
data Qtrs;
%do Year=2006 %to 2019;
 %do Qtr=1 %to 4;
	 Month=mdy(3*&Qtr,1,&year);
     Next_Mo=intnx("month",Month,1)-1;
	 End_Date=Next_Mo;
	 count=0;
	 do until(count=2);
	   if weekday(End_Date)=6
	      then count=count+1;
	   if count<2 then End_Date=End_Date-1;
	 end;
	 Acctg_Yr=&Year;
	 Acctg_Qtr=&Qtr;
     Cut_Off=mdy(3*Acctg_Qtr,1,Acctg_Yr);
     Acct_YYYYMM=100*Acctg_Yr+3*Acctg_Qtr;
	 Aux=End_Date;
     if 100*Acctg_Yr+Acctg_Qtr in (201804,201902)
	    then output;
 %end;
%end;
format Month Next_Mo End_Date Aux Cut_Off yymmdd10.;
drop count;
run;
%mend;
%Qtrs;

/* Create begin cut-offs for MTD pull */
%let Beg_Date=14609;/* EQUIVALE A "01jan2000"-1*/
data Qtrs2;
	retain Month Next_Mo Beg_Date End_Date;
	set Qtrs(rename=(End_date=End_Date));
	format Beg_Date yymmdd10.;
	Beg_Date=coalesce(1*symget("Beg_Date")+1,month);
	call symput("Beg_Date",End_Date);
run;

/* query */
proc sql;
create table jose.zDeepu_YTD_Recips as
SELECT 
 Qtrs.Month,Qtrs.Beg_Date,Qtrs.End_Date,wcl_expo_tran.BAD_DAT_IND
,wcl_expo_tran.clm_nbr,wcl_expo_tran.expo_nbr,wcl_expo_tran.actv_amt,wcl_expo_tran.TWR_MGRT_IND
,wcr_claim.UW_CO,wcr_claim.DOL,wcr_claim.DOR,wrd_uw_cmpy.UW_CMPY_ABBR,wrd_uw_cmpy.uw_cmpy_cd
,Case
 WHEN wrd_clm_actv_typ.actv_typ_cd = 'LOS' THEN 'Loss'
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
,wcl_clm.Ls_Rept_Dt,wcl_clm.pol_nbr,wcl_clm.ls_dt,wcl_clm.src_sys_id,wcl_clm.src_sys_orgn_cd
,wrd_src_sys.SRC_SYS_CD,wrd_src_sys.SRC_SYS_DESC

/* ASL */
,wrd_chnl.chnl_cd,wrd_covg.covg_cd,wrd_covg.gl_covg_cd,wrd_covg.covg_typ_cd,wrd_covg.asl_covg_id
,wrd_lob.lob_cd,wcl_expo.LGCY_ASLOB_CD,WRD_ASL_COVG.ASL_COVG_CD
,case when wrd_src_sys.src_sys_id = 12
 then case when wrd_lob.lob_cd ='HOME' and wrd_asl_covg.asl_covg_cd in ('192') then '040'
           when wrd_covg.covg_typ_cd is null and  wrd_lob.lob_cd ne 'HOME' then '192'
           else wrd_asl_covg.asl_covg_cd end 
 else coalesce(wcl_expo.LGCY_ASLOB_CD,WRD_ASL_COVG.asl_covg_cd) end as ASL

,wrd_clm_actv_typ.actv_typ_cd

/*case when chk_nbr is null then temp_chk_nbr else chk_nbr end as Check_Number,*/
/* MONEYS */
,case 
  when wrd_clm_actv_typ.actv_typ_cd='LOS' then wcl_expo_tran.actv_amt 
  when wrd_clm_actv_typ.actv_typ_cd='LCR' then -wcl_expo_tran.actv_amt 
  else 0 end as Paid_Loss
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('SAL','SUB') then -wcl_expo_tran.actv_amt else 0 end as Rec_Loss
/* ALAE */
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('PMT','SBX','SLX') and wcl_expo_tran.alae_ulae_cd='A' then wcl_expo_tran.actv_amt else 0 end as Paid_ALAE
 ,case when wrd_clm_actv_typ.actv_typ_cd='LAE' and alae_ulae_cd='A' then -wcl_expo_tran.actv_amt else 0 end as Rec_ALAE
/* ULAE */
 ,case when wrd_clm_actv_typ.actv_typ_cd in ('PMT','SBX','SLX') and wcl_expo_tran.alae_ulae_cd='U' then actv_amt else 0 end as Paid_ULAE
 ,case when wrd_clm_actv_typ.actv_typ_cd='LAE' and wcl_expo_tran.alae_ulae_cd='U' then -wcl_expo_tran.actv_amt else 0 end as Rec_ULAE
FROM Qtrs2 as Qtrs,
jose.wcl_expo_tran,
jose.wcl_clm,
jose.wcr_claim, 
jose.wcl_expo,
jose.wrd_clm_actv_typ,

jose.wrd_covg,
jose.WRD_ASL_COVG,
jose.wrd_lob_map,
jose.wrd_lob,
jose.wrd_src_sys,

jose.wrd_st,
jose.wrd_uw_cmpy_map,
jose.wrd_uw_cmpy,
jose.wrd_chnl
WHERE Qtrs.Month="01jun2019"d
and Qtrs.Beg_Date<wcl_expo_tran.tran_ld_dtm<=Qtrs.End_Date
AND wcl_expo_tran.clm_nbr=wcr_claim.clm_nbr= wcl_expo.clm_nbr = wcl_clm.clm_nbr
and wcl_expo.expo_nbr = wcl_expo_tran.expo_nbr
and (wcr_claim.UW_CO in ('AIE','MVIC','NJSI','NJSIA') or wrd_uw_cmpy.UW_CMPY_ABBR in ('AIE','MVIC','NJSI','NJSIA'))
/* AND wcl_clm.src_sys_orgn_cd in ('TWR','OB') or */
/* AND wrd_src_sys.src_sys_id in (17,18) */
/* and wcl_expo_tran.TWR_MGRT_IND is null */
AND wcl_clm.clm_eff_dtm <= Qtrs.End_Date and (wcl_clm.clm_exp_dtm IS NULL OR wcl_clm.clm_exp_dtm > Qtrs.End_Date)
AND wcl_clm.src_sys_id = wrd_src_sys.src_sys_id
AND wrd_clm_actv_typ.actv_typ_id = wcl_expo_tran.actv_typ_id
AND wrd_clm_actv_typ.actv_typ_id IN (30, 31, 32, 39, 48, 56, 62, 63)
/* AND wrd_clm_actv_typ.actv_typ_cd IN ('LOS', 'SAL', 'SUB', 'PMT', 'SBX', 'SLX', 'LCR', 'LAE')->Deepu commentout*/
AND wcl_expo.entps_covg_cd_id = wrd_covg.covg_id
AND wcl_expo.expo_eff_dtm <= Qtrs.End_Date and (wcl_expo.expo_exp_dtm IS NULL OR wcl_expo.expo_exp_dtm > Qtrs.End_Date)
AND wcl_expo_tran.row_log_del_ind=wcl_expo.row_log_del_ind=wcl_clm.row_log_del_ind='N'
AND wrd_covg.covg_unof_covg_ind = 'N'
AND wcl_expo_tran.rec_src_cd = 'A'
AND wcl_clm.uw_cmpy_map_id = wrd_uw_cmpy_map.uw_cmpy_map_id
AND wrd_uw_cmpy.uw_cmpy_id = wrd_uw_cmpy_map.entps_uw_cmpy_id
AND wcl_clm.rt_st_id = wrd_st.st_id
AND wcl_clm.lob_map_id = wrd_lob_map.lob_map_id
AND wrd_lob.lob_id = wrd_lob_map.entps_lob_id
AND wrd_chnl.chnl_id = wcl_clm.chnl_id
and wrd_covg.asl_covg_id=WRD_ASL_COVG.asl_covg_id;
quit;

%let form=%str(Paid_Loss,Paid_Alae,Paid_Ulae,Rec_Loss,Rec_Alae,Rec_Ulae);
proc sql;
create table Test as
	select ASL
	,sum(sum(&form))/1000 as YTD_19Q2 format=comma12.
	,sum((BAD_DAT_IND="Y")*sum(&form)) as YTD_Bad format=comma12.
	,sum((src_sys_orgn_cd not in ('NPS','TWR','OB'))*sum(&form))/1000 as YTD_Src format=comma12.
from jose.zDeepu_YTD_Recips a 
group by 1;
quit;

/* CHECK IF MONEYS CHANGED */
%let form=%str(Paid_Loss,Paid_Alae,Paid_Ulae,Rec_Loss,Rec_Alae,Rec_Ulae);
proc sql;
select 'New' as Typ,sum(sum(&form)) as Pds format=comma12.
from jose.zDeepu_YTD_Recips a 
union all
select 'Old',sum(sum(&form))
from jose.zDeepu_YTD_Recips_v2 a;
quit;

proc sql;
select UW_CO in ('AIE','MVIC','NJSI','NJSIA') as F1
,UW_CMPY_ABBR in ('AIE','MVIC','NJSI','NJSIA') as F2,count(*) as N
from jose.zDeepu_YTD_Recips
group by 1,2;
quit;

/*src_sys_id in(17,18) AND wcl_clm.src_sys_orgn_cd*/

proc sql;
create table dupes as
select *
from RefData.WRD_ASL_COVG
group by asl_covg_id
having count(*)>1;
quit;

/* THIS PART NEEDS TO BE INCOROPORATED ABOVE */
proc freq data=jose.zDeepu_YTD_Recips_v1;
table src_sys_orgn_cd;
run;

/* TEST */
proc sql;
create table test as
select Trans_cd
	,sum(actv_amt)/1000 as Amt format=comma12.
	,sum(Paid_Loss)/1000 as Paid_Loss format=comma12.
	,sum(Paid_ALAE)/1000 as Paid_ALAE format=comma12.
	,sum(Paid_ULAE)/1000 as Paid_ULAE format=comma12.
	,sum(Rec_Loss)/1000 as Rec_Loss format=comma12.
	,sum(Rec_ALAE)/1000 as Rec_ALAE format=comma12.
	,sum(Rec_ULAE)/1000 as Rec_ULAE format=comma12.
from jose.zDeepu_YTD_Recips
group by 1;
quit;

/* TEST */
/* IT SHOULD RUN FASTER NOW */
/* PERHAPS THE BEST ADVANTAGE OF REPULLING EACH TIME 
/* IS THE OFFICIAL COVERAGES CHANGING */
proc sql;
create table zEpic_Paids as
select b.Acctg_Yr,b.Acctg_Qtr,b.Month,b.Next_Mo,b.End_Date
,a.clm_nbr,p.Leg_Clm_Nbr,a.EXPO_NBR,o.DOL,o.DOR
,a.tran_ld_dtm,a.actv_dtm,a.actv_typ_id
,a.TWR_MGRT_IND,m.covg_unof_covg_ind
,o.Pol_No,o.Pol_Eff,o.POL_SMBL_CD
,o.UW_CO /* COMPANY */
,o.Pol_St as State
,o.Product_Epic
/* Fields */
,p.src_sys_id,p.SRC_SYS_CD,p.SRC_SYS_ORGN_ID,p.SRC_SYS_ORGN_CD
/* are these 2 fields equal? */
,p.lob_cd,m.LOB_CD_EXPO,m.LOB_CD_EXPO2
,m.ASL_COVG_CD,m.ASL_COVG_CD2
,m.covg_typ_cd,m.LGCY_ASLOB_CD,m.COVG_CD,m.COVG_DESC,m.entps_covg_cd_id
,a.GL_COVG_CD
/* ASL FORMULA */
,case when p.src_sys_id = 12
 then case when p.lob_cd ='HOME' and m.asl_covg_cd2 in ('192') then '040'
           when m.covg_typ_cd is null and p.Lob_cd ne 'HOME' then '192'
           else m.asl_covg_cd2 end 
 else coalesce(m.LGCY_ASLOB_CD,m.asl_covg_cd2) end as ASL
,a.Paid_Loss,a.Rec_Loss,a.Paid_ALAE,a.Rec_ALAE,a.Paid_ULAE,a.Rec_ULAE
from Qtrs2 b 
inner join jose.zWcr_claim o on o.DOL<=b.End_Date
inner join jose.zWCL_EXPO_TRAN a on a.clm_nbr=o.clm_nbr
and b.Beg_date<=case when a.TWR_MGRT_IND is null then a.tran_ld_dtm else a.actv_dtm end<=b.End_date
/* CLM */
inner join jose.zWcl_clm p on p.clm_nbr=o.clm_nbr 
and case 
when a.TWR_MGRT_IND is null
then (p.clm_eff_dtm<=b.End_date and (p.clm_exp_dtm is NULL or p.clm_exp_dtm>b.End_date)) 
else (p.clm_exp_dtm is null) end
/* EXPO*/
inner join jose.zWcl_expo m on m.CLM_NBR=o.CLM_NBR and m.EXPO_NBR=a.EXPO_NBR 
and case 
when a.TWR_MGRT_IND is null
then (m.expo_eff_dtm<=b.End_date and (m.expo_exp_dtm is NULL or m.expo_exp_dtm>b.End_date))
else (m.expo_exp_dtm is null) end
where o.UW_CO in ('AIE','MVIC','NJSI','NJSIA')
and b.Month="01jun2019"d;
quit;

/* MATCHES PLEOM ALMOST EXACTLY */
%let form=%str(Paid_Loss,Paid_Alae,Paid_Ulae,Rec_Loss,Rec_Alae,Rec_Ulae);
proc sql;
create table Test2 as
select ASL
,sum((covg_unof_covg_ind='N')*sum(&form))/1000 as YTD_19Q2 format=comma12.
,sum((covg_unof_covg_ind='Y')*sum(&form))/1000 as Diff format=comma12.
,sum((src_sys_orgn_cd not in ('NPS','TWR','OB'))*sum(&form))/1000 as YTD_Src format=comma12.
from zEpic_Paids a 
group by 1;
quit;
