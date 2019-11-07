
************ VAR forecast ***************************

** Directory path
cd "/Users/julienbernardo/Dropbox/Working/ECO466/STATA/DATA"
set more off
*log using var_forecast.log, replace

** Color format of graphs
set scheme s2color

** Select model type:
** 1 = VAR, 2 = VAR with US->Can constraints
local model_type = 2

** Number of lags
local lags = 1

** Forecast horizon
local FH = 8

** Data and variables
use "dat1.dta", clear
drop if gdp_can==.
*drop if year == 2019
*drop if year == 2018 & quarter == 4
*drop if year == 2018 & quarter == 3

local y_rate_can = "rate_target_can"
local y_cpi_can  = "cpi_can"
local y_oth_can  = "gdp_can gap_int_can gap_fil_can"
local y_rate_us  = "fed_us"
local y_cpi_us   = "cpi_us" 
local y_un_us    = "un_us"
local y_oth_us   = "gdp_us gap_us"

local y_binv_can = "binv_can"
local y_export_can_us = "quart_export_can_us"
local y_import_can_us = "quart_import_can_us"
local y_ippi_can = "ippi_can"
local y_un_can = "un_can"
local y_exr_us_can = "quart_exr_us_can"

** Creates vectors (add space like "`variable' ")
local y_can = "`y_rate_can' " + "`y_cpi_can' " + "`y_oth_can' " + "`y_binv_can' "  +  "`y_export_can_us' "  +  "`y_import_can_us' "  +  "`y_ippi_can' "  +  "`y_un_can' "  +  "`y_exr_us_can' " 

local y_us  = "`y_rate_us' " + "`y_cpi_us' " + "`y_un_us' " + "`y_oth_us'"

local y_all = "`y_can' " + "`y_us'"

** Differenced variables
local D_y_can = ""
foreach y in `y_can' {
   local D_y_can = "`D_y_can'" + " D_`y'"
}   
local D_y_us = ""
foreach y in `y_us' {
   local D_y_us = "`D_y_us'" + " D_`y'"
}   
local D_y_all = "`D_y_can' " + "`D_y_us'"
 
** Set up time series (drop the extreme outlier year 2008)
drop time
drop if year==2008
gen time = _n
tsset time

** Estimate a VAR model
run "/Users/julienbernardo/Dropbox/Working/ECO466/Presentation/Do_files/var_model_setup.do"
var_model `model_type' `lags' _N+1 "`D_y_can'" "`D_y_us'"

*** Verify lag length, adjust above (works only with model_type=1)
*varsoc, maxlag(5)
	   
** Check the stability of VAR estimates
varstable

** Granger causality test
vargranger

** Forecast
local T  = _N
local T1 = _N+1
fcast compute f_, step(`FH')

** Create confidence interval variables
foreach y in `y_all' {
  quietly gen `y'_LB = `y' in `T'/`T'
  quietly gen `y'_UB = `y' in `T'/`T'
}  

** Sum forecasted differences into level forecasts
foreach y in `y_all' {  
  quietly replace `y' = f_D_`y' in `T1'/l
  quietly replace `y'_LB = f_D_`y'_LB in `T1'/l
  quietly replace `y'_UB = f_D_`y'_UB in `T1'/l  
  quietly replace `y' = sum(`y') in `T'/l
  quietly replace `y'_LB = sum(`y'_LB) in `T'/l
  quietly replace `y'_UB = sum(`y'_UB) in `T'/l
}

** Round interest rate forecasts to 0.25 points
gen fraction = `y_rate_can' - floor(`y_rate_can') if year==.
replace fraction = 0 if fraction < 0.125 & year==.
replace fraction = 0.25 if fraction >= 0.125 & fraction < 0.375 & year==.
replace fraction = 0.5 if fraction >= 0.375 & fraction < 0.625 & year==.
replace fraction = 0.75 if fraction >= 0.625 & fraction < 0.875 & year==.
replace fraction = 1 if fraction >= 0.875 & year==.
replace `y_rate_can' = floor(`y_rate_can') + fraction if year==.

drop fraction
gen fraction = `y_rate_us' - floor(`y_rate_us') if year==.
replace fraction = 0 if fraction < 0.125 & year==.
replace fraction = 0.25 if fraction >= 0.125 & fraction < 0.375 & year==.
replace fraction = 0.5 if fraction >= 0.375 & fraction < 0.625 & year==.
replace fraction = 0.75 if fraction >= 0.625 & fraction < 0.875 & year==.
replace fraction = 1 if fraction >= 0.875 & year==.
replace `y_rate_us' = floor(`y_rate_us') + fraction if year==.

** Create time index for forecast
drop time
gen time=yq(year,quarter)
replace time = time[_n-1] + 1 if time == .
order time
tsset time
format time %tq

** Forecast graphs
** without confidence intervals
foreach y in `y_all' {
   twoway (scatter `y' time in `T1'/l, connect(line)) ///
   ,  legend(off) name(`y', replace) 
   *graph export `y'.emf, replace
}


/*
** with confidence intervals
foreach y in `y_all' {
   twoway (rarea `y'_LB `y'_UB time in `T1'/l, color(gs15) title(`y')) /// 
   || (scatter `y' time in `T1'/l, connect(line)) ///
   ,  legend(off) name(`y', replace) 
   *graph export `y'.emf, replace
}
*/

*log close
