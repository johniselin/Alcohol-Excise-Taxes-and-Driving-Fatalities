
/***********************************************************************
Author: Robert McClelland and John Iselin
Date: Spring 2017 (Updated January 2019)

Illinois Liquor tax increase and alcohol-related accidents. 

Part 2: Running the Model and Placebo Tests


We are examining the effect of a 1999 and 2009 Alcohol Tax Increase
In Illinois. This do-file takes a constructed dataset and runs 
through a set of pre- and post-estimation tests and models the
effects of the tax change using the synthetic control method as 
described in Abadie, Diamond, and Hainmuller (2010).

This do-file is the second of three. This file takes the datasets created in 
synth_preestimation and runs through our model. The model is run twice for 
each version of the data (described below) - once with all pre-treatment
dependent variable lags, and once with our selected explanatory variables plus 
lags selected based on our preestimation tests. This file also runs the versions 
through placebo tests, which run each potential donor state  through the same 
model IL was run through, to determine if the IL result is different from that 
seen in other states.

Please refer to the READ ME file before running this do-file to be sure that
folders and datasets are correctly organized. 

For the 2009 IL tax change, there will be two versions of the model, one for 
each dependent variable: the share of total accidents with BAC values over 0.08 
(share_alcohol) and the total number of accidents with BAC values over 0.08 
divided by the number of drivers (drivers_alcohol). For each of these dependent 
variables, we run the model over our set of donor states, which is all 50 states 
plus DC minus states with large liquor tax changes, states with liquor control 
as opposed to or in addition to taxes, and Alaska, DC, and Hawaii. As a 
sensitivity analysis we also will re-run the models over a second set of donor 
states where we add back in states with liquor control boards.

Make sure that the synth program in installed:

ssc install synth

Note: While the tax changes occured in 1999 and 2009, since the first year 
when the tax change were fully in effect fell in 2000 and 2010, those are 
the first years of the "treatment".

Make sure that the filepaths are created as outlined in the READ-ME file by 
running synth_setup.do.

**************************************************************************/


*** Set-Up ***
capture log close
clear matrix
clear all
set more off

*set maxvar 10000

** MAC vs PC Filepaths
if regexm(c(os),"Mac") == 1 local mypath = "/Users/johniselin/Desktop/Desktop - John’s MacBook Pro/TPC/Illinois Alcohol Taxes and Drunk Driving/Results/Synth Run 01.16.2019/"
else if regexm(c(os),"Windows") == 1 local mypath = "...\"

if regexm(c(os),"Mac") == 1 {
	local mypath_logs = "`mypath'/Logs/"
	local mypath_data = "`mypath'/Data/"
	
}
else if regexm(c(os),"Windows") == 1 {
	local mypath_logs = "`mypath'\Logs\"
	local mypath_data = "`mypath'\Data\"
	}

cd "`mypath'"
log using "`mypath_logs'synth_alcohol_model_2010", replace

*** Loop over the following to create V1 - V4:
*** V1: Share of Accidents Due to Alcohol, No Controls (share, narrow)
*** V3: Alcohol-Related Accidents per Driver, No Controls (drivers, narrow)


local depvar share drivers
local sizevar narrow 
foreach a of local depvar {

	foreach b of local sizevar {	
		if regexm(c(os),"Mac") == 1 {
			local mypath_`a'_`b' = "`mypath'IL 2010 - `a' - `b'/"
	
	}
	else if regexm(c(os),"Windows") == 1 local mypath_`a'_`b' = "`mypath'IL 2010 - `a' - `b'\"
	

}
}	

* List of states included in donor pool (..._states_1 is just the first state)
local narrow_states 4 5 8 13 16 18 20 21 22 24 25 27 29 31 38 45 46 47 48 55 36 9 40 12 19
local narrow_states_1 4

* List of explanatory variables
local vars_share youngshare oldshare liverdeaths_percap
local vars_drivers pipercap_deflated gasolinetax_deflated unempl youngshare oldshare liverdeaths_percap 


