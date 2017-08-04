*---------------------------------------------------------------*;
* ADAE.sas creates the ADaM ADAE-structured data set
* for AE data (ADAE), saved to the ADaM libref.
*---------------------------------------------------------------*;

%let path1=/folders/myfolders/test1;
%let path2=/folders/myfolders/test2;

%include "&path2/setup.sas";

**** CREATE EMPTY ADAE DATASET CALLED EMPTY_ADAE;
%let metadatafile=&path1/adam_metadata.xlsx;
%include "&path1/make_empty_dataset.sas";
%make_empty_dataset(metadatafile=&metadatafile,dataset=ADAE)

proc sort
  data = adam.adsl
  (keep = usubjid siteid country age agegr1 agegr1n sex race trtsdt trt01a trt01an saffl)
  out = adsl;
    by usubjid;
%include "&path2/dtc2dt.sas";  
data adae;
  merge sdtm.ae (in = inae) adsl (in = inadsl);
    by usubjid ;
    
        if inae and not inadsl then
          put 'PROB' 'LEM: Subject missing from ADSL?-- ' usubjid= inae= inadsl= ;
        
        rename trt01a    = trta
               trt01an   = trtan
        ;               
        if inadsl and inae;
        
        %dtc2dt(aestdtc, prefix=ast, refdt=trtsdt);
        %dtc2dt(aeendtc, prefix=aen, refdt=trtsdt);

        if index(AEDECOD, 'PAIN')>0 or AEDECOD='HEADACHE' then
          CQ01NAM = 'PAIN EVENT';
        else
          CQ01NAM = '          ';
          
        aereln = input(put(aerel, $aereln.), best.);
        aesevn = input(put(aesev, $aesevn.), best.);
        relgr1n = (aereln); ** group related events (AERELN>0);
        relgr1  = put(relgr1n, relgr1n.);
        if astdt>=trtsdt then
          trtemfl = 'Y';
        format astdt aendt yymmdd10.;
run;

** assign variable order and labels;
data adae;
  retain &adaeKEEPSTRING;
  set EMPTY_adae adae;
run;

**** SORT adae ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%include "&path1/make_sort_order.sas"; 
%make_sort_order(metadatafile=&metadatafile, dataset=ADAE)

proc sort
  data=adae(keep = &adaeKEEPSTRING)
  out=adam.adae;
    by &adaeSORTSTRING;
run;        

