*---------------------------------------------------------------*;
* make_sdtm_dy.sas is a SAS macro that takes two SDTM --DTC dates
* and calculates a SDTM study day (--DY) variable. It must be used
* in a datastep that has both the REFDATE and DATE variables 
* specified in the macro parameters below.
* MACRO PARAMETERS:
* refdate = --DTC baseline date to calculate the --DY from.  
*           Generally RFSTDTC.
* date = --DTC date to calculate the --DY to.  The variable
*          associated with the --DY variable.
*---------------------------------------------------------------*;
%macro make_sdtm_dy(refdate=,date=); 

    if length(&date) >= 10 and length(&refdate) >= 10 then
      do;
        if input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) >= 
           input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.) then
          %upcase(%substr("&date",2,%length(&date)-3))DY = input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) - 
          input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.) + 1;
        else
          %upcase(%substr("&date",2,%length(&date)-3))DY = input(substr(%substr("&date",2,%length(&date)-3)dtc,1,10),yymmdd10.) - 
          input(substr(%substr("&refdate",2,%length(&refdate)-3)dtc,1,10),yymmdd10.);  
      end;

%mend make_sdtm_dy;    


