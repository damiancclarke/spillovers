/* simul.do v0.00                damiancclarke             yyyy-mm-dd:2014-12-24
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file simulates difference in difference data, where the outcome is depende-
nt upon treatment, and being close to treatment. The specification is of the fo-
rm:

y_it = alpha + beta 

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Simulate independent variables
********************************************************************************
set obs 12000
gen year=.

foreach yr of numlist 1(1)6 {
    local low  = (`yr'-1)*2000+1
    local high = `yr'*2000
    local year=2004+`yr'
    dis `low' `high'
    replace year=`year' in `low'/`high'
    gen y`year'=year==`year'
}

gen T = runiform()
gen D = runiform()*100
gen treatment = T>0.75
gen distance  = (1-treatment)*D
gen postTreat = treatment==1&year>=2008
gen postDist  = distance if year>=2008
replace postDist = 0 if postDist==.

drop T D

********************************************************************************
*** (2) Simulate dependent variable
********************************************************************************
gen y = 5 + 1*y2005 + 2*y2006 + 3*y2007 + 4*y2008 + 5*y2009 + 10*postTreat /*
*/ + 3*rnormal()
