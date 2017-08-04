*---------------------------------------------------------------*;
* XP.sas creates the SDTM XP dataset and saves it
* as a permanent SAS datasets to the target libref.
*---------------------------------------------------------------*;
%include '/folders/myfolders/test1/common.sas';
%common;
%include '/folders/myfolders/test1/make_sdtm_dy2.sas';
%include '/folders/myfolders/test1/make_sort_order.sas';
%include '/folders/myfolders/test1/make_empty_dataset.sas';
%make_empty_dataset(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=XP);

proc format;
  value pain
    0='None'
    1='Mild'
    2='Moderate'
    3='Severe';
  value visit_labs_month
    0='Baseline visit'
    1='Month 3 visit'
    2='Month 6 visit';
run;

**** DERIVE THE MAJORITY OF SDTM XP VARIABLES;

data xp;
  set empty_xp source.pain;
    studyid = 'XYZ123';
    domain = 'XP';
    usubjid = left(uniqueid);

    xptest = 'Pain Score';
    xptestcd = 'XPPAIN';

    **** transpose pain data;
    array dates {3} randomizedt month3dt month6dt;
    array scores {3} painbase pain3mo pain6mo;

    do i = 1 to 3;
      visitnum = i - 1;
      visit = put(visitnum,visit_labs_month.);
      if scores{i} ne . then
        do;
          xporres = left(put(scores{i},pain.));
	  xpstresc = xporres;
	  xpstresn = scores{i};
          xpdtc = put(dates{i},yymmdd10.);
          output;
        end;
    end;
    *drop randomizedt month3dt month6dt painbase pain3mo pain6mo i;
run;

 
proc sort
  data=xp;
    by usubjid;
run;

**** CREATE SDTM STUDYDAY VARIABLES;
data xp;
  merge xp(in=inxp) target.dm(keep=usubjid rfstdtc);
    by usubjid;

    if inxp;

    %make_sdtm_dy(refdate=rfstdtc,date=xpdtc) 
run;


**** CREATE SEQ VARIABLE;
proc sort
  data=xp;
    by studyid usubjid xptestcd visitnum;
run;


data xp;
  retain STUDYID DOMAIN USUBJID XPSEQ XPTESTCD XPTEST XPORRES VISITNUM VISIT XPDTC XPDY;
  set xp(drop=xpseq);
    by studyid usubjid xptestcd visitnum; 

    if not (first.visitnum and last.visitnum) then
      put "WARN" "ING: key variables do not define an unique record. " usubjid=;

    retain xpseq;
    if first.usubjid then
      xpseq = 1;
    else
      xpseq = xpseq + 1;
		
    label xpseq = "Sequence Number";
run;


**** SORT XP ACCORDING TO METADATA AND SAVE PERMANENT DATASET;
%make_sort_order(metadatafile=/folders/myfolders/test1/SDTM_METADATA.xlsx,dataset=XP);

proc sort
  data=xp(keep = &XPKEEPSTRING)
  out=target.xp;
    by &XPSORTSTRING;
run;
