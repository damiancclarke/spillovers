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
*** (0) Globals and locals
********************************************************************************
global OUT "~/investigacion/2014/Spillovers/results/cdifdif"

local gra 0 
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
mat def Close=J(6,3,.)

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
        local marg = (`i'-1)*10
        mat Close[`i',1]=_b[d`marg']-1.96*_se[d`marg']
        mat Close[`i',2]=_b[d`marg']
        mat Close[`i',3]=_b[d`marg']+1.96*_se[d`marg']
    }
}

********************************************************************************
*** (5) Graphs
********************************************************************************
if `gra'==1 {
svmat Treat
svmat Close

gen dist = (_n-1)*10 in 1/6

#delimit ;
line Treat1 dist, lpattern("---") lcolor(gs10) ||
line Treat2 dist, lpattern(solid) lcolor(gs0)  ||
line Treat3 dist, lpattern("---") lcolor(gs10)
scheme(s1mono) legend(order(1 2) label(1 "95% CI") label(2 "Point Estimate"))
title("Treatment Effect with Spillovers")
xtitle("Spillover Distance") ytitle("Estimated Treatment Effect");
#delimit cr

graph export "$OUT/treatmentEffect.eps", as(eps) replace 

#delimit ;
line Close1 dist if Close1!=., lpattern("---") lcolor(gs10) ||
line Close2 dist if Close1!=., lpattern(solid) lcolor(gs0)  ||
line Close3 dist if Close1!=., lpattern("---") lcolor(gs10)
scheme(s1mono) legend(order(1 2) label(1 "95% CI") label(2 "Point Estimate"))
title("Effect of Spillovers on Nearby Areas")
xtitle("Spillover Distance") ytitle("Effect of Spillover");
#delimit cr
graph export "$OUT/spilloverEffect.eps", as(eps) replace

drop Treat1 Treat2 Treat3
drop Close1 Close2 Close3
mat list Close
mat list Treat
}
********************************************************************************
*** (6) cdifdif trials
********************************************************************************
do cdifdif.ado

gen cluster=.
foreach num of numlist 1(1)100 {
    local low =(`num'-1)*120+1
    local high=(`num')*120
    qui replace cluster=`num' in `low'/`high'
}

cdifdif y postTreat i.year, close(distance) bandw(10) timevar(year) tyear(2008) /*
*/ treatvar(postTreat)
