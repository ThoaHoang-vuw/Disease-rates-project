/**********************************************************************************************************************/

/* Purpose		Create disease episodes and derived variables */
/* Author		Thoa Hoang */
/* Date			April 2020 */


/**********************************************************************************************************************/

/* Summary */

/* This code is a template to create disease episodes representing the time the person had the disease. It also derives
variables needed for incidence, prevalence and mortality calculations. Update the library location and macros below
before running the code.

For more information about the variable names, or terms used, please see the 1.Abbreviations used in code spreadsheet. The
spreadsheet is saved here INSERT LOCATION.*/

/**********************************************************************************************************************/

/*Updates to code*/

/*V2 - changed the code so that it is easier to update. Removed variables that are taken from elsewhere (dob and dod).
Removed some of the test queries that are no longer needed.

V3 01/05/2020 - changed the code to make it easier to run e.g. included macros to make the code easier to update.*/

/**********************************************************************************************************************/

/* Libraries */

/*Disease specific input and output*/
libname output "E:\Dean_grant_project\1_Diseases\Cancer\Cancer_breast (female)\3_SAS_outputs";

/**********************************************************************************************************************/

/* UPDATE THESE MACROS */

%let DISEASE=BRE; 
%let CURE_TIME=20; /*An estimate of the cure time for the disease. The cure time per disease can be found HERE UPDATE
ONCE BACK AT WORK.*/

/**********************************************************************************************************************/

/*Create temporary dates*/

/*Manpipulate data for the purposes of disease episode building.

Create temporary episodes for each person and event. The temporary episode starts on the event_date and ends when the person
was cured (event date + disease-specific cure time).

Count the number of events per person.

Please note that. This logic will only work if the output is sorted by unique_id and event start date. The previous version
of the code and the query below includes this function. Suggest double-checking these functions are still included if the
code is changed.*/

proc sql; 
create table &DISEASE._episode1 as
SELECT
unique_id,
event_date as temp_sd format=ddmmyy10.,
INTNX('year',event_date,&CURE_TIME,"sameday") FORMAT=ddmmyy10. as temp_ed,
count(unique_id) as count
FROM Output.&DISEASE._cancer_base1
GROUP BY Unique_id
ORDER BY 1,3;
quit;

/*Test query*/

/*This next table should produce no results.

If it does produce results then a person will have more than three events and the code will need to be updated.
Either produce more lag variables or create an array.*/



proc sql; 
create table Output.episodes_per_person1 AS
SELECT
unique_id,
count
FROM &DISEASE._episode1
WHERE count >3
ORDER BY count DESC;
quit;

/*Creates a flag for the first event per person and creates lag variables for the purposes of episode building*/

data &DISEASE._episode2;
SET &DISEASE._episode1;
BY unique_id;
first_unique_id =first.unique_id;
lag_unique_id1 = lag1(unique_id);
lag_unique_id2 = lag2(unique_id);
lag_temp_ed1 = lag1(temp_ed);
lag_temp_ed2 = lag2(temp_ed);
FORMAT lag_temp_ed1 lag_temp_ed2  ddmmyy10.;
run;
/**********************************************************************************************************************/
/*Creates distinct episodes*/

/*The first episode is given an episode ID of 1. The start date of any subsequent episodes are compared with the end date
of the previous episode to see if they overlap. 

If the episodes do not overlap, they are counted as a new episode and a new episode id is assigned.

If the episodes overlap, the second event is counted as part of the first. The second event is given a null value and will 
be excluded. 

If the first and second episodes are overlappping, and there is a third episode, the dates from the third episode must be
compared with those from the first episode. A lag episode id is created for the purposes of comparing the first and third episode and
these episodes are compared.*/

data &DISEASE._episode3;
SET &DISEASE._episode2;
RETAIN epi_id;
BY unique_id;

/*One event*/
IF first_unique_id = '1' THEN epi_id =1;

/*Events that do not overlap*/
IF (unique_id = lag_unique_id1 AND temp_sd > lag_temp_ed1) THEN epi_id +1;

/*Events that overlap*/
IF (unique_id = lag_unique_id1 AND temp_sd <= lag_temp_ed1) THEN epi_id =.;

lag_epi_id = lag1(epi_id);

/*Three events. First two overlap, the third does not overlap with the first*/
IF (lag_epi_id =. AND unique_id = lag_unique_id2 AND temp_sd > lag_temp_ed2) THEN epi_id =2;
run;

/*Exclude overlapping events i.e. events with no episode ID*/

proc sql;
create table Output.&DISEASE._episode4 as
SELECT
unique_id,
epi_id,
temp_sd as epi_sd,
temp_ed as epi_ed
FROM &DISEASE._episode3
WHERE epi_id is not null;
quit;

/**********************************************************************************************************************/


