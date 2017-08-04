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
set temp (rename=(A=subject B=month C=labcat D=labtest E=colunits F=nresult G=lownorm H=highnorm I=labdate));
if lownorm=. then lownorm=0;
uniqueid = 'UNI' || put(subject,3.);
RUN;