foreach a of local depvar {

	foreach b of local sizevar {


cd "`mypath_`a'_`b''"

local vars1 `vars_`a'' `a'_alcohol(1992) `a'_alcohol(1997) `a'_alcohol(2008)
local vars2 `vars_`a'' 
local vars_labels `vars_`a'' `a'_alcohol_1992 `a'_alcohol_1997 `a'_alcohol_2008
di "`vars1'"
di "`vars2'"
di "`vars_labels'"
local states ``b'_states'
di "`states'"
local states_1 ``b'_states_1'
di "`states_1'"

use alcohol_`a'_`b'
tsset state year

* Note: Drop US First
drop if state == 0


*** 1. Run Model with all outcome lags

synth `a'_alcohol 															///
														 `a'_alcohol(1992) ///
	`a'_alcohol(1993) `a'_alcohol(1994) `a'_alcohol(1995) `a'_alcohol(1996) ///
	`a'_alcohol(1997) `a'_alcohol(1998) `a'_alcohol(1999) `a'_alcohol(2000) ///
	`a'_alcohol(2001) `a'_alcohol(2002) `a'_alcohol(2003) `a'_alcohol(2004) ///
	`a'_alcohol(2005) `a'_alcohol(2006) `a'_alcohol(2007) `a'_alcohol(2008), ///
	trunit(17) trperiod(2010) xperiod(1992(1)2008) mspeperiod(1992(1)2008) ///
	resultsperiod(1992(1)2015) keep(all_lags) replace
clear

use all_lags
export excel using "`mypath'Analysis_`a'_`b'_2010.xlsx", sheet("All Lags - Data") sheetmodify  firstrow(var)
drop if _time==.
gen IL_diff=_Y_synthetic-_Y_treated
drop _Co_Number _W_Weight _Y_treated _Y_synthetic
save IL_alllags_short, replace
clear

*** 2. Run Model with Explanatory variables + appropriate outcome lags
	
use alcohol_`a'_`b'
tsset state year

* Note: Drop US First
drop if state == 0

synth `a'_alcohol `vars1', ///
	trunit(17) trperiod(2010) xperiod(1992(1)2008) mspeperiod(1992(1)2008) ///
	resultsperiod(1992(1)2015) keep(original) replace
ereturn list
matrix list e(V_matrix)
matrix a = e(V_matrix)
clear

svmat double a, names(weights)
local y = 1
foreach z of local vars_labels {
	egen x = total (weights`y')
	replace weights`y' = x
	drop x
	rename weights`y' `z'
	local y = `y' + 1
	}
	
duplicates drop
save original_var_weight, replace
export excel using "`mypath'Analysis_`a'_`b'_2010.xlsx", sheet("Variable Weights - Data") sheetmodify  firstrow(var)
clear

use original
export excel using "`mypath'Analysis_`a'_`b'_2010.xlsx", sheet("Original - Data") sheetmodify  firstrow(var)
drop if _time==.
gen IL_diff=_Y_synthetic-_Y_treated
drop _Co_Number _W_Weight _Y_treated _Y_synthetic
save IL_short, replace
clear
use original
drop if _Co_Number==.
keep _Co_Number _W_Weight
save original_weight, replace
clear


*** 3. Placebo Tests (In-Time and In-Place)

use alcohol_`a'_`b'
tsset state year


*Exclude Illinois and the US*
drop if state==17
drop if state==0
*Placebo states*
tempname placebo_mat		

****  In-space placebo test  ****

** Original Model 
cd "`mypath_`a'_`b''placebo tests"
local names
foreach x of local states {
	synth `a'_alcohol `vars1', ///
	trunit(`x') trperiod(2010) xperiod(1992(1)2008) mspeperiod(1992(1)2008) ///
	resultsperiod(1992(1)2015) keep(`x'placebo) replace

    matrix `placebo_mat' = nullmat(`placebo_mat') \ e(RMSPE)
    local names `"`names' `"`x'"'"'
}
mat colnames `placebo_mat' = "RMSPE"
mat rownames `placebo_mat' = `names'
matlist `placebo_mat' , row("Treated Unit")

clear
foreach x of local states {
	use `x'placebo
	drop if _time==.
	gen synth`x'_diff=_Y_synthetic-_Y_treated
	drop _Co_Number _W_Weight _Y_treated _Y_synthetic
	save `x'placebo_short, replace
}
clear

use `states_1'placebo_short

foreach x of local states {
	merge 1:1 _time using `x'placebo_short, keepusing(synth`x'_diff)
	drop _merge
}
cd "`mypath_`a'_`b''"
merge 1:1 _time using IL_short, keepusing(IL_diff)
drop _merge


order _time, first
save placebo_data, replace
export excel using "`mypath'Analysis_`a'_`b'_2010.xlsx", sheet("Placebo - Data") sheetmodify  firstrow(var)
clear


** All Lags Model

use alcohol_`a'_`b'
tsset state year
	

*Exclude Illinois and the US*
drop if state==17
drop if state==0
*Placebo states*
tempname placebo_mat		


cd "`mypath_`a'_`b''placebo tests"


local names
foreach x of local states {
	synth `a'_alcohol 														///
																			///
														  `a'_alcohol(1992) ///
	`a'_alcohol(1993) `a'_alcohol(1994) `a'_alcohol(1995) `a'_alcohol(1996) ///
	`a'_alcohol(1997) `a'_alcohol(1998) `a'_alcohol(1999) `a'_alcohol(2000) ///
	`a'_alcohol(2001) `a'_alcohol(2002) `a'_alcohol(2003) `a'_alcohol(2004) ///
	`a'_alcohol(2005) `a'_alcohol(2006) `a'_alcohol(2007) `a'_alcohol(2008), ///
	trunit(`x') trperiod(2010) xperiod(1992(1)2008) mspeperiod(1992(1)2008) ///
	resultsperiod(1992(1)2015) keep(`x'placebo_lags) replace

    matrix `placebo_mat' = nullmat(`placebo_mat') \ e(RMSPE)
    local names `"`names' `"`x'"'"'
}
mat colnames `placebo_mat' = "RMSPE"
mat rownames `placebo_mat' = `names'
matlist `placebo_mat' , row("Treated Unit")

clear

foreach x of local states {
	use `x'placebo_lags
	drop if _time==.
	gen synth`x'_diff=_Y_synthetic-_Y_treated
	drop _Co_Number _W_Weight _Y_treated _Y_synthetic
	save `x'placebo_lags_short, replace
}
clear

use `states_1'placebo_lags_short

foreach x of local states {
	merge 1:1 _time using `x'placebo_lags_short, keepusing(synth`x'_diff)
	drop _merge
}
cd "`mypath_`a'_`b''"
merge 1:1 _time using IL_alllags_short, keepusing(IL_diff)
drop _merge
order _time, first
save placebo_lags_data, replace
export excel using "`mypath'Analysis_`a'_`b'_2010.xlsx", sheet("Placebo Lags - Data") sheetmodify  firstrow(var)
clear




