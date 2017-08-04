%include '/folders/myfolders/test1/common.sas';
%common;

**** CREATE EMPTY DM DATASET CALLED EMPTY_DM;
%include '/folders/myfolders/test1/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=EX);
%include '/folders/myfolders/test1/make_sdtm_dy2.sas';
%include '/folders/myfolders/test1/make_sort_order.sas';

**** DERIVE THE MAJORITY OF SDTM EX VARIABLES;
data ex;
  set EMPTY_EX
      source.dosing;

    studyid = 'XYZ123';
    domain = 'EX';
    usubjid = left(uniqueid);
    exdose = dailydose;
    exdostot = dailydose;
    exdosu = 'mg';
    exdosfrm = 'TABLET, COATED';
    exstdtc=put(startdt,yymmdd10.);
    exendtc=put(enddt,yymmdd10.);
run;
 
proc sort
  data=ex;
    by usubjid;
run;

**** CREATE SDTM STUDYDAY VARIABLES AND INSERT EXTRT;
data ex;
  merge ex(in=inex) target.dm(keep=usubjid rfstdtc arm);
    by usubjid;

    if inex;

    %make_sdtm_dy(refdate=rfstdtc,date=exstdtc); 
    %make_sdtm_dy(refdate=rfstdtc,date=exendtc); 

    **** in this simplistic case all subjects received the treatment they were randomized to;
    extrt = arm;
run;


**** CREATE SEQ VARIABLE;
proc sort
  data=ex;
    by studyid usubjid extrt exstdtc;
run;

OPTIONS MISSING = ' ';
data ex;
  retain STUDYID DOMAIN USUBJID EXSEQ EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSTOT
         EXSTDTC EXENDTC EXSTDY EXENDY;
  set ex(drop=exseq);
    by studyid usubjid extrt exstdtc;

    if not (first.exstdtc and last.exstdtc) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;

    retain exseq;
    if first.usubjid then
      exseq = 1;
    else
      exseq = exseq + 1;
		
    label exseq = "Sequence Number";
run;


**** SORT EX ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=EX);


proc sort
  data=ex(keep = &EXKEEPSTRING)
  out=target.ex;
    by &EXSORTSTRING;
run;
