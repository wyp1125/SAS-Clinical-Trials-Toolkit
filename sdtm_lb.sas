%include '/folders/myfolders/test1/common.sas';
%common;

**** CREATE EMPTY DM DATASET CALLED EMPTY_DM;
%include '/folders/myfolders/test1/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=LB);
%include '/folders/myfolders/test1/make_sdtm_dy2.sas';
%include '/folders/myfolders/test1/make_sort_order.sas';

proc format;
  value visit_labs_month
    0=baseline
    1=3 months
    2=6 months;
  run;

data lb;
  set EMPTY_LB
      source.labs; 

    studyid = 'XYZ123';
    domain = 'LB';
    usubjid = left(uniqueid);
    lborres = left(put(nresult,best.));
    lborresu = left(colunits);
    lbornrlo = left(put(lownorm,best.));
    lbornrhi = left(put(highnorm,best.));
    lbcat = labcat;
    lbtest = labtest;
    lbtestcd = labtest;


    **** create standardized results;
    lbstresc = lborres;
    lbstresn = nresult;
    lbstresu = lborresu;
    lbstnrlo = lownorm;
    lbstnrhi = highnorm;

    if lbstnrlo ne . and lbstresn ne . and 
       round(lbstresn,.0000001) < round(lbstnrlo,.0000001) then
      lbnrind = 'LOW';
    else if lbstnrhi ne . and lbstresn ne . and 
       round(lbstresn,.0000001) > round(lbstnrhi,.0000001) then
      lbnrind = 'HIGH';
    else if lbstnrhi ne . and lbstresn ne . then
      lbnrind = 'NORMAL';

    visitnum = month;
    visit = put(month,visit_labs_month.);
    if visit = 'baseline' then
      lbblfl = 'Y';
	else
	  lbblfl = ' ';

    lbdtc = put(labdate,yymmdd10.); 
run;

 
proc sort
  data=lb;
    by usubjid;
run;

**** CREATE SDTM STUDYDAY VARIABLES;
data lb;
  merge lb(in=inlb) target.dm(keep=usubjid rfstdtc);
    by usubjid;

    if inlb;

    %make_sdtm_dy(refdate=rfstdtc,date=lbdtc) 
run;


**** CREATE SEQ VARIABLE;
proc sort
  data=lb;
    by studyid usubjid lbtestcd visitnum;
run;

data lb;
  retain STUDYID DOMAIN USUBJID LBSEQ LBTESTCD LBTEST LBCAT LBORRES LBORRESU LBORNRLO LBORNRHI 
         LBSTRESC LBSTRESN LBSTRESU LBSTNRLO LBSTNRHI LBNRIND LBBLFL VISITNUM VISIT LBDTC LBDY;
  set lb(drop=lbseq);
    by studyid usubjid lbtestcd visitnum; 

    if not (first.visitnum and last.visitnum) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;

    retain lbseq;
    if first.usubjid then
      lbseq = 1;
    else
      lbseq = lbseq + 1;
		
    label lbseq = "Sequence Number";
run;


**** SORT LB ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=LB);

proc sort
  data=lb(keep = &LBKEEPSTRING)
  out=target.lb;
    by &LBSORTSTRING;
run;
