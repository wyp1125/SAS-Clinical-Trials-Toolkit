%include '/folders/myfolders/test1/common.sas';
%common;

filename pn "/folders/myfolders/test1/pn.dat";
data source.pain;
label subject  = "Subject Number"
      randomizedt = "Baseline visit date"
      month3dt    = "Month 3 visit date"
      month6dt    = "Month 6 visit date"
      painbase    = "Pain score at baseline: 0=none, 1=mild, 2=moderate, 3=severe"
      pain3mo     = "Pain score at 3 months: 0=none, 1=mild, 2=moderate, 3=severe"
      pain6mo     = "Pain score at 6 months: 0=none, 1=mild, 2=moderate, 3=severe"
      uniqueid = "Company Wide Subject ID";
infile pn;
input subject randomizedt mmddyy10. +1 month3dt mmddyy10. +1 month6dt mmddyy10. painbase pain3mo pain6mo;
uniqueid = 'UNI' || put(subject,3.);
format randomizedt month3dt month6dt mmddyy10.;
run;