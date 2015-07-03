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
global BIR "~/investigacion/2014/Spillovers/data"
global DAT "~/investigacion/2014/Spillovers/results/Mexico/910results"
global OUT "~/investigacion/2014/Spillovers/results/Mexico"
global LOG "~/investigacion/2014/Spillovers/log"
global CHI "~/investigacion/2014/Spillovers/results/Chile"


********************************************************************************
*** (2) Descriptives (age)
********************************************************************************
use "$BIR/MunicipalBirths"
gen AgeGroup2 = .
replace AgeGroup2 = 1 if Age>=11&Age<=15
replace AgeGroup2 = 2 if Age>=16&Age<=20
replace AgeGroup2 = 3 if Age>=21&Age<=25
replace AgeGroup2 = 4 if Age>=26&Age<=30
replace AgeGroup2 = 5 if Age>=31&Age<=35
replace AgeGroup2 = 6 if Age>=36&Age<=40
replace AgeGroup2 = 7 if Age>=41&Age<=45
replace AgeGroup2 = 8 if Age>=46&Age<=50

collapse (sum) birth, by(AgeGroup2)
keep if AgeGroup!=.
egen totalbirth = sum(birth)
replace birth = birth/totalbirth
gen abort = .
local nums 0.014 0.227 0.34 0.20 0.124 0.07 0.019 0.001
tokenize `nums'
foreach a of numlist 1(1)8 {
    replace abort = ``a'' if AgeGroup2==`a'
}
lab def ages 1 "11-15" 2 "16-20" 3 "21-25" 4 "26-30" 5 "31-35" 6 "36-40" /*
*/ 7 "41-45" 8 "46-50"
lab val AgeGroup2 ages

#delimit ;
twoway bar  abort Age, fcolor(white) lcolor(gs0) ||
       line birth Age, lcolor(gs0) scheme(s1mono)
       xlabel(1(1)8, valuelabels angle(50))
       xtitle(" " "Mother's Age") ytitle("Proportion") 
       legend(label(1 "Proportion of Abortions") label(2 "Proportion of Births"));
graph export "$OUT/birthDescriptives.eps", replace as(eps);
#delimit cr
exit
********************************************************************************
*** (3a) Use placebo, graph
********************************************************************************
insheet using "$DAT/ClosePlacebo.csv", delim(";") clear
gen distance=(_n-1)*10
sort distance

foreach n of numlist 1{
	gen up`n'=beta`n'+1.96*se`n'
	gen down`n'=beta`n'-1.96*se`n'
  #delimit ;
	twoway line beta`n' distance ||
         line up`n' distance, lpattern(dash ||
	       line down`n' distance, lpattern(dash)
         scheme(s1mono) yline(0, lpattern(dot)) xtitle("Distance") 
         legend(order(1 "Point Estimate" 2 "90% CI")) ytitle("Births" " ");
	graph export "$OUT/ClosePlacebo`n'.eps", as(eps) replace;
  #delimit cr
}


********************************************************************************
*** (3b) Use, graph
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
*** (4) Chile
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
