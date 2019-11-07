

************ VAR Counterfactual experiements ******************

cd "/Users/julienbernardo/Dropbox/Working/ECO466/STATA/DATA"
set more off
*log using var_counterfactual.log, replace

** Color format of graphs
set scheme s2color

** Select model type:
** 1 = VAR, 2 = VAR with US->Can constraints
local model_type = 1

** Number of lags
local lags = 1

** Forecast horizon
local FH = 8 

** Data and variables
use "dat1", clear

local y_rate_can = "rate_target_can"
local y_cpi_can  = "cpi_can"
local y_oth_can  = "gdp_can gap_int_can gap_fil_can"
local y_rate_us  = "fed_us"
local y_cpi_us   = "cpi_us" 
local y_un_us    = "un_us"
local y_oth_us   = "gdp_us"

local y_binv_can = "binv_can"
local y_export_can_us = "quart_export_can_us"
local y_import_can_us = "quart_import_can_us"
local y_ippi_can = "ippi_can"
*local y_un_can = "un_can"
local y_exr_us_can = "quart_exr_us_can"

keep if gdp_can~=.

** Creates vectors 
local y_can = "`y_rate_can' " + "`y_cpi_can' " + "`y_oth_can' " + "`y_binv_can' " + "`y_export_can_us' " + "`y_import_can_us' "  +  "`y_ippi_can' "  +  "`y_exr_us_can' "
*+  "`y_un_can' "
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
 
** Set up time series and stretch out time index
drop if year==2008
local T = _N
local T1 = `T' + 1
local TFH = `T' + `FH'
set obs `TFH'
drop time
gen time = _n
tsset time

** Counterfactual variable and values
*local yctf1 = "gap_int_can"
*replace `yctf1' = `yctf1'[_n-1] - 0.4 in `T1'/`TFH'

local yctf2 = "quart_export_can_us"
replace `yctf2' = (1 + (1 - 0.9691))*`yctf2'[_n-1] in `T1'/`TFH'

local yctf3 = "quart_import_can_us"
replace `yctf3' = (1 + (1 - 0.9848))*`yctf3'[_n-1] in `T1'/`TFH'

*local yctf4 = "ippi_can"
*replace `yctf4' = 1.02*`yctf4'[_n-1] in `T1'/`TFH'

*local yctf5 = "quart_exr_us_can"
*replace `yctf5' = 1.01672*`yctf5'[_n-1] in `T1'/`TFH'

*local yctf6 = "un_can"
*replace `yctf6' = 1.02438*`yctf6'[_n-1] in `T1'/`TFH'

local yctf7 = "rate_target_can"
replace `yctf7' = 1.75 in `T1'/`TFH'



** Differences of counterfactual variables
*gen `yctf1'_ctf = `yctf1' in `T1'/`TFH'
*gen D_`yctf1'_ctf = `yctf1' - `yctf1'[_n-1] in `T1'/`TFH'

gen `yctf2'_ctf = `yctf2' in `T1'/`TFH'
gen D_`yctf2'_ctf = `yctf2' - `yctf2'[_n-1] in `T1'/`TFH'

gen `yctf3'_ctf = `yctf3' in `T1'/`TFH'
gen D_`yctf3'_ctf = `yctf3' - `yctf3'[_n-1] in `T1'/`TFH'

*gen `yctf4'_ctf = `yctf4' in `T1'/`TFH'
*gen D_`yctf4'_ctf = `yctf4' - `yctf4'[_n-1] in `T1'/`TFH'

*gen `yctf5'_ctf = `yctf5' in `T1'/`TFH'
*gen D_`yctf5'_ctf = `yctf5' - `yctf5'[_n-1] in `T1'/`TFH'

gen `yctf7'_ctf = `yctf7' in `T1'/`TFH'
gen D_`yctf7'_ctf = `yctf7' - `yctf7'[_n-1] in `T1'/`TFH'

