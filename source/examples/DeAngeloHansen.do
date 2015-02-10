/* DeAngeloHansen.do v0.00          damiancclarke          yyyy-mm-dd:2015-02-10
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file replicates the main analysis in DeAngelo and Hansen (2014), augmenting
to test for local spillovers in difference-in-differences specifications. The m-
ain equation is as follows:

 fatal_smy/VMT_sy = b*(OR*after) + y_y + s_s + m_m + X'_smy a + u

where E is employment at time t and municipality m, and pi are a series of event
study coefficients based on when the municipality in question entered Seguro Po-
pular.  The specification is agumented to estimate close coefficients as per:

 fatal_smy/VMT_sy = b*(OR*after) + c*(close*after) y_y + s_s + m_m + X'_smy a + u

where now we are interested in testing close coefficients c, as well as the orig-
inal coefficients (b).

Data comes from the authors' paper, which has been downloaded from the AEJ websi-
te. 
The entire file can be controlled in section 1, where globals and locals should
be set based on locations on the user's machine.

    contact: mailto:damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT "~/investigacion/2014/Spillovers/data/examples/DeAngeloHansen"
global OUT "~/investigacion/2014/Spillovers/results/examples/DeAngeloHansen" 
global LOG "~/investigacion/2014/Spillovers/log"

log using "$LOG/DeAngeloHansen.txt", text replace

local prep  1
local regs  0
local graph 0

********************************************************************************
*** (2) Merge distance data into DeAngelo Hansen original data
********************************************************************************
if `prep'==1 {
    use "$DAT/fatal_analysis_file_1814.dta"


********************************************************************************
*** (3) Calculate distance to nearest treatment municipality
********************************************************************************
}



********************************************************************************
*** (4) Clean up, save
********************************************************************************

lab dat "DeAngelo Hansen (2014) data augmented to include distance to treatment"
save "$DAT/DeAngeloHansenDistance", replace
}


********************************************************************************
*** (5) Regressions
********************************************************************************
if `regs'==1 {
    use "$DAT/BoschCamposDistance"

    **REPRODUCE BOSCH CAMPOS-VAZQUEZ REGRESSIONS

    
    **TEST DISTANCE REGRESSION
    sum dist if dist>0
    local d = round(0.05*r(sd))
    local d1 0 `=1*`d'' `=2*`d'' `=3*`d'' `=4*`d'' `=5*`d''
    tokenize `d1'

    
    foreach d2 of numlist `=1*`d'' `=2*`d'' `=3*`d'' `=4*`d'' `=5*`d'' `=6*`d'' {
        dis "distance between `1' and `d2'"

        gen Close_`d2'    = dist>`1'    & dist < `d2'
    
}

********************************************************************************
*** (6) Graphs
********************************************************************************
if `graph'==1 {
matrix colnames ests = lbTreat bTreat ubTreat lbClose bClose ubClose
svmat ests, names(col)

gen lag=.
gen closeIt=0 in 1/7
replace closeIt=`=1*`d'' in 8/14
replace closeIt=`=2*`d'' in 15/21
replace closeIt=`=3*`d'' in 22/28
replace closeIt=`=4*`d'' in 29/35
replace closeIt=`=5*`d'' in 36/42
replace closeIt=`=6*`d'' in 43/49


foreach n of numlist 1(7)43 {
    replace lag=3  in `n'
    replace lag=2  in `=`n'+1'
    replace lag=0  in `=`n'+2'
    replace lag=-1 in `=`n'+3'
    replace lag=-2 in `=`n'+4'
    replace lag=-3 in `=`n'+5'
    replace lag=-4 in `=`n'+6'    
}


foreach l of numlist -4 -3 -2 -1 0 2 3 {
    #delimit ;
    twoway line bTreat closeIt if lag==`l' ||                    
           line lbTreat closeIt if lag==`l', lpattern(dash) || 
           line ubTreat closeIt if lag==`l', lpattern(dash) scheme(s1mono)
       yline(0, lpattern(dot)) legend(order(1 "Point Estimate" 2 "95% CI"))
       xtitle("Distance") ytitle("Effect SP on Employers" " ");
    graph export "$OUT/MainEstimate_Lag`l'.eps", as(eps) replace;

    twoway line bClose closeIt if lag==`l' & bClose!=. ||
           line lbClose closeIt if lag==`l'&lbClose!=., lpattern(dash) || 
           line ubClose closeIt if lag==`l'&lbClose!=., lpattern(dash)
    scheme(s1mono) yline(0, lpattern(dot)) xtitle("Distance") 
    legend(order(1 "Point Estimate" 2 "95% CI"))
    ytitle("Effect SP on Employers" " ");
    graph export "$OUT/CloseEstimate_Lag`l'.eps", as(eps) replace;
    #delimit cr
}
}
