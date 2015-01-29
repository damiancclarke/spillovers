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
    [
      vce(passthru)
      areg(varname)
      graph(varname)
      *
    ]
;
#delimit cr

dis "Hello"
*=============================================================================
*=== (0) Error capture
*=============================================================================
local e111 "Error in initial model. Test this model and fix any errors"

fvexpand `varlist'
local varlist `r(varlist)'

if "`areg'"=="" {
    qui reg `varlist',
    if _rc!=0 {
        dis as error "`e111'"
        exit 111
    }
}
else if "`areg'"!="" {
    qui areg `varlist', absorb(`areg')
    if _rc!=0 {
        dis as error "`e111'"
        exit 111
    }
}


end
