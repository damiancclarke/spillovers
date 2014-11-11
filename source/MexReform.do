/* MexReform.do v0.00            damiancclarke             yyyy-mm-dd:2014-11-07
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file runs regressions of the form:

birth(ijt) = ... + alpha*Reform(ijt-1) + beta*Close(ijt-1) + XG + u(ijt)

contact: mailto:damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close
set matsize 5000

********************************************************************************
*** (1) Globals and Locals
********************************************************************************
global DAT "~/investigacion/2014/Spillovers/data"
global OUT "~/investigacion/2014/Spillovers/results/Mexico"
global LOG "~/investigacion/2014/Spillovers/log"

log using "$LOG/MexReform.txt", replace text
local FE i.year
local tr i.id#c.linear
local se cluster(id)
local cont medicalstaff MedMissing planteles* aulas* bibliotecas* totalinc /*
*/ totalout subsidies unemployment

********************************************************************************
*** (2) Setup data
********************************************************************************
use "$DAT/MunicipalBirths.dta"
*drop if year==2010
*replace Abortion=1 if stateid=="09"&year==2008

gen AgeGroup=.
replace AgeGroup=1 if Age>=15&Age<=17
replace AgeGroup=2 if Age>=18&Age<=24
replace AgeGroup=3 if Age>=25&Age<=29
replace AgeGroup=4 if Age>=30&Age<=39
drop if AgeGroup==.

collapse `cont' Abortion (sum) birth, by(stateid munid year AgeGroup)
merge m:1 stateid munid using "$DAT/DistProcessed.dta"
keep if _merge==3
drop _merge

egen id = concat(stateid munid)
bys id AgeGroup (year): gen linear=_n

********************************************************************************
*** (3) Regressions
********************************************************************************
destring id, replace
local y birth
preserve

keep if year<2008
cap drop Abortion
cap drop close*

gen Abortion=mindistDF==0&year>2005
dis "This is the placebo test:"

foreach g of numlist 1 {
	areg `y' `FE' `tr' `cont' Abortion if AgeGroup==`g', `se' absorb(id)
	outreg2 Abortion using "$OUT/PlaceboAgeGroupN`g'.tex", replace tex(pretty)
	local i=0
	local d=10
	foreach c of numlist 0(`d')50 {
		gen close`g'_`i'=mindistDF>`c'&mindistDF<=`c'+`d'&year>=2005
		tab close`g'_`i'
		areg `y' `FE' `tr' `cont' Abortion close`g'* if AgeG==`g', `se' absorb(id)
		outreg2 Abortion close* using "$OUT/PlaceboAgeGroupN`g'.tex", append /*
		*/ tex(pretty)
		local ++i
	}
	dis "Predicted effect for Abortion is:"
	dis _b[Abortion]*2*16
	dis "Predicted effect for Close is:"
	dis _b[close`g'_0]*2*4+_b[close`g'_1]*2*22
	dis "Predicted Total Effect"
	dis (_b[Abortion]*16+_b[close`g'_0]*4+_b[close`g'_1]*22)*2
}

restore

exit

foreach g of numlist 1(1)4 {
	areg `y' `FE' `tr' `cont' Abortion if AgeGroup==`g', `se' absorb(id)
	outreg2 Abortion using "$OUT/AgeGroupN`g'.tex", replace tex(pretty)
	local i=0
	local d=10
	foreach c of numlist 0(`d')50 {
		gen close`g'_`i'=mindistDF>`c'&mindistDF<=`c'+`d'&year>=2009
		tab close`g'_`i'
		areg `y' `FE' `tr' `cont' Abortion close`g'* if AgeG==`g', `se' absorb(id)
		outreg2 Abortion close* using "$OUT/AgeGroupN`g'.tex", append tex(pretty)
		local ++i
	}
	dis "Predicted effect for Abortion is:"
	dis _b[Abortion]*2*16
	dis "Predicted effect for Close is:"
	dis _b[close`g'_0]*2*4+_b[close`g'_1]*2*22
	dis "Predicted Total Effect"
	dis (_b[Abortion]*16+_b[close`g'_0]*4+_b[close`g'_1]*22)*2
}

exit
********************************************************************************
*** (4) Descriptives
********************************************************************************
gen Treat=0
replace Treat=1 if mindistDF>0&mindistDF<30
replace Treat=2 if mindistDF==0
preserve
collapse (sum) birth, by(year Treat AgeGroup)
label var birth "Number of Births"
foreach a of numlist 1(1)4 {
	twoway line birth year if Treat==0&AgeGroup==`a', yaxis(1)                ///
	  ||   line birth year if Treat==1&AgeGroup==`a', yaxis(2) lpattern(dash) ///
	  ||   line birth year if Treat==2&AgeG==`a', yaxis(2) lpattern(longdash) ///
	  xline(2007.3, lpat(dash)) xline(2008) scheme(s1mono) xtitle("Year")     ///
	  legend(label(1 "Control") label(2 "Close") label(3 "Treatment"))
	graph export "$OUT/BirthTrends`a'.eps", as(eps) replace
}

restore
