/*Process the raw dose data from an Excel file
Key points: 1) make up missing dates; 2)convert Excel dates to SAS dates
*/

%include '/folders/myfolders/test1/common.sas';
%common;

libname ds xlsx "/folders/myfolders/test1/ds.xlsx";

data source.dosing;
set ds.Sheet1;
if find(startdt,'/') then
do;
  array var1(3) $4.;
  do i=1 to 3;
    var1(i)=scan(startdt,i,"/");
    if var1(i)=' ' then
    var1(i)='1';
  end;
  startdt1=mdy(input(var1(1),$4.), input(var1(2),$4.) , input(var1(3),$4.)); 
end;
else
  startdt1=input(startdt,$10.)-21916;
if find(enddt,'/') then
do;
  array var2(3) $4.;
  do i=1 to 3;
    var2(i)=scan(enddt,i,"/");
    if var2(i)=' ' then
    var2(i)='1';
  end;
  enddt1=mdy(input(var2(1),$4.), input(var2(2),$4.) , input(var2(3),$4.)); 
end;
else
  enddt1=input(enddt,$10.)-21916;
uniqueid = 'UNI' || put(subject,3.);
format startdt1 enddt1 mmddyy10.;
drop i startdt enddt var11-var13 var21-var23;
rename startdt1=startdt enddt1=enddt;
run;

