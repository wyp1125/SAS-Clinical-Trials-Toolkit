**** define common SAS setings;
%include '/folders/myfolders/test1/common.sas';
%common;

Options validVarName=any; 
/* if the input file is txt format*/
*filename infl '/folders/myfolders/test1/ae.txt'; 

/*if the input file is Excel format. Note the raw data should use space, not dot, for missing number*/
PROC IMPORT OUT=temp
     DATAFILE="/folders/myfolders/test1/ae.xlsx"
     DBMS=XLSX REPLACE;
     getnames=NO;
     sheet='Sheet1';
RUN;

data source.adverse;
set temp (rename=(A=subject B=aerel C=aesev D=aeaction E=aestart F=aeend G=bodysys H=prefterm I=aetext));

label subject  = "Subject Number"
      bodysys = "Body System of Event"
      prefterm  = "Preferred Term for Event"
      aerel    = "Relatedness: 1=not,2=possibly,3=probably"
      aesev    = "Severity/Intensity:1=mild,2=moderate,3=severe"
      aeaction = "Action taken: 1=drug stopped, 2=dose reduced, 3=dose increased, 4=no dose change, 5=unknown"
      aestart  = "AE Start date"
      aeend    = "AE End date"
      serious  = "Serious AE?"
      aetext   = "Event Verbatim Text"
      uniqueid = "Company Wide Subject ID";
      serious = 'N';
/*input from a txt file*/
*infile infl;
*input subject aerel aesev aeaction aestart mmddyy10. +1 aeend mmddyy10. bodysys $ 33-63 prefterm $ 65-82 aetext $ 94-130;
run;

/*examine data types of the input data*/
proc contents data=source.adverse;
   run;

proc print data=source.adverse;
   run;
