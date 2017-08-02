 *---------------------------------------------------------------*;
* %make_define generates parts of the define.xml file for the SDTM and ADaM.  
* The parts can be concatenated into the define.xml file using shell scripts.
*
* PARAMETERS:
*            path = System path to where the SDTM or ADaM metadata
*                   file exists as well as where the define.xml
*                   file will be stored.
*        metadata = The name of the metadata spreadsheet.
*
* It requires that the following tabs exist in the metadata file:
* DEFINE_HEADER_METADATA = define file header metadata
* TOC_METADATA = "table of contents" dataset metadata
* VARIABLE_METADATA = variable/column level metadata
* VALUELEVEL_METADATA = value/parameter level metadata
* COMPUTATIONAL_MKETHOD = computational methods
* CODELISTS = controlled terminology metadata
* ANALYSIS_RESULTS = ADaM analysis metadata. [Only for ADaM define]
* EXTERNAL_LINKS = ADaM results file pointers. [Only for ADaM define]
*---------------------------------------------------------------*;

%macro make_define(path=,metadata=);

**** GET DEFINE FILE HEADER INFORMATION METADATA;
proc import 
    out = define_header
    datafile = "&path\&metadata" 
    dbms=xlsx 
    replace;
    sheet="DEFINE_HEADER_METADATA";
run;

**** DETERMINE IF THIS IS A SDTM DEFINE FILE OR AN ADAM DEFINE FILE
**** AND SET THE STANDARD MACRO VARIABLE FOR THE REST OF THE PROGRAM;
data _null_;
	set define_header;

    if upcase(standard) = 'ADAM' then
        call symput('standard','ADAM');
    else if upcase(standard) = 'SDTM' then
        call symput('standard','SDTM');
    else
        put "ERR" "OR: CDISC standard undefined in define_header_metadata";
run;

**** GET "TABLE OF CONTENTS" LEVEL DATASET METADATA;
proc import 
    out = toc_metadata
    datafile = "&path\&metadata" 
    dbms=xlsx 
    replace;
    sheet = "TOC_METADATA" ;
run;

**** GET THE VARIABLE METADATA;
proc import 
    out = VARIABLE_METADATA
    datafile = "&path\&metadata"
    dbms=xlsx
    replace;
    sheet = "VARIABLE_METADATA";
run;

**** GET THE CODELIST METADATA;
proc import 
    out = codelists
    datafile = "&path\&metadata" 
    dbms=xlsx
    replace;
    sheet = "CODELISTS" ;
run; 

**** GET THE COMPUTATIONAL METHOD METADATA;
proc import 
    out = compmethod
    datafile = "&path\&metadata" 
    dbms=xlsx
    replace;
    sheet = "COMPUTATION_METHOD" ;
run; 

**** GET THE VALUE LEVEL METADATA;
proc import 
    out = valuelevel
    datafile = "&path\&metadata" 
    dbms=xlsx
    replace;
    sheet = "VALUELEVEL_METADATA" ;
run; 

%if "&standard" = "ADAM" %then
  %do;
    **** GET THE ANALYSIS RESULTS METADATA;
    proc import 
        out = analysisresults
        datafile = "&path\&metadata" 
        dbms=xlsx
        replace;
        sheet = "ANALYSIS_RESULTS" ;
    run; 

    **** GET THE ANALYSIS RESULTS METADATA;
    proc import 
        out = externallinks
        datafile = "&path\&metadata" 
        dbms=xlsx
        replace;
        sheet = "EXTERNAL_LINKS" ;
    run; 
  %end;

**** USE HTMLENCODE ON SOURCE TEXT THAT NEEDS ENCODING FOR PROPER BROWSER REPRESENTATIION;
%if &standard=ADAM %then
  %do;
  
    data toc_metadata;
      	length documentation $ 800;
            set toc_metadata;
      
          documentation = htmlencode(documentation);
          ** convert single quotes to double quotes;
          documentation = tranwrd(documentation, "'", '"');
          ** convert double quotes to html quote;
          documentation = tranwrd(trim(documentation), '"', '&quot;');
          format documentation $800.;
    run;
  
  %end;
  
        
