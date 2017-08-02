*---------------------------------------------------------------*;
* STDM_DM.sas creates the SDTM DM and SUPPDM datasets and saves them
* as permanent SAS datasets to the target libref.
*---------------------------------------------------------------*;
%include '/folders/myfolders/test1/common.sas';
%common;

**** CREATE EMPTY DM DATASET CALLED EMPTY_DM;
%include '/folders/myfolders/test1/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=DM);

 
**** GET FIRST AND LAST DOSE DATE FOR RFSTDTC AND RFENDTC;
proc sort
  data=source.dosing(keep=subject startdt enddt)
  out=dosing;
    by subject startdt;
run;

**** FIRSTDOSE=FIRST DOSING AND LASTDOSE=LAST DOSING;
data dosing;
  set dosing;
    by subject;
    format firstdose lastdose mmddyy10.;
    retain firstdose lastdose;

    if first.subject then
      do;
        firstdose = .;
        lastdose = .;
      end;

    firstdose = min(firstdose,startdt,enddt);
    lastdose = max(lastdose,startdt,enddt);
    drop startdt enddt;
    if last.subject;
run; 

**** GET DEMOGRAPHICS DATA;
proc sort
  data=source.demographic
  out=demographic;
    by subject;
run;

data demog_dose;
  merge demographic
        dosing;
    by subject;
run;

**** DERIVE THE MAJORITY OF SDTM DM VARIABLES;
data dm;
  set EMPTY_DM
    demog_dose;
    studyid = 'XYZ123';
    domain = 'DM';
    usubjid = left(uniqueid);
    subjid = put(subject,3.); 
    rfstdtc = put(firstdose,yymmdd10.);  
    rfendtc = put(lastdose,yymmdd10.); 
    siteid = substr(subjid,1,1) || "00";
    brthdtc = put(dob,yymmdd10.);
    age = floor ((intck('month',dob,firstdose) - 
          (day(firstdose) < day(dob))) / 12);
    if age ne . then
        ageu = 'YEARS';
    country = "USA";
    sex=gender;
    arm=trt1;
    armcd=put(trt,3.);
    drop gender trt trt1;
run;

%include '/folders/myfolders/test1/make_sort_order.sas';
%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=DM);

proc sort
  data=dm(keep = &DMKEEPSTRING)
  out=target.dm;
    by &DMSORTSTRING;
run;

**** CREATE EMPTY SUPPDM DATASET CALLED EMPTY_DM;
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=SUPPDM);

data suppdm;
  set EMPTY_SUPPDM
      dm; 

    keep &SUPPDMKEEPSTRING;

    **** OUTPUT OTHER RACE AS A SUPPDM VALUE;
    if orace ne '' then
      do;
        rdomain = 'DM';
        qnam = 'RACEOTH';
        qlabel = 'Race, Other';
        qval = left(orace);
        qorig = 'CRF';
        output;
      end;

    **** OUTPUT RANDOMIZATION DATE AS SUPPDM VALUE;
    if randdt ne . then
      do;
        rdomain = 'DM';
        qnam = 'RANDDTC';
        qlabel = 'Randomization Date';
        qval = left(put(randdt,yymmdd10.));
        qorig = 'CRF';
        output;
      end;
run;

%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=SUPPDM);

proc sort
  data=suppdm
  out=target.suppdm;
    by &SUPPDMSORTSTRING;
run;