**** In-Time Placebo Test ****

cd "`mypath_`a'_`b''"

use alcohol_`a'_`b'
tsset state year
drop if state==0

cd "`mypath_`a'_`b''placebo tests"

****  In-time placebo test: 2005 intervention, end period at 2015, all outcome lags, no other predictors  ****
synth `a'_alcohol   								      `a'_alcohol(1992) ///
	`a'_alcohol(1993) `a'_alcohol(1994) `a'_alcohol(1995) `a'_alcohol(1996) ///
	`a'_alcohol(1997) `a'_alcohol(1998) `a'_alcohol(1999) `a'_alcohol(2000) ///
	`a'_alcohol(2001) `a'_alcohol(2002) `a'_alcohol(2003) `a'_alcohol(2004), ///
	trunit(17) trperiod(2005) xperiod(1992(1)2004) resultsperiod(1992(1)2015) ///
	mspeperiod(1992(1)2004) fig keep(2005_all_lags_placebo) replace
graph export 1995_all_lags_placebo.pdf, replace 


****  In-time placebo test: 2005 intervention, end period at 2005  ****
synth `a'_alcohol `vars2' `a'_alcohol(1994), ///
	  	trunit(17) trperiod(2005) xperiod(1992(1)2004) mspeperiod(1992(1)2004) ///
		resultsperiod(1992(1)2015)  fig keep(2005_placebo) replace
graph export 1995_placebo.pdf, replace 


clear
use 2005_placebo
drop if _time==.
drop _Co_Number _W_Weight
rename _Y_synthetic _2005_placebo_synth
order _time, first
save 2005_placebo_short, replace
use 2005_all_lags_placebo
drop if _time==.
drop _Co_Number _W_Weight
rename _Y_synthetic _2005_all_lags_synth
order _time, first
save 2005_all_lags_short, replace
use 2005_placebo_short
merge 1:1 _time using 2005_all_lags_short, keepusing(_2005_all_lags_synth)
drop _merge
save 2005_placebo_test, replace
clear


}

}

** Find Set of Donor States

cd "`mypath'"

use "`mypath_data'alcohol_bac01.dta"
drop if year != 2015
keep state statename stateabb
rename state _Co_Number
foreach a of local depvar {
	foreach b of local sizevar {
merge 1:1 _Co_Number using "`mypath_`a'_`b''original_weight.dta", keepusing(_W_Weight)
rename _W_Weight weight_`a'_`b'
drop _merge


}
}
rename _Co_Number state
quietly: save "`mypath_data'donorstate_weights_2010.dta", replace

clear

log close