data variable_metadata;
	length comment $ 2000;
	set variable_metadata;

	format comment;
	informat comment;	
    origin = htmlencode(origin); 
	label = htmlencode(label); 
	comment = htmlencode(comment); 

    **** FOR ADAM, JOIN ORIGIN/"SOURCE" AND COMMENT
	**** TO FORM "SOURCE/DERIVATION" METADATA;
	if "&standard" = "ADAM" and origin ne '' and 
        comment ne '' then 
      comment = "SOURCE: " || left(trim(origin)) ||
                " DERIVATION: " || left(trim(comment)); 
	else if "&standard" = "ADAM" and origin ne '' and 
        comment = '' then 
      comment = "SOURCE: " || left(trim(origin)); 
	if "&standard" = "ADAM" and origin = '' and 
        comment ne '' then 
      comment = "DERIVATION: " || left(trim(comment)); 
run;

data codelists;
	set codelists;

	codedvalue = htmlencode(codedvalue);
	translated = htmlencode(translated);
run;

data compmethod;
	set compmethod;

	computationmethod = htmlencode(computationmethod); 
run;

data valuelevel;
	length comment $ 2000;
	set valuelevel;

	format comment;
	informat comment;	
    origin = htmlencode(origin); 
	label = htmlencode(label); 
	comment = htmlencode(comment); 

    **** FOR ADAM, JOIN ORIGIN/"SOURCE" AND COMMENT
	**** TO FORM "SOURCE/DERIVATION" METADATA;
	if "&standard" = "ADAM" and origin ne '' and 
        comment ne '' then 
      comment = "SOURCE: " || left(trim(origin)) ||
                " DERIVATION: " || left(trim(comment)); 
	else if "&standard" = "ADAM" and origin ne '' and 
        comment = '' then 
      comment = "SOURCE: " || left(trim(origin)); 
	if "&standard" = "ADAM" and origin = '' and 
        comment ne '' then 
      comment = "DERIVATION: " || left(trim(comment)); 
run;


%if "&standard" = "ADAM" %then
  %do;
    data analysisresults;
         length programmingcode $800. docleafid $40.;
	  set analysisresults;
      where displayid ne '';
          
      arrow + 1;
      selectioncriteria = htmlencode(selectioncriteria); 
      paramlist = htmlencode(paramlist);
      reason = htmlencode(reason); 
      documentation = htmlencode(documentation);
      if index(documentation, '[r]')>0 then
        docleafid = substr(documentation, index(documentation,'[r]')+3, index(documentation,'[\r]')-index(documentation,'[r]')-3);
      else
        docleafid = '.';
          
      programmingcode = htmlencode(programmingcode); 
      ** convert single quotes to double quotes;
      programmingcode = tranwrd(programmingcode, "'", '"');
      ** convert double quotes to html quote;
      programmingcode = tranwrd(programmingcode, '"', '&quot;');
      format programmingcode $800.;
    run;

    ** ENSURE UNIQUENESS ON DISPLAYID AND RESULTID AND CREATE A COMBO ID;
    data analysisresults;
      set analysisresults;
      by displayid notsorted;
    
      drop resultnum;
      retain resultnum;
      if first.displayid then
          resultnum = 0;
      resultnum + 1;
      if not(first.displayid and last.displayid) then
          arid = trim(displayid) || ".R." || put(resultnum,z2.);
      else
          arid = displayid;
    run;          
            
    ** IF DOCLEAFID IS NON-MISSING, MERGE IN THE TITLE FROM EXTERNAL_LINKS;
    proc sort
      data = analysisresults;
      by docleafid;
    run;
 
    proc sort
      data = externallinks (keep = leafid title rename=(leafid=docleafid title=doctitle))
      out  = doc_links;
      by docleafid;
    run;
 
    data analysisresults;
      merge analysisresults (in = inar) doc_links (in = indoc_links);
      by docleafid;
    
      if inar;
      ** if the leaf ID exists, then the title of the leaf ID will be printed and can be removed from DOCUMENTIATION;
      if indoc_links then
        documentation = tranwrd(documentation, '[r]' || trim(docleafid) || '[\r]', " ");
    run;

    proc sort
      data = analysisresults;
      by arrow;
    run;
  %end;
    
