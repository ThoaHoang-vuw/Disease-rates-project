
/**********************************************************************************************************************/

/* Purpose		Create a base dataset to extract any indication of CHD */
/* Author		Thoa Hoang */
/* Date			April 2020 */

/**********************************************************************************************************************/

/* Summary */
/* Extract all publicly funded hospitalisations with a ICD9 or ICD10 diagnosis or procedure indicating Coronary Heart 
Disease (CHD). Next identify people with at least two publicly funded community dispended pharmaceuticals per year, 
and death registrations also indicating CHD.



/**********************************************************************************************************************/

/*Updates to code*/

/*V1 - 23/04/2020 */

/**********************************************************************************************************************/

/* Libraries */

/*Disease specific input and output*/
libname output "E:\Dean_grant_project\1_Diseases\Coronary disease\3_SAS_outputs";

/* For input data*/
libname UOWData "E:\Dean_grant_project\5_UOW18Datasets";

/**********************************************************************************************************************/
/*Identification - NMDS diags and procedures */
/*Still to check whether use of event end date for stroke makes a big diff*/

proc sql; 
create table output.chdnmdbase as 
select 	new_enc_nhi as unique_id,
		clin_cd as clin_code,
		evstdate as event_date,
		case 	when diag_typ = 'A' then 'NMD1' 
				when diag_typ = 'B' then 'NMD2' 
				when diag_typ = 'O' then 'NMD2' 
				end as source
from UOWData.nmds_diagsnew
where
evstdate between '01JAN1988'd and '31DEC2018'd
and
(/* ICD 10 diags */
	(CC_Sys in ('10','12') and diag_typ in ('A','B') and substr(clin_cd,1,3) in ('I20','I21','I22','I23','I24','I25'))
or
	(CC_Sys in ('10','12') and diag_typ in ('A','B') and substr(clin_cd,1,4) in ('Z951','Z952'))
or

/* ICD 10 ops */
	(CC_Sys in ('10','12') and diag_typ in ('O') and substr(clin_cd,1,7) in ('3530400', '3530500', '3531000', '3531001', '3531002', '3849700',
			'3849701', '3849702', '3849703', '3849704', '3849705', '3849706', '3849707', '3850000', '3850001', '3850002', '3850003',
			'3850004', '3850300', '3850301', '3850302', '3850303', '3850304', '3863700', '9020100', '9020101', '9020102', '9020103'))
or

/* ICD 9 diags */
	(CC_Sys = '06' and diag_typ in ('A','B') and substr(clin_cd,1,3) in ('410','411','412','413','414'))
or
	(CC_Sys = '06' and diag_typ in ('A','B') and substr(clin_cd,1,5) in ('V4581','V4582'))

or

/* ICD 9 ops */
	(CC_Sys = '06' and diag_typ in ('O') and substr(clin_cd,1,4) in ('3601', '3602', '3603', '3604', '3605', '3606','3607', '3610', '3611',
	'3612', '3613', '3614', '3615', '3616'))
)
order by 1,3; 

quit;

/*Identification - Pharms*/
/*Notes - potentially use the form ID or concatenated version of TG and chemical ID
		   - *exclude admin records?*/
proc sql; 
create table output.chdpharmsbase1 as
select 	new_enc_nhi as unique_id,
		put(chemical_id,6.) as clin_code, /*Thoa*//*chemical_id,4.*/
		date_dispensed as event_date,
		'PHA' as source
from UOWData.pharms
where
date_dispensed between '1JAN2005'd and '30JUN2019'd
and
chemical_id in (1577,2377,2836,1272,1949)
order by 1,3;
quit;

/*Identify dispensings within the financial year of interest and sort the result.*/

%macro chd_pha(fstart,fend,finyear); 

data output.chdpharmsbase2;/* Thoa added output.*/
set output.chdpharmsbase1;
where event_date between "01Jul&fstart"d and "30Jun&fend"d;
run;

proc sort data=output.chdpharmsbase2;
by unique_id event_date;
run;

/* Create a lag variable and then calculate the number of days between dispensings for each person. The lag for the 
first dispensing per person is a null value. */

data output.chdpharmsbase3;/* Thoa added output.*/
set output.chdpharmsbase2;
by unique_id;
format lag_date ddmmyy10.;
lag_date = lag(event_date);
if first.unique_id then lag_date = .;
daysbetwn = event_date-lag_date;
run;

/* Exclude the  first dispensing (null value) and records where there is more than one year (366 days) between dispensings. This
means that only people with two or more dispensings remain. It also means that the date of first incidence date within
the Pharmaceutical  Collection will be the date of second dispensing.*/

data output.chdpharmsbase4;/* Thoa added output.*/
set output.chdpharmsbase3;
where . < daysbetwn <= 366;
run;

/*Keep the first record for each person.*/

data output.chdpharmsbase5&finyear;
set output.chdpharmsbase4;
by unique_id;
keep unique_id event_date;
if first.unique_id then output;
run;
%mend chd_pha;

%chd_pha(2006,2007,200607);
%chd_pha(2007,2008,200708);
%chd_pha(2008,2009,200809);
%chd_pha(2009,2010,200910);
%chd_pha(2010,2011,201011);
%chd_pha(2011,2012,201112);
%chd_pha(2012,2013,201213);
%chd_pha(2013,2014,201314);
%chd_pha(2014,2015,201415);
%chd_pha(2015,2016,201516);

/* Append all datasets */
data output.chdpharmsbase6;
set output.chdpharmsbase5: ;
run;

/*Identification - Mortality*/

proc sql;
create table output.chdmorbase as
select	new_enc_nhi as unique_id,
		icda as clin_code,
		dod as event_date,
		'CHD' as cod, /*Thoa*/
		'MOR' as source
from UOWData.mortality
where
dod between '01JAN2000'd and '31DEC2016'd
and
substr(icda,1,3) in ('I20','I21','I22','I23','I24','I25')
order by 1,3;
quit;

/*Combine records from NMDS, the Pharmaceutical Colleciton and the Mortality Collection. Only keep the unique_id 
and event_date and then sort the results.*/

data output.chdbase1; 
set output.chdnmdbase output.chdpharmsbase6 output.chdmorbase;
keep unique_id event_date;
run;

proc sort data= output.chdbase1;
by unique_id event_date;
run;

/*Identify all events for each person and keep the event that happened first.*/

data output.chdbase2;
set output.chdbase1;
by unique_id;
if first.unique_id then output;
run;

/*Create an disease episode for each person. The episode starts on the first event found within the data and ends after
99 years, essentially meaning there is no end date for CHD.*/

proc sql; 
create table output.chdbase3 as 
SELECT
unique_id,
event_date as epi_sd,
INTNX('year',event_date,99,"sameday") FORMAT=ddmmyy10. as epi_ed
FROM output.chdbase2;
run;


/**********************************************************************************************************************/
