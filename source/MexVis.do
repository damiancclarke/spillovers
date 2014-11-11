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
global CHI "~/investigacion/2014/Spillovers/results/Chile"

********************************************************************************
*** (2a) Use placebo, graph
********************************************************************************
insheet using "$DAT/ClosePlacebo.csv", delim(";") clear
gen distance=(_n-1)*10
sort distance

foreach n of numlist 1{
	gen up`n'=beta`n'+1.96*se`n'
	gen down`n'=beta`n'-1.96*se`n'
	twoway line beta`n' distance || line up`n' distance, lpattern(dash) ///
	  || line down`n' distance, lpattern(dash) scheme(s1mono) yline(0, lpattern(dot)) ///
	  legend(order(1 "Point Estimate" 2 "90% CI")) xtitle("Distance") ytitle("Births" " ")
	graph export "$OUT/ClosePlacebo`n'.eps", as(eps) replace
}
exit

********************************************************************************
*** (2b) Use, graph
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

********************************************************************************
*** (3) Chile
********************************************************************************
insheet using "$CHI/close1519.csv", delim(",") names clear

rename distance num
rename pillbeta distance
rename pillse beta
rename closebeta se1

gen up1=beta+1.67*se1
gen down1=beta-1.67*se1
sort distance

twoway line beta distance || line up1 distance, lpattern(dash) ///
  || line down1 distance, lpattern(dash) scheme(s1mono) ///
  yline(0, lpattern(dot)) legend(order(1 "Point Estimate" 2 "90% CI")) ///
  xtitle("Distance") ytitle("Pr(Birth)" " ") xlabel(minmax)
graph export "$CHI/CloseEstimate1.eps", as(eps) replace

insheet using "$CHI/close2034.csv", delim(",") names clear
rename pillbeta beta
rename pillse se1

gen up1=beta+1.67*se1
gen down1=beta-1.67*se1
sort distance

twoway line beta distance || line up1 distance, lpattern(dash) ///
  || line down1 distance, lpattern(dash) scheme(s1mono) ///
  yline(0, lpattern(dot)) legend(order(1 "Point Estimate" 2 "90% CI")) ///
  xtitle("Distance") ytitle("Pr(Birth)" " ") xlabel(minmax)
graph export "$CHI/CloseEstimate2.eps", as(eps) replace