**** CREATE DEFINE FILE HEADER SECTION;
filename dheader "&path\define_header.txt";
data define_header;
    set define_header;

    file dheader notitles;

	creationdate = compress(put(datetime(), IS8601DT.));

    put @1 '<?xml version="1.0" encoding="ISO-8859-1" ?>' /
        @1 '<?xml-stylesheet type="text/xsl" href="' stylesheet +(-1) '"?>' /
        @1 '<!-- ******************************************************************************* -->' /
        @1 '<!-- File: define.xml                                                                -->' /
        @1 "<!-- Date: &sysdate9.                                                                -->" /
        @1 '<!-- Description: Define.xml file for '   studyname +(-1) '                          -->' /
        @1 '<!-- ******************************************************************************* -->' /
        @1 '<ODM' /
        @3 'xmlns="http://www.cdisc.org/ns/odm/v1.2"' /
        @3 'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' /
        @3 'xmlns:xlink="http://www.w3.org/1999/xlink"' /
        @3 'xmlns:def="http://www.cdisc.org/ns/def/v1.0"' /
        %if "&standard" = "ADAM" %then
          @3 'xmlns:adamref="http://www.cdisc.org/ns/ADaMRes/DRAFT"' /
        ;
        @3 'xsi:schemaLocation="' schemalocation +(-1) '"' /
        @3 'FileOID="' fileoid +(-1) '"' /
        @3 'ODMVersion="1.2"' /
        @3 'FileType="Snapshot"' /
        @3 'CreationDateTime="' creationdate +(-1) '">' /
        @1 '<Study OID="' studyoid +(-1) '">' /
        @3 '<GlobalVariables>' /
        @5 '<StudyName>' studyname +(-1) '</StudyName>' /
        @5 '<StudyDescription>' studydescription +(-1) '</StudyDescription>' /
        @5 '<ProtocolName>' protocolname +(-1) '</ProtocolName>' /
        @3 '</GlobalVariables>' /
        @3 '<MetaDataVersion OID="CDISC.' standard +(-1) '.' version +(-1) '"' /
        @5 'Name="' studyname +(-1) ',Data Definitions"' /
        @5 'Description="' studyname +(-1) ',Data Definitions"' /
        @5 'def:DefineVersion="1.0.0"' /
        @5 'def:StandardName="CDISC ' standard +(-1) '"' /
        @5 'def:StandardVersion="' version +(-1) '">' /
        %if "&standard" = "ADAM" %then
          %do;
            @5 '<def:SupplementalDoc>' /
            @7 '<def:DocumentRef leafID="Suppdoc"/>' /
            @5 '</def:SupplementalDoc>' /
            @5 '<def:leaf ID="Suppdoc" xlink:href="dataguide.pdf">' /
            @7 '<def:title>Data Guide</def:title>' /
          %end;
        %else %if "&standard" = "SDTM" %then
          %do;
            @5 '<def:AnnotatedCRF>' /
            @7 '<def:DocumentRef leafID="blankcrf"/>' /
            @5 '</def:AnnotatedCRF>' /
            @5 '<def:leaf ID="blankcrf" xlink:href="blankcrf.pdf">' /
            @7 '<def:title>Annotated Case Report Form</def:title>' /
          %end;
        @5 '</def:leaf>';
run;

**** ADD OTHER ADAM EXTERNAL LINKS;
%if "&standard" = "ADAM" %then
  %do;
    filename leaves "&path\leaves.txt";
    data _null_;
      set externallinks;
  
      file leaves notitles;

      put @5 '<def:leaf ID="' leafid +(-1) '"'     /
          @7 'xlink:href="' leafrelpath +(-1) '">' /
          @7 '<def:title>' title '</def:title>'    /
          @5 '</def:leaf>'
          ;
    run;            
  %end;


**** ADD ITEMOID TO VARIABLE METADATA;
data variable_metadata;
    set variable_metadata(rename=(domain = oid));

    length itemoid $ 40;
    if variable in ("STUDYID","DOMAIN","USUBJID","SUBJID") then
      itemoid = variable;
    else
      itemoid = compress(oid || "." || variable);
run;

**** ADD ITEMOID TO VALUE LEVEL METADATA;
data valuelevel;
    set valuelevel;

    length itemoid $ 200;
    itemoid = compress(valuelistoid || "." || valuename);
run;

