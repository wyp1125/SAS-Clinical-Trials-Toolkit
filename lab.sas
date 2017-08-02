%include '/folders/myfolders/test1/common.sas';
%common;

Options validVarName=any; 
PROC IMPORT OUT=temp
     DATAFILE="/folders/myfolders/test1/lab.xls"
     DBMS=xls REPLACE;
     getnames=NO;
     sheet='Sheet1';
RUN;

data source.labs;
label subject      = "Subject Number"
      month        = "Month: 0=baseline, 1=3 months, 2 =6 months"
      labcat       = "Category for Lab Test"
      labtest      = "Laboratory Test"
      colunits     = "Collected Units"
      nresult      = "Numeric Result"
      lownorm      = "Normal Range Lower Limit"
      highnorm     = "Normal Range Upper Limit"
      labdate      = "Date of Lab Test"
      uniqueid = "Company Wide Subject ID";
set temp (rename=(A=subject B=month C=labcat D=labtest E=colunits F=nresult G=lownorm H=highnorm I=labdate));
if lownorm=. then lownorm=0;
uniqueid = 'UNI' || put(subject,3.);
RUN;

proc print data=source.labs label;
   run;
