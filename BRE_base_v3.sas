/**********************************************************************************************************************/

/* Purpose		Create a base dataset to extract any indication of the breast (female)cancer */
/* Author		Thoa Hoang */
/* Date			April 2020 */
	

/**********************************************************************************************************************/

/* Summary */
/* This code is written to create baseline data for the breast (female) cancer  rates. To run the code, update the library location
and macros below.

The code extracts all cancer and deaths registrations with site code or underlying cause of death indicating the disease.

For more information about the variable names, or terms used, please see the 1.Abbreviations used in code spreadsheet. The
spreadsheet is saved here INSERT LOCATION.*/

/**********************************************************************************************************************/

/*Updates to code*/

/*V2 - changed the code so that it is easier to update. Removed variables that aren't needed and variables that are taken
from elsewhere (event ID, reg ID, dob and dod).

V3 01/05/2020 - included macros to make the code easier to update.*/

/**********************************************************************************************************************/

/* Libraries */

/*Disease specific input and output*/
libname output "E:\Dean_grant_project\1_Diseases\Cancer\Cancer_breast (female)\3_SAS_outputs";

/* For input data*/
libname UOWData "E:\Dean_grant_project\5_UOW18Datasets";


/**********************************************************************************************************************/

/* UPDATE THESE MACROS */

%let DISEASE=BRE; 
%let cause_of_death ='BRE'; 
%let ICD10 ='C50'; 
%let CAN_END =2018; /*The most up-to-date data available for the Cancer Registry.*/
%let MOR_END =2016; /*The most up-to-date data for the Mortality Collection.*/

/**********************************************************************************************************************/

/*Identification - Cancer Registry Events*/

proc sql; 
create table Output.&DISEASE._cancer_base1 as 
SELECT 	new_enc_nhi as unique_id,
		site as clin_code,
		diag_date as event_date,
		'CAN' as source
FROM UOWData.cancer
WHERE ((substr(site,1,3) in (&ICD10)))
	and diag_date between'01JAN1991'd and "31DEC&CAN_END"d ;
quit;

/*Identification - Mortality Collection */

proc sql; 
create table Output.&DISEASE._mort_base1 as 
SELECT 	new_enc_nhi as unique_id,
		icda,
		&cause_of_death as cod,
		'MOR' as source
FROM UOWData.mortality
WHERE ((substr(icda,1,3) in (&ICD10)))
	and dod between '01JAN2000'd and "31DEC&MOR_END."d ;
quit; 

/**********************************************************************************************************************/
