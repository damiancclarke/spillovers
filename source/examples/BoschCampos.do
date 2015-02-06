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

********************************************************************************
*** (2) Merge municipal data into Bosch Campos-Vazquez final dataset
********************************************************************************
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
