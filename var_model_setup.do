
** VAR model specifications **
capture program drop var_model
 program define var_model
 args model_type lags T D_y_can D_y_us
	  
*********** VAR ************************************

if `model_type' == 1 {
  
      var `D_y_can' `D_y_us' if _n<`T', lags(1/`lags') noconstant  
}

*********** VAR with US->Can constraints ***********

if `model_type' == 2 {

   local ct = 0
   foreach y_us in `D_y_us' {
      foreach y_can in `D_y_can' {
         forvalues i=1/`lags' {
	        local ct = `ct' + 1
		    constraint `ct' [`y_us']L`i'.`y_can' = 0
		 }
	  }
   }

   var `D_y_can' `D_y_us' if _n<`T', lags(1/`lags') noconstant constraints(1/`ct')

   disp `ct'
   
}

end