**** CREATE COMPUTATION METHOD SECTION;
filename comp "&path\compmethod.txt";
data compmethods;
    set compmethod;

    file comp notitles;

    if _n_ = 1 then
    put @5 "<!-- ******************************************* -->" /
        @5 "<!-- COMPUTATIONAL METHOD INFORMATION        *** -->" /    
        @5 "<!-- ******************************************* -->";
    put @5 '<def:ComputationMethod OID="' computationmethodoid +(-1) '">' computationmethod +(-1) '</def:ComputationMethod>';   
run;


**** CREATE VALUE LEVEL LIST DEFINITION SECTION;
proc sort
    data=valuelevel;
    where valuelistoid ne '';
    by valuelistoid;
run;

filename vallist "&path\valuelist.txt";
data valuelevel;
  set valuelevel;
    by valuelistoid;

    file vallist notitles;

    if _n_ = 1 then
      put @5 "<!-- ******************************************* -->" /
          @5 "<!-- VALUE LEVEL LIST DEFINITION INFORMATION  ** -->" /    
          @5 "<!-- ******************************************* -->";

    if first.valuelistoid then
      put @5 '<def:ValueListDef OID="' valuelistoid +(-1) '">';

    put @7 '<ItemRef ItemOID="' itemoid /*valuename*/ +(-1) '"' /
        @9 'Mandatory="' mandatory +(-1) '"/>';

    if last.valuelistoid then
      put @5 '</def:ValueListDef>';
run;



**** CREATE "ITEMGROUPDEF" SECTION;
proc sort
    data=VARIABLE_METADATA;
    where oid ne '';
    by oid varnum;
run;

proc sort
    data=toc_metadata;
    where oid ne '';
    by oid;
run;

filename igdef "&path\itemgroupdef.txt";
data itemgroupdef;
    length label $ 40;
    merge toc_metadata VARIABLE_METADATA(drop=label);
    by oid;

    file igdef notitles; 

    if first.oid then
      do;
        put @5 "<!-- ******************************************* -->" /
            @5 "<!-- " oid   @25   "ItemGroupDef INFORMATION *** -->" /    
            @5 "<!-- ******************************************* -->" /
            @5 '<ItemGroupDef OID="' oid +(-1) '"' /
            @7 'Name="' name +(-1) '"' /
            @7 'Repeating="' repeating +(-1) '"' /
            @7 'Purpose="' purpose +(-1) '"' /
            @7 'IsReferenceData="' isreferencedata +(-1) '"' /
            @7 'def:Label="' label +(-1) '"' /
            @7 'def:Structure="' structure +(-1) '"' /
            @7 'def:DomainKeys="' domainkeys +(-1) '"' /
            @7 'def:Class="' class +(-1) '"' ;
        %if &standard=ADAM %then
          put @7 'def:ArchiveLocationID="Location.' archivelocationid +(-1) '"' /
              @7 'Comment="' documentation +(-1) '">' 
              ;
        %else 
          put @7 'def:ArchiveLocationID="Location.' archivelocationid +(-1) '">';        
        ;
      end;

    put @7 '<ItemRef ItemOID="' itemoid +(-1) '"' /
        @9 'OrderNumber="' varnum +(-1) '"' /
        @9 'Mandatory="' mandatory +(-1) @;
		
    if role ne '' and "&standard" = "SDTM" then
      put '"' /
      @9 'Role="' role +(-1) '"' /
      @9 'RoleCodeListOID="CodeList.' rolecodelist +(-1) '"/>';
    else
      put '"/>';


    if last.oid then
      put @7 "<!-- **************************************************** -->" /
          @7 "<!-- def:leaf details for hypertext linking the dataset   -->" /
          @7 "<!-- **************************************************** -->" /
          @7 '<def:leaf ID="Location.' oid +(-1) '" xlink:href="' archivelocationid +(-1) '.xpt">' /
          @9 '<def:title>' archivelocationid +(-1) '.xpt </def:title>' /
          @7 '</def:leaf>' /
          @5 '</ItemGroupDef>';
run;
  

**** CREATE "ITEMDEF" SECTION;
filename idef "&path\itemdef.txt";
 
