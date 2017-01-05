/* NVSSprep.do v0.0.0              DCC/CAM                 yyyy-mm-dd:2016-12-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

 This file takes raw NVSS data and merges to create consistent county FIPS. This
requires a crosswalk for each year, given that NVSS (NCHS) county codes change
slightly each year.  These crosswalks were constructed by DCC with edits by CAM
using the original NCHS source manuals.
*/
vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals/locals
********************************************************************************
global MAIN "~/investigacion/2014/Spillovers/"
global NAT  "~/database/NVSS/Births/dta"

global LOG "$MAIN/log"
global DAT "$MAIN/ELA"
global COD "$MAIN/source/ELA"

log using "$LOG/log_nacimientos_largo.txt", text replace
local outfiles

********************************************************************************
*** (2) Hacer un loop para todos los años, y usar condiciones para tener
***     un codigo distinto cuando hayan cambios en las variables entre años
********************************************************************************
local year_ini = 1968
local year_end = 1990

foreach y of num `year_ini'/`year_end' {
    display "PROCESSING YEAR `y'"

    *1. FIX NBER DATA
    use "$DAT/nchs2fips_county1990_nber.dta", clear
    quietly: do "$COD/fix_nber_data_all_years.do"
    if `y' <= 1981 {
        quietly: do "$COD/fix_nber_data_some_years.do"
    }
    quietly: destring stateoc countyoc, replace
    tempfile crosswalk
    save `crosswalk'

    *2. MERGE DATA AND ANALYZE MERGE == 1
    use "$DAT2/natl`y'.dta", clear

    if `y'<1972 gen recwt=2
    
    generate stateoc = substr(cntynat, 1, 2)
    generate countyoc = substr(cntynat, 3, .)
    
    destring stateoc countyoc, replace
    merge n:1 stateoc countyoc using `crosswalk', keepusing(fipsco countyname)
    
    drop if _merge == 2
    
    rename fipsco county
    generate str2 state=substr(county, 1, 2)
    
    rename dbirwt birthweight
    rename dmage mothersage
    
    generate year=`y'
    generate numbirths=1
    generate underweight=0
    replace underweight=1 if birthweight<=2500	
    replace mothersage=. if mothersage==99 | mothersage<=12
    replace birthweight=. if birthweight==9999
    drop if county=="."
    drop if state=="."
    
    keep numbirths birthweight mothersage underweight county state year recwt
    generate underw_ratio=100*underweight/numbirths
    label var underw_ratio "Underweighted child"
    
    tempfile anho`y'
    save `anho`y''
    local outfiles `outfiles' `anho`y''
}

********************************************************************************
*** (3) Hacer un append de todos los anios juntos
********************************************************************************
clear
append using `outfiles'

********************************************************************************
*** (4) Formatear y guardar
********************************************************************************
label var numbirths   "Number of births"
label var birthweight "Birthweight of child"
label var mothersage  "Mother's age"
label var underweight "Underweighted child"
label var county      "County FIPS code"
label var state       "State FIPS code"
label var year        "Year of birth"

/*dat label "All births 1968-1990 NVSS"*/
order year state county numbirths mothersage birthweight underweight
saveold "$OUT/births1968-1990", replace
log close
