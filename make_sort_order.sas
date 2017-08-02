*----------------------------------------------------------------*;
* make_sort_order.sas creates a global macro variable called  
* **SORTSTRING where ** is the name of the dataset that contains  
* the metadata specified sort order for a given dataset.
*
* MACRO PARAMETERS:
* metadatafile = the file containing the dataset metadata
* dataset = the dataset or domain name
*----------------------------------------------------------------*;
%macro make_sort_order(metadatafile=,dataset=);

    proc import 
        datafile="&metadatafile"
        out=_temp 
        dbms=xlsx
        replace;
        sheet="TOC_METADATA";
    run;

    ** create **SORTSTRING macro variable;
    %global &dataset.SORTSTRING;
    data _null_;
      set _temp;

        where name = "&dataset";
    
        call symputx(compress("&dataset" || "SORTSTRING"), 
                     translate(domainkeys," ",","));
    run;
     
%mend make_sort_order;