data itemdef;
    set VARIABLE_METADATA end=eof;
    by oid;

    file idef notitles; 

    if _n_ = 1 then
      put @5 "<!-- ************************************************************ -->" /
          @5 "<!-- The details of each variable is here for all domains         -->" /
          @5 "<!-- ************************************************************ -->" ;

    put @5 '<ItemDef OID="' itemoid +(-1) '"' /
        @7 'Name="' variable +(-1) '"' /
        @7 'DataType="' type +(-1) '"' /
        @7 'Length="' length +(-1) '"';
    if significantdigits ne '' then
      put @7 'SignificantDigitis="' significantdigits +(-1) '"';
    if displayformat ne '' then
      put @7 'def:DisplayFormat="' displayformat +(-1) '"';
    if computationmethodoid ne '' then
      put @7 'def:ComputationMethodOID="' computationmethodoid +(-1) '"';
    put %if "&standard" = "SDTM" %then 
        @7 'Origin="' origin +(-1) '"' / ;
	    @7 'Comment="' comment +(-1) '"' / 			
        @7 'def:Label="' label +(-1) '">';

    if codelistname ne '' then
      put @7 '<CodeListRef CodeListOID="CodeList.' codelistname +(-1) '"/>';

    if valuelistoid ne '' then
      put @7 '<def:ValueListRef ValueListOID="' valuelistoid +(-1) '"/>';

    put @5 '</ItemDef>';
run;
 

**** ADD ITEMDEFS FOR VALUE LEVEL ITEMS TO "ITEMDEF" SECTION;
filename idefvl "&path\itemdef_value.txt";
 
data itemdefvalue;
    set valuelevel end=eof;
    by valuelistoid;

    file idefvl notitles; 

    if _n_ = 1 then
      put @5 "<!-- ************************************************************ -->" /
          @5 "<!-- The details of value level items are here                    -->" /
          @5 "<!-- ************************************************************ -->" ;

    put @5 '<ItemDef OID="' itemoid /*valuename*/ +(-1) '"' /
        @7 'Name="' valuename +(-1) '"' /
        @7 'DataType="' type +(-1) '"' /
        @7 'Length="' length +(-1) '"';
    if significantdigits ne '' then
      put @7 'SignificantDigitis="' significantdigits +(-1) '"';
    if displayformat ne '' then
      put @7 'def:DisplayFormat="' displayformat +(-1) '"';
    if computationmethodoid ne '' then
      put @7 'def:ComputationMethodOID="' computationmethodoid +(-1) '"';
    put %if "&standard" = "SDTM" %then 
        @7 'Origin="' origin +(-1) '"' / ;
        @7 'Comment="' comment +(-1) '"' / 			
        @7 'def:Label="' label +(-1) '">';

    if codelistname ne '' then
      put @7 '<CodeListRef CodeListOID="CodeList.' codelistname +(-1) '"/>';

    put @5 '</ItemDef>';
run;
 

