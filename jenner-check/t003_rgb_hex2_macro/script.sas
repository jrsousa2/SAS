/* Caller for the %Hex2 / %RGB macros defined in                        */
/* "Proc Report/Proc Report-SIU metrics.sas" in jrsousa2/SAS.           */
/* The two macro definitions below are byte-identical to the source;    */
/* the %RGB(...) calls and PROC PRINT are a caller we wrote to exercise */
/* them, since the source file defines them but has no isolated test.   */

/* THIS IS FOR THE MAIN REPORT */
/* Creating the excel file for the final report out */
/* This macro sets the formatting style as well as the capablility to use RGB
/* to align with the company's brand center*/
%macro Hex2(n);
%local digits n1 n2;
%let digits = 0123456789ABCDEF;
%let n1 = %substr(&digits, &n / 16 + 1, 1);
%let n2 = %substr(&digits, &n - &n / 16 * 16 + 1, 1);
&n1&n2
%mend Hex2;

%macro RGB(R,G,B);
        %cmpres(CX%hex2(&R)%hex2(&G)%hex2(&B))
%mend RGB;

/* Caller: builds a small table of brand colors using %RGB, one call    */
/* per row, matching the company-brand-center use case from the source */
/* (the original calls %RGB(0,145,204) inline for a report title color) */
data brand_colors;
    length Color_Name $20. Hex_Code $10.;
    Color_Name = "Company Blue"; Hex_Code = "%RGB(0,145,204)"; output;
    Color_Name = "Pure White";   Hex_Code = "%RGB(255,255,255)"; output;
    Color_Name = "Pure Black";   Hex_Code = "%RGB(0,0,0)"; output;
    Color_Name = "Highlight";    Hex_Code = "%RGB(255,235,59)"; output;
run;

proc print data=brand_colors noobs;
run;
