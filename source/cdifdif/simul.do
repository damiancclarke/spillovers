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

********************************************************************************
*** (2) Generate distance spillover
********************************************************************************
local bwidth=10

foreach dist of numlist 0(10)40 {
    local up=`dist'+`bwidth'
    gen d`up'=postDist>`dist'&postDist<=`up'
}   

drop T D

********************************************************************************
*** (3) Simulate dependent variable
********************************************************************************
gen y = 5 + 1*y2005 + 2*y2006 + 3*y2007 + 4*y2008 + 5*y2009 + 10*postTreat /*
*/ + 8*d10 + 6*d20 + 4*d30 + 2*d40 + 0*d50 + 3*rnormal()


********************************************************************************
*** (4) Regressions
********************************************************************************
reg y i.year

mat def Treat=J(6,3,.)
mat def Close=J(5,3,.)

local ctrl1 postTreat
local ctrl2 postTreat d10
local ctrl3 postTreat d10 d20
local ctrl4 postTreat d10 d20 d30
local ctrl5 postTreat d10 d20 d30 d40
local ctrl6 postTreat d10 d20 d30 d40 d50

foreach i of numlist 1/6 {

    reg y i.year `ctrl`i''
    mat Treat[`i',1]=_b[postTreat]-1.96*_se[postTreat]
    mat Treat[`i',2]=_b[postTreat]
    mat Treat[`i',3]=_b[postTreat]+1.96*_se[postTreat]

    if `i'>1 {
        local j    = `i'-1
        local marg = `j'*10
        mat Close[`j',1]=_b[d`marg']-1.96*_se[d`marg']
        mat Close[`j',2]=_b[d`marg']
        mat Close[`j',3]=_b[d`marg']+1.96*_se[d`marg']
    }
}
