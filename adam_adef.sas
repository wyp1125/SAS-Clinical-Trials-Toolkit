*---------------------------------------------------------------*;
* ADEF.sas creates the ADaM BDS-structured data set
* for efficacy data (ADEF), saved to the ADaM libref.
*---------------------------------------------------------------*;

%let path1=/folders/myfolders/test1;
%let path2=/folders/myfolders/test2;

%include "&path2/setup.sas";

**** CREATE EMPTY ADEF DATASET CALLED EMPTY_ADEF;
%let metadatafile=&path1/adam_metadata.xlsx;
%include "&path1/make_empty_dataset.sas";
%make_empty_dataset(metadatafile=&metadatafile,dataset=ADEF)


** calculate changes from baseline for all post-baseline visits;
%include "&path2/cfb.sas";
%cfb(indata=sdtm.xp, outdata=adef, dayvar=xpdy, avalvar=xpstresn);

proc sort
  data = adam.adsl
  (keep = usubjid siteid country age agegr1 agegr1n sex race randdt trt01p trt01pn ittfl)
  out = adsl;
    by usubjid;
    
%include "&path2/dtc2dt.sas";      
data adef;
  merge adef (in = inadef) adsl (in = inadsl);
    by usubjid ;
    
        if not(inadsl and inadef) then
          put 'PROB' 'LEM: Missing subject?-- ' usubjid= inadef= inadsl= ;
        
        rename trt01p    = trtp
               trt01pn   = trtpn
               xptest    = param
               xptestcd  = paramcd
               visit     = avisit
               xporres   = avalc
        ;               
        if inadsl and inadef;
        avisitn = input(put(visitnum, avisitn.), best.);
        
        %dtc2dt(xpdtc, refdt=randdt);
        
        retain crit1 "Pain improvement from baseline of at least 2 points";
        RESPFL = put((.z <= chg <= -2), _0n1y.);         
        if RESPFL='Y' then
          crit1fl = 'Y';
        else
          crit1fl = 'N';          
run;

** assign variable order and labels;
data adef;
  retain &ADEFKEEPSTRING;
  set EMPTY_ADEF adef;
run;

**** SORT ADEF ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%include "&path1/make_sort_order.sas"; 
%make_sort_order(metadatafile=&metadatafile,dataset=ADEF)

proc sort
  data=adef(keep = &ADEFKEEPSTRING)
  out=adam.adef;
    by &ADEFSORTSTRING;
run;        

