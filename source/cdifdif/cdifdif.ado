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
local max `=`r(max)''

if `max'<`bandwidth' {
    dis as error "`bw'" 
    dis as error "Choose a smaller bandwidth and re-estimate"
    exit 200
}


*=============================================================================
*=== (1) Iterative addition of spillover tests
*=============================================================================
local cond 1
local j=0
local itvars

while `cond'==1 {
    local d1 = `j'*`bandwidth'
    local d2 = (`j'+1)*`bandwidth'
    local vn = `=`d2''
 
    tempvar close`vn'
    gen `close`vn''=`close'>`d1'&`close'<=`d2'&`timevar'>=`tyear'
    

    reg `varlist' `itvars' `close`vn'', `vce'   
    local itvars `itvars' `close`vn''

    local ++j
    if `j'>5 local cond=0
}
    
end
