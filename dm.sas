/*Process the raw demographic data from a CSV file*/
%include '/folders/myfolders/test1/common.sas';
%common;

filename infl '/folders/myfolders/test1/dm.csv';

proc format;
   value trt
      1 = "Active"
      0 = "Placebo"; 
   value gender 
      1 = "M"
      2 = "F"
      3 = "U";
   value race
      1 = "White"
      2 = "Black"
      3 = "Other";
run;

data source.demographic;
infile infl dlm='2C0D'x dsd missover;
length dob1 $10
       randdt1 $10;
input subject trt gender race orace $ dob1 $ randdt1 $;
dob=input(dob1,mmddyy10.);
randdt=input(randdt1,mmddyy10.);
format dob randdt mmddyy10.;
uniqueid = 'UNI' || put(subject,3.);
gender1=put(gender,gender.);
race1=put(race,race.);
trt1=put(trt,trt.);
label subject  = "Subject Number"
      trt      = "Treatment"
      gender   = "Gender"
      race     = "Race"
      orace    = "Oher Race Specify"
      dob      = "Date of Birth"
      uniqueid = "Company Wide Subject ID"
      randdt   = "Randomization Date";
drop dob1 randdt1 gender race;
rename gender1=gender race1=race;
run;