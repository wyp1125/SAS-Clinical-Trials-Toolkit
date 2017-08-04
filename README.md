
# SAS-Clinical-Trials-Toolset
SAS scripts for clinical trials applications including generating SDTM domains, ADaM datasets, and Define.xml files.

Important: The data and programs in this toolset were derived from Holland and Shostak (2012). However, extensive modifications were made
throughout the data and programs. All the programs are fully tested and correctly functional under SAS University Edition and Windows 10 OS.

1. Preprocess programs

a) "common.sas": common library settings

b) "dm.sas": reads in "dm.csv" to process raw demographic data

c) "ae.sas": reads in "ae.xlsx" to process raw adverse event data

d) "ds.sas": reads in "ds.xlsx" to process raw dosage data

e) "pn.sas": reads in "pn.dat" to process raw pain score data

f) "lab.sas": reads in "lab.xls" to process raw labs data

2. "Define.xml" program

"make_define.sas": contains a macro "%make_define" to generate parts of the define.xml file for the SDTM and ADaM, which can be further concatenated into the define.xml file.

3. SDTM programs

a) "make_empty_dataset.sas": contains a macro "%make_empty_dataset" to generate an empty domain dataset according to the variable list specified in the metadata file "SDTM_METADATA.xlsx".

b) 

4. ADaM pprograms
