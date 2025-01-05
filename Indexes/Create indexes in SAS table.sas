/* SAMPLES ON HOW TO CREATE INDEXES */	

PROC DATASETS LIB=actper NOLIST;
	modify premium_&month;
		format entered_date transaction_date policy_expiry_date
				effective_date_of_policy treffdat trexpdat yymmdd10.;
	MODIFY premium_&month;
		INDEX CREATE IDX1=(POLICY_NBR RISK_NBR COVER_CD driver_class TREFFDAT);
		INDEX CREATE TREFFDAT;
		INDEX CREATE TREXPDAT;
		INDEX CREATE company_number;
		INDEX CREATE risk_province;
		INDEX CREATE branch;
		INDEX CREATE postal_code;
		INDEX CREATE broker_number;
		INDEX CREATE PRODUCT;
/*
		INDEX CREATE broker_with_lozenge;
		INDEX CREATE model_year;
		INDEX CREATE car_code;
		INDEX CREATE driver_class;
 */
		INDEX CREATE idx2=(load_month rownum) / unique;
	MODIFY premium_&month
		(sortedby=POLICY_NBR RISK_NBR COVER_CD driver_class descending TREFFDAT);
		
	MODIFY earned_premium_&month;
		INDEX CREATE IDX1=(POLICY_NBR RISK_NBR COVER_CD);
		INDEX CREATE earned_month;
		INDEX CREATE idx2=(load_month rownum);
quit;