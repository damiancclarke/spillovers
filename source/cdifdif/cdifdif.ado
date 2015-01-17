*! cdifdif: Difference-in-differences in the presence of local spillovers
*! Version 1.0.0 noviembre 8, 2014 @ 09:35:32
*! Author: Damian C. Clarke
*! Department of Economics
*! The University of Oxford
*! damian.clarke@economics.ox.ac.uk

cap program drop cdifdif
program cdifdif, eclass
vers 10.0

#delimit ;
syntax varlist(min=2) [if] [in] [pweight fweight aweight iweight],
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

*=============================================================================
*=== (0) Error capture
*=============================================================================


end