**** ADD ANALYSIS RESULTS METADATA SECTION FOR ADAM;
%if "&standard" = "ADAM" %then
  %do;
    filename ar "&path\analysisresults.txt";

    data _null_;
      set analysisresults;
      ** note that it is required that identical display IDs be adjacent to 
	  ** each other in the metadata spreadsheet;
      by displayid notsorted;

      file ar notitles; 
      if _n_ = 1 then
        put @5 "<!-- ************************************************************ -->" /
            @5 "<!-- Analysis Results MetaData are Presented Below                -->" /
            @5 "<!-- ************************************************************ -->" 
            ;
      if first.displayid then
        put @5 '<adamref:AnalysisResultDisplays>' /
            @7 '<adamref:ResultDisplay DisplayIdentifier="' displayid +(-1) 
               '" OID="' displayid +(-1) '" DisplayLabel="' displayname +(-1) 
               '" leafID="' displayid +(-1) '">'  ;
          
      put @9 '<adamref:AnalysisResults ' /
          @9 'OID="' arid +(-1) '"' /
          @9 'ResultIdentifier="' resultid +(-1) '"' /
          @9 'Reason="' reason +(-1) '">' /
          @9 '<!-- List the parameters and parameter codes -->' /
          @9 '<adamref:ParameterList>'
          ;
        
      ** loop through PARAMCD/PARAM sets;
      set = 1;
      do while(scan(paramlist,set,'|') ne '');
        paramset = scan(paramlist,set,'|');
        paramcd  = scan(paramset,1,'/\');
        param    = trim(scan(paramset,2,'/\'));
        put @11 '<adamref:Parameter ParamCD="' paramcd +(-1) 
                '" Param="' param +(-1) '"/>' ;
        set = set + 1;
      end;
      put @9 '</adamref:ParameterList>';
    
      ** loop through the analysis variables;
      set = 1;
      do while(scan(analysisvariables,set,',') ne '');
        analysisvar = scan(analysisvariables,set,',');
        put @11 '<adamref:AnalysisVariable ItemOID="' analysisdataset +(-1) 
                '.' analysisvar +(-1) '"/>';
        set = set + 1;
      end;
      put @9 '<!-- AnalysisDatasets are  pairs of dataset references and selection criteria. Dataset references are ItemGroupRefs.  The label in the xsl is the def:label for the ItemGroup -->';
      put @9 '<adamref:AnalysisDataset>' /
          @11  '<ItemGroupRef ItemGroupOID="' analysisdataset +(-1) '" Mandatory="No"/>' /
          @11  '<adamref:SelectionCriteria>' /
          /* just use the row number of the data set as the unique number for the selection criteria */
          @13    '<def:ComputationMethod OID="SC' _n_ z3. 
                 '" Name="Selection Criteria ' _n_ z3. '"> [' selectioncriteria ' ]</def:ComputationMethod> '/
          @11  '</adamref:SelectionCriteria> ' /
          @9 '</adamref:AnalysisDataset> ' /
          @9 '<adamref:Documentation leafID="' docleafid +(-1) '">' /
          @11  '<TranslatedText xml:lang="en">' Documentation  /
          @11  '</TranslatedText>'        /
          @9  '</adamref:Documentation>'  /
          @9  '<adamref:ProgrammingCode>' /
          @9  '<def:ComputationMethod OID="'  displayid +(-1) '">' /
          @1  ProgrammingCode /
          @9 '</def:ComputationMethod>' /
          @9 '</adamref:ProgrammingCode>' /
          @7 '</adamref:AnalysisResults>' ;
        
      if last.displayid then
        put @5 '</adamref:ResultDisplay>' /
            @5 '</adamref:AnalysisResultDisplays>'
            ;
    run;  
  %end;


**** CREATE CODELIST SECTION;
filename codes "&path\codelist.txt";
 
proc sort
    data=codelists
    nodupkey;
    by codelistname codedvalue translated;
run;

**** MAKE SURE CODELIST IS UNIQUE;
data _null_;	
    set codelists;
    by codelistname codedvalue;

    if not (first.codedvalue and last.codedvalue) then 
      put "ERR" "OR: multiple versions of the same coded value " 
           codelistname= codedvalue=;
run;

proc sort
    data=codelists;
    by codelistname rank;	
run;

data codelists;
    set codelists end=eof;
    by codelistname rank;

    file codes notitles; 

    if _n_ = 1 then
      put @5 "<!-- ************************************************************ -->" /
          @5 "<!-- Codelists are presented below                                -->" /
          @5 "<!-- ************************************************************ -->" ;

    if first.codelistname then
      put @5 '<CodeList OID="CodeList.' codelistname +(-1) '"' /
          @7 'Name="' codelistname +(-1) '"' /
          @7 'DataType="' type +(-1) '">';

    **** output codelists that are not external dictionaries;
    if codelistdictionary = '' then
	  do;
        put @7  '<CodeListItem CodedValue="' codedvalue +(-1) '"' @;
        if rank ne . then
	      put ' def:Rank="' rank +(-1) '">';
	    else 
	      put '>';
        put @9  '<Decode>' /
            @11 '<TranslatedText>' translated +(-1) '</TranslatedText>' /
            @9  '</Decode>' /
            @7  '</CodeListItem>';
      end;
    **** output codelists that are pointers to external codelists;
    if codelistdictionary ne '' then
      put @7 '<ExternalCodeList Dictionary="' codelistdictionary +(-1) 
             '" Version="' codelistversion +(-1) '"/>';

    if last.codelistname then
      put @5 '</CodeList>';

    if eof then
      put @3 '</MetaDataVersion>' /
          @1 '</Study>' /
          @1 '</ODM>';
run; 

%mend make_define;

%make_define(path=/folders/myfolders/define/sdtm/,metadata=SDTM_METADATA.xlsx);
%make_define(path=/folders/myfolders/define/adam/,metadata=ADAM_METADATA.xlsx);
