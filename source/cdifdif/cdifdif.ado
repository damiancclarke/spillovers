*! cdifdif: Difference-in-differences in the presence of local spillovers
*! Version 1.0.0 noviembre 8, 2014 @ 09:35:32
*! Author: Damian C. Clarke
*! Department of Economics
*! The University of Oxford
*! damian.clarke@economics.ox.ac.uk

cap program drop cdifdif
program cdifdif, eclass
vers 11.0

#delimit ;
  syntax varlist(min=2 fv ts) [if] [in] [pweight fweight aweight iweight],
    close(varname)
    BANDWidth(real)
    treatvar(varname)
    timevar(varname)
    tyear(real)
    [
      vce(passthru)
      areg(varname)
      graph(varname)
      *
    ]
;
#delimit cr

*=============================================================================
*=== (0) Error capture
*=============================================================================
local e111 "Error in initial model. Test this model and fix any errors"
local bw "Maximum value of close variable is `max' but bandwidth is `bandwidth'"

fvexpand `varlist'
local varlist `r(varlist)'

if "`areg'"=="" {
    qui reg `varlist', `vce'
    if _rc!=0 {
        dis as error "`e111'"
        exit 111
    }
}

else if "`areg'"!="" {
    qui areg `varlist', absorb(`areg') `vce'
    if _rc!=0 {
        dis as error "`e111'"
        exit 111
    }
}

qui sum `close'
local max    `=`r(max)''
local maxbin `=ceil(`r(max)'/`bandwidth')'

if `max'<`bandwidth' {
    dis as error "`bw'" 
    dis as error "Choose a smaller bandwidth and re-estimate"
    exit 200
}


*=============================================================================
*=== (1) Iterative addition of spillover tests
*=============================================================================
local tstat = 200
local pval  = 0.01
local j     = 1
local itvars

mat point = J(`maxbin',3,.)


dis "Distance ...  Coefficient on Close ... Treatment"
while `tstat'>1.96|`pval'<0.1 {
    local d1 = (`j'-1)*`bandwidth'
    local d2 = `j'*`bandwidth'
    local vn = `=`d2''
 
    tempvar close`vn'
    gen `close`vn''=`close'>`d1'&`close'<=`d2'&`timevar'>=`tyear'
    qui reg `varlist' `itvars' `close`vn'', `vce'   
    
    dis "`d1'-`d2' ..." _b[`close`vn''] " ..." _b[`treatvar']

    qui sureg (`varlist' `itvars' `close`vn'') (e2:`varlist' `itvars')
    test `treatvar'=[e2]`treatvar'
    local pval = `r(p)'
    
    mat point[`j',1]=_b[`treatvar']-1.96*_se[`treatvar']
    mat point[`j',2]=_b[`treatvar']
    mat point[`j',3]=_b[`treatvar']+1.96*_se[`treatvar']

    local tstat = abs(_b[`close`vn'']/_se[`close`vn''])
    
    local itvars `itvars' `close`vn''
    local ++j
}

mat list point
end
