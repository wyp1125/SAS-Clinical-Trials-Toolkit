%include '/folders/myfolders/test1/common.sas';
%common;
%include '/folders/myfolders/test1/make_sdtm_dy2.sas';
%include '/folders/myfolders/test1/make_sort_order.sas';
%include '/folders/myfolders/test1/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=AE);

%put &AEKEEPSTRING;

**** DERIVE THE MAJORITY OF SDTM AE VARIABLES;
options missing = ' ';
data ae;
  set EMPTY_AE
  source.adverse;
    studyid = 'XYZ123';
    domain = 'AE';
    usubjid = left(uniqueid);
run;

 
proc sort
  data=ae;
    by usubjid;
run;

data ae;
  merge ae(in=inae) target.dm(keep=usubjid rfstdtc);
    by usubjid;

    if inae;

    %make_sdtm_dy(refdate=rfstdtc,date=aestdtc); 
    %make_sdtm_dy(refdate=rfstdtc,date=aeendtc); 
run;


**** CREATE SEQ VARIABLE;
proc sort
  data=ae;
    by studyid usubjid aedecod aestdtc aeendtc;
run;

data ae;
  retain STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AEBODSYS AESEV AESER AEACN AEREL AESTDTC
         AEENDTC AESTDY AEENDY;
  set ae(drop=aeseq);
    by studyid usubjid aedecod aestdtc aeendtc;

    if not (first.aeendtc and last.aeendtc) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;

    retain aeseq;
    if first.usubjid then
      aeseq = 1;
    else
      aeseq = aeseq + 1;
		
    label aeseq = "Sequence Number";
run;


**** SORT AE ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=AE);

proc sort
  data=ae(keep = &AEKEEPSTRING)
  out=target.ae;
    by &AESORTSTRING;
run;
