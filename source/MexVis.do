/* MexVis v0.00                  damiancclarke             yyyy-mm-dd:2014-11-09
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
*/

vers 11
clear all
set more off
cap log close

********************************************************************************
*** (1) Globals and Locals
********************************************************************************
global DAT "~/investigacion/2014/Spillovers/results/Mexico/910results"
global OUT "~/investigacion/2014/Spillovers/results/Mexico"
global LOG "~/investigacion/2014/Spillovers/log"

********************************************************************************
*** (2) Use, graph
********************************************************************************
insheet using "$DAT/Main.csv", delim(";")
gen distance=(_n-1)*10
gen up1=beta1+1.96*se1
gen down1=beta1-1.96*se1
sort distance

keep if distance<=40

foreach num of numlist 1(1)4 {
	twoway line beta`num' distance, scheme(s1mono)
	graph export "$OUT/MainEstimate`num'.eps", as(eps) replace
}

insheet using "$DAT/Close.csv", delim(";") clear
gen distance=(_n-1)*10
sort distance

foreach n of numlist 1(1)4{
	gen up`n'=beta`n'+1.67*se`n'
	gen down`n'=beta`n'-1.67*se`n'
	twoway line beta`n' distance || line up`n' distance, lpattern(dash) ///
	  || line down`n' distance, lpattern(dash) scheme(s1mono) yline(0, lpattern(dot)) ///
	  legend(order(1 "Point Estimate" 2 "90% CI")) xtitle("Distance") ytitle("Births" " ")
	graph export "$OUT/CloseEstimate`n'.eps", as(eps) replace
}
