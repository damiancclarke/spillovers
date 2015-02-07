/* BoschCampos.do v0.00          damiancclarke             yyyy-mm-dd:2015-02-06
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file replicates the main analysis in Bosch and Campos-Vazquez (2014), augm-
enting to test for local spillovers in difference-in-differences specifications.
The main equation is as follows:

  E_mt = a + d P_mt + sum_j pi_{jmy} 1(t_my=j) + controls + FEs + trends 

where E is employment at time t and municipality m, and pi are a series of event
study coefficients based on when the municipality in question entered Seguro Po-
pular.  The specification is agumented to estimate close coefficients as per:

  E_mt = a + d P_mt + sum_j[pi_{jmy} 1(t_my=j) + zeta_{jmy} 1(c_my=j)] + ...

where now we are interested in testing close coefficients zeta, as well as the o-
riginal coefficients (pui).

Data comes from the authors' paper, which has been downloaded from the AEJ websi-
te. Municipal distance is calculated from mid-point to mid-point, and is based on
INEGI's official municipality data.

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
global DAT "~/investigacion/2014/Spillovers/data/examples/BoschCampos"
global OUT "~/investigacion/2014/Spillovers/results/examples/BoschCampos" 
global LOG "~/investigacion/2014/Spillovers/log"

log using "$LOG/BoschCampos.txt", text replace

local prep 0
local regs 1

********************************************************************************
*** (2) Merge municipal data into Bosch Campos-Vazquez final dataset
********************************************************************************
if `prep'==1 {
use "$DAT/Reg_t"

merge m:1 cvemun using "$DAT/Municipios"
keep if _merge==3|_merge==1
drop _merge
merge m:1 oid using "$DAT/distMatrix"

********************************************************************************
*** (3) Calculate distance to nearest treatment municipality
********************************************************************************
gen dist=.

foreach y of numlist 2002(1)2011 {
    foreach q of numlist 1(1)4 {
        if `y'==2002&`q'!=4 exit
        if `y'==2011&`q'==4 exit
        
        dis "I am on year `y', quarter `q'"
        
        qui gen takeup`y'_`q' = oid if T==1&year==`y'&quarter==`q'
        qui levelsof takeup`y'_`q', local(muns)
        foreach mun of local muns {
            qui gen _MM`mun'=m`mun'
        }
        qui egen dist`y'_`q' = rowmin(_MM*)
        qui replace dist = dist`y'_`q' if year==`y'&quarter==`q'
        drop _MM* dist`y'_`q' takeup`y'_`q'
    }
}

********************************************************************************
*** (3b) Calculate distance lags
********************************************************************************
forvalues j=4 8 to 16 {
    qui bys cvemun (year quarter): gen dist`j'  = dist[_n-`j']
    qui bys cvemun (year quarter): gen distL`j' = dist[_n+`j']
}
replace distL12=0 if distL12==.
replace distL8=0  if distL8 ==.
replace distL4=0  if distL4 ==.


********************************************************************************
*** (4) Clean up, save
********************************************************************************
drop m1-m84 _merge

lab dat "Bosch Campos (2014) data augmented to include data to treatment"
save "$DAT/BoschCamposDistance", replace
}


********************************************************************************
*** (5) Regressions
********************************************************************************
if `regs'==1 {
    use "$DAT/BoschCamposDistance"

    **REPRODUCE BOSCH CAMPOS-VAZQUEZ REGRESSIONS

    xi: xtreg p_t TbL12x TbL8x Tbx Tb4x Tb8x Tb12x Tb16  log_pop x_t_* /*
    */ i.ent*mydate i.ent*mydate2 i.ent*mydate3 _Ix* [aw=pob2000], fe robust /*
    */ cluster(cvemun)
    outreg2 Tb* using "$OUT/EventStudyReg.xls", excel replace

    mat ests = J(35,6,.)
    local j=1
    foreach v in TbL12x TbL8x Tbx Tb4x Tb8x Tb12x Tb16 {
        mat ests[`j',1]=_b[`v']-1.96*_se[`v']
        mat ests[`j',2]=_b[`v']
        mat ests[`j',3]=_b[`v']+1.96*_se[`v']
        local ++j
    }

    
    **TEST DISTANCE REGRESSION
    local d1 0 10000 20000 30000
    tokenize `d1'

    
    foreach d2 of numlist 10000 20000 30000 40000 {
        dis "distance between `1' and `d2'"

        gen Close_`d2'    = dist>`1'    & dist < `d2'
        gen Close4_`d2'   = dist4>`1'   & dist < `d2'
        gen Close8_`d2'   = dist8>`1'   & dist < `d2'
        gen Close12_`d2'  = dist12>`1'  & dist < `d2'
        gen Close16_`d2'  = dist16>`1'  & dist < `d2'
        gen CloseL8_`d2'  = distL8>`1'  & dist < `d2'
        gen CloseL12_`d2' = distL12>`1' & dist < `d2'
    
        xi: xtreg p_t  log_pop x_t_* i.ent*mydate i.ent*mydate2 i.ent*mydate3 _Ix* /*
        */ TbL12x TbL8x Tbx Tb4x Tb8x Tb12x Tb16 Close* [aw=pob2000], fe robust    /*
        */ cluster(cvemun)
        outreg2 Tb* Close* using "$OUT/EventStudyReg.xls", excel append
        foreach v in TbL12x TbL8x Tbx Tb4x Tb8x Tb12x Tb16 {
            mat ests[`j',1]=_b[`v']-1.96*_se[`v']
            mat ests[`j',2]=_b[`v']
            mat ests[`j',3]=_b[`v']+1.96*_se[`v']
        }
        foreach v in CloseL12_`d2' CloseL8_`d2' Close_`d2' Close4_`d2' Close8_`d2' /*
        */ Close12_`d2' Close16_`d2' {
            mat ests[`j',4]=_b[`v']-1.96*_se[`v']
            mat ests[`j',5]=_b[`v']
            mat ests[`j',6]=_b[`v']+1.96*_se[`v']
            local ++j
        }        
        macro shift
    }

    mat list ests
}

********************************************************************************
*** (6) Graphs
********************************************************************************
matrix colnames ests = lbTreat bTreat ubTreat lbClose cClose ubClose
svmat ests, names(col)

gen lag=.
gen closeIt=0 in 1/7
replace closeIt=10 in 8/14
replace closeIt=20 in 15/21
replace closeIt=30 in 22/28
replace closeIt=40 in 29/35

foreach n of numlist 1(7)29 {
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
       xtitle("Distance") ytitle("Effect SP on Employers" " ") xlabel(minmax);
    graph export "$OUT/MainEstimate_Lag`l'.eps", as(eps) replace;

    twoway line bClose closeIt if lag==`l' ||
           line lbClose closeIt if lag==`l', lpattern(dash) || 
           line ubClose closeIt if lag==`l', lpattern(dash) scheme(s1mono)
       yline(0, lpattern(dot)) legend(order(1 "Point Estimate" 2 "95% CI"))
       xtitle("Distance") ytitle("Effect SP on Employers" " ") xlabel(minmax);
    graph export "$OUT/CloseEstimate_Lag`l'.eps", as(eps) replace;
    #delimit ;
}