** Create variables for counterfactual and regular confidence intervals
foreach y in `y_all' {
   gen `y'_LB = .
   quietly replace `y'_LB = `y' in `T'/`T'
   gen `y'_UB = .   
   quietly replace `y'_UB = `y' in `T'/`T'

   gen af_`y' = .   
   quietly replace af_`y' = `y' in `T'/`T'      
   gen af_`y'_LB = .
   quietly replace af_`y'_LB = `y' in `T'/`T'
   gen af_`y'_UB = .   
   quietly replace af_`y'_UB = `y' in `T'/`T'
}

** Counterfactual experiment
  
local FH_1 = `FH'-1
forvalues i=1/`FH' {

   ** Forecast target time period
   local Ti = `T'+`i'
   
   ** Run VAR
   run "/Users/julienbernardo/Dropbox/Working/ECO466/Presentation/Do_files/var_model_setup.do"
   quietly var_model `model_type' `lags' _N+1 "`D_y_can'" "`D_y_us'"  

   ** Forecast
   fcast compute f_, step(1)	   
  
   ** Actual forecast with real data
   if `i' == 1 {       
      fcast compute af_, step(`FH')
      foreach y in `y_all' {
	     quietly replace af_`y'_LB = af_D_`y'_LB in `Ti'/l
	     quietly replace af_`y'_UB = af_D_`y'_UB in `Ti'/l
         quietly replace af_`y' = af_D_`y' in `Ti'/l      	  	  
	  }
   }

   ** Forecast and confidence intervals 
   foreach y in `y_all' {
	  quietly replace `y'_LB = `y'_LB[_n-1] + f_D_`y'_LB in `Ti'/`Ti'
	  quietly replace `y'_UB = `y'_UB[_n-1] + f_D_`y'_UB in `Ti'/`Ti'
      quietly replace `y' = `y'[_n-1] + f_D_`y' in `Ti'/`Ti'      	  
      quietly replace D_`y' = f_D_`y' in `Ti'/`Ti'      	  
   }
   drop f_*   

   ** Set counterfactual values 
	*quietly replace D_`yctf1' = D_`yctf1'_ctf in `Ti'/`Ti'
   *quietly replace `yctf1' = `yctf1'[_n-1] + D_`yctf1'_ctf in `Ti'/`Ti'
   
	quietly replace D_`yctf2' = D_`yctf2'_ctf in `Ti'/`Ti'
   quietly replace `yctf2' = `yctf2'[_n-1] + D_`yctf2'_ctf in `Ti'/`Ti'
   
	quietly replace D_`yctf3' = D_`yctf3'_ctf in `Ti'/`Ti'
   quietly replace `yctf3' = `yctf3'[_n-1] + D_`yctf3'_ctf in `Ti'/`Ti' 
   
	*quietly replace D_`yctf4' = D_`yctf4'_ctf in `Ti'/`Ti'
   *quietly replace `yctf4' = `yctf4'[_n-1] + D_`yctf4'_ctf in `Ti'/`Ti'
   
  	*quietly replace D_`yctf5' = D_`yctf5'_ctf in `Ti'/`Ti'
   *quietly replace `yctf5' = `yctf5'[_n-1] + D_`yctf5'_ctf in `Ti'/`Ti'
   
   	quietly replace D_`yctf7' = D_`yctf7'_ctf in `Ti'/`Ti'
   quietly replace `yctf7' = `yctf7'[_n-1] + D_`yctf7'_ctf in `Ti'/`Ti'
}

