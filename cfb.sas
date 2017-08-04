*---------------------------------------------------------;
* Macro for deriving ABLFL, BASE, CHG, and PCHG for a BDS
*   formatted ADaM data set;
* Assumes baseline is the last non-missing value on or before
*   study day 1 and that the INDDATA is an SDTM data set with
*   variables USUBJID and VISITNUM
*---------------------------------------------------------;
%macro cfb(indata= ,outdata= ,avalvar= ,dayvar= ,keepvars= );

    proc sort
      data = &indata
      out = &outdata (rename = (&avalvar = aval));
        by usubjid visitnum;
    run;
    
    * Baseline is defined as the last non-missing value prior to study day 1 first dose;
    * (note, values on Day 1 are assumed to occur before the first dose);
    data base1 (keep = usubjid visitnum) base2 (keep = usubjid base);
      set &outdata;
        where &dayvar<=1 and aval > .z; 
        by usubjid visitnum;
        
        rename aval = base;
        if last.usubjid;
    run;        
    
    * Do one merge to identify the baseline record;
    data &outdata;
      merge &outdata base1 (in = inbase);
        by usubjid visitnum;

           if inbase then 
             ablfl = 'Y';
    run;
                 
    * Do another merge to merge in the baseline value;                 
    data &outdata;
      merge &outdata base2;
        by usubjid;
    
           %if &keepvars^= %then
             keep  &keepvars;
           ;
             
           chg  = aval - base;
           pchg = chg/base*100;
    run;
    
%mend cfb;