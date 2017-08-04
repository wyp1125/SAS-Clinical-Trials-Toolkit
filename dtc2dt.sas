%macro dtc2dt(dtcvar , prefix=a, refdt= );

    if length(trim(&dtcvar))=10 and index(&dtcvar,'--')=0 then
      &prefix.dt = input(&dtcvar, yymmdd10.);
    else if length(&dtcvar)=16 and index(&dtcvar,'--')=0 and index(&dtcvar,'-:')=0 then
      do;
        &prefix.dtm = input(trim(&dtcvar)||":00", e8601dt19.);
        &prefix.dt  = datepart(&prefix.dtm); 
        * optionally add formats: ;
        * format &prefix.dtm datetime16.;
      end;
      
    %if &refdt^= %then
      %do;
        if .<&prefix.dt<&refdt then
          &prefix.dy = &prefix.dt - &refdt;
        else if &prefix.dt>=&refdt then
          &prefix.dy = &prefix.dt - &refdt + 1;
      %end;
    * optionally add formats: ;
    * format &prefix.dt yymmdd10. ;

%mend dtc2dt;