** Cumulative sum of forecasted differences
foreach y in `y_all' {  
   quietly replace af_`y'_LB = sum(af_`y'_LB) in `T'/l
   quietly replace af_`y'_UB = sum(af_`y'_UB) in `T'/l
   quietly replace af_`y' = sum(af_`y') in `T'/l   
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

gen fraction = af_`y_rate_can' - floor(af_`y_rate_can') if year==.
replace fraction = 0 if fraction < 0.125 & year==.
replace fraction = 0.25 if fraction >= 0.125 & fraction < 0.375 & year==.
replace fraction = 0.5 if fraction >= 0.375 & fraction < 0.625 & year==.
replace fraction = 0.75 if fraction >= 0.625 & fraction < 0.875 & year==.
replace fraction = 1 if fraction >= 0.875 & year==.
replace af_`y_rate_can' = floor(af_`y_rate_can') + fraction if year==.
drop fraction

gen fraction = `y_rate_us' - floor(`y_rate_us') if year==.
replace fraction = 0 if fraction < 0.125 & year==.
replace fraction = 0.25 if fraction >= 0.125 & fraction < 0.375 & year==.
replace fraction = 0.5 if fraction >= 0.375 & fraction < 0.625 & year==.
replace fraction = 0.75 if fraction >= 0.625 & fraction < 0.875 & year==.
replace fraction = 1 if fraction >= 0.875 & year==.
replace `y_rate_us' = floor(`y_rate_us') + fraction if year==.
drop fraction

gen fraction = af_`y_rate_us' - floor(af_`y_rate_us') if year==.
replace fraction = 0 if fraction < 0.125 & year==.
replace fraction = 0.25 if fraction >= 0.125 & fraction < 0.375 & year==.
replace fraction = 0.5 if fraction >= 0.375 & fraction < 0.625 & year==.
replace fraction = 0.75 if fraction >= 0.625 & fraction < 0.875 & year==.
replace fraction = 1 if fraction >= 0.875 & year==.
replace af_`y_rate_us' = floor(af_`y_rate_us') + fraction if year==.
drop fraction

** Delete confidence intervals for counterfactual variable
*quietly replace `yctf1'_LB = .
*quietly replace `yctf1'_UB = .

quietly replace `yctf2'_LB = .
quietly replace `yctf2'_UB = .

quietly replace `yctf3'_LB = .
quietly replace `yctf3'_UB = .

*quietly replace `yctf4'_LB = .
*quietly replace `yctf4'_UB = .

*quietly replace `yctf5'_LB = .
*quietly replace `yctf5'_UB = .

quietly replace `yctf7'_LB = .
quietly replace `yctf7'_UB = .

** Create time index for forecasts
drop time
gen time=yq(year,quarter)
replace time = time[_n-1] + 1 if time == .
order time
tsset time
format time %tq

** Graphs of Counterfactuals vs Actual Forecasts
gen f_time = time if year==.
disp `T1'
format f_time %tq

** without confidence intervals


keep if year== .
foreach y in `y_all' {
   twoway (scatter af_`y' f_time, connect(line)) ///
   || (scatter `y' f_time, mfcolor(none) connect(line)) ///
   || (scatter `y'_UB f_time, msymbol(none) connect(line) lpattern(dash) lcolor(gray)) ///
   || (scatter `y'_LB f_time, msymbol(none) connect(line) lpattern(dash) lcolor(gray)) ///
   ,  legend(lab(1 "Forecast") lab(2 "Counterfactual") order(1 2)) name(`y', replace) 
   *graph export `y'.emf, replace
}
exit


** with confidence intervals
keep if f_time ~= .
foreach y in `y_all' {
   twoway (rarea af_`y'_LB af_`y'_UB f_time, color(gs15) title(`y') mlabel(`y')) /// 
   || (scatter af_`y' f_time, connect(line)) ///
   || (scatter `y' f_time, mfcolor(none) connect(line)) ///
   || (scatter `y'_UB f_time, msymbol(none) connect(line) lpattern(dash) lcolor(gray)) ///
   || (scatter `y'_LB f_time, msymbol(none) connect(line) lpattern(dash) lcolor(gray)) ///
   ,  legend(lab(2 "Forecast") lab(3 "Counterfactual") order(2 3)) name(`y', replace) 
   *graph export `y'.emf, replace
}


*log close
lo
