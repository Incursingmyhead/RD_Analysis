
**RDD Test

use "D:\工作集\RDD\Data\Data and Do Files\RDD data.dta", clear

gl Y classrank
gl Y1 lnexpminc
gl Y2 lnexpinc
gl R scee_pct
gl c = 99.75
gl cov "sex han party pedyr pparty lnfinc keyschool track wkbj obj"

gl wreps = 1000
gl rreps = 5000

drop if $R==.

gen R = $R - $c
gen D = $R >= $c
gen R1 = $R1 - $c
gen D1 =.
replace D1 =$R1 if  $R1>= $c
drop R D
*gen Y=lninc
*gen X=scee_pct


**Step 1: Descriptive Statistics
********************************************************************************
	** Table 1: Descriptive Statistics, Outcome and Running Variable 
	***********************************************************

	********************************************************************************
	** Tables 2: Summary Statistics of the Covariates and Difference in Means
	********************************************************************************
	

**Step 2: Continuity-based Approach
***********************************************************************

	**1. Test Continuity away from cutoff 
	*****************************************
		**whether the outcome variables exhibit discontinuities over the support of the running variable at places other than the actual cutoff.
	
		********************************************************************************
		** Figure 2: Scatter and RD plot
		********************************************************************************
		**Raw plot
		twoway (scatter $Y $R if track==1, mcolor(black) xline($c, lcolor(black))), graphregion(color(white)) ytitle(Outcome) xtitle(Score)

		**RD Plot
		rdplot $Y $R if $R >=96&track==1 &ccp==1, c($c) nbins(25) p(0) binselect(qs)  graph_options(graphregion(color(white)) ///
			title("") ytitle("`lab'") legend(off))

		** rdplot with MSE-optimal choice
		rdplot $Y $R if $R >=96&track==1 &ccp==1, c($c) binselect(es) p(0) graph_options(graphregion(color(white)) ///
			title("") ytitle("`lab'") legend(off))
		rdplot $Y $R if $R >=96&track==0&ccp==0, c($c) binselect(es)  p(4) graph_options(graphregion(color(white)) ///
			title("") ytitle("`lab'") legend(off))


	**2. Test Continuity of Predetermined Covariates and Placebo Outcomes
		********************************************************************************
		** Figure 2A: Rdplots
		********************************************************************************

		local nombre = 1
		foreach var of varlist $Y $cov {
			rdplot `var' $R if $R>95, c($c) graph_options(graphregion(color(white)) ///
				ytitle("`lab'") title(""))
			local ++nombre
		}
		
		********************************************************************************
		** Table 3: Formal Continuity-Based Analysis for Covariates
		********************************************************************************
		local nombre = 1    
		foreach var of varlist $Y $cov {
			rdrobust `var' $R, c($c)
			local ++nombre
		}
	
			**Check the balance of covariates-Continuity test
			rdrobust sex $R, c($c)
			local bandwidth = e(h_l)
			rdplot sex $R if R <= `bandwidth' & R >=`', h(`bandwidth') p(1) kernel(triangular) c($c) ///
				graph_options(graphregion(color(white)) ///
				ytitle("`lab'") title("") xscale(range(95 100)) ) 
	
	
	**3. Test Running variable manipulation
	*****************************************
		**whether units are sorted precisely around the cutoff (i.e., no self-selection into control or treatment status).
		**placement of units just below (control group) and just above (treatment group) should be as-if random near the RD cutoff

	
		********************************************************************************
		** Figure 2B: Minipulation Testing Plot
		********************************************************************************
		rddensity $R if track==1, c($c) 
		local bandwidth_left = e(h_l)
		local bandwidth_right = e(h_r)
		rddensity $R if track==1, plot plot_range($c-`bandwidth_left' $c+`bandwidth_right') c($c)
drop bandwidth_left bandwidth_right
	
	**4. Bandwidth Selection
	**********************************************************
		rdbwselect $Y $R, kernel(triangular) p(1) bwselect(mserd) c($c)
		rdbwselect  $Y1 $R, kernel(triangular) p(1) bwselect(msetwo) c($c)
		ereturn list
		rdrobust $Y $R if track==1&ccp==1, fuzzy(elite) kernel(triangular) p(1) bwselect(msetwo) c($c)  
		
	
	**5. Flexible parametric RD methods, not recommended
	*************************************************************************************
		**p=0 or 1 for small h, p=4 or 5 for large h; regression included
		
	

	**6. Robust bias-corrected local polynomial methods, recommended
	********************************************************************************
		** Recommend: p=1, local-linear specification; triangular kernel; MSE-optimal bandwidth estimator; robust
		**	bias-corrected inference/confidence intervals
		
		**Estimation
			** Bias correction
			rdrobust $Y $R,  c($c) kernel(triangular) p(1)  all
			rdrobust $Y $R,  c($c) kernel(triangular) p(1) bwselect(mserd) all
			rdrobust $Y $R,  c($c) kernel(triangular) p(1) bwselect(cerrd) all
			
			rdbwselect $Y $R, c($c) kernel(triangular) p(1) all 
			rdplot $Y $R , p(1) scale(9.353 0.172)  kernel(triangular) c($c) 

			**Covariate-adjust
			rdrobust $Y $R,  c($c)  covs($cov) kernel(triangular) p(1) bwselect(mserd) all
			rdrobust $Y $R,  c($c)  covs($cov) kernel(triangular) p(1) bwselect(mserd) all vce(nncluster oprov)
			rdrobust $Y $R,  c($c)  covs($cov) kernel(triangular) p(1) bwselect(mserd) all vce(nncluster oprov) scaleregul(1)
			rdrobust $Y $R,  c($c)  covs($cov) kernel(triangular) p(1) bwselect(mserd) all vce(nncluster oprov) scaleregul(1) h( -0.3 0.3)
			
	
	**7. Sensitivity Check, Placebo Cutoffs
	********************************************************************************
		** Table 4C: Continuity-Based Analysis for Alternative Cutoffs
		********************************************************************************	
		rdrobust $Y $R if track==1&ccp==1, p(1) h(0.3) c($c)
		rdrobust $Y $R if track==1&ccp==1, p(1) h(0.3) c(98.31)
		rdrobust $Y $R, p(1) h(0.3) c(99.16)		
		
		
	**8. Sensitivity Check, Observations near the Cutoff
	*******************************************************
		**test how sensitive the results are to the response of units who are located very close to the cutff. To remedy systematic manipulation.
		
		********************************************************************************
		** Table 4D: Continuity-Based Analysis for the Donut-Hole Approach
		********************************************************************************
		rdrobust $Y $R if abs($R-$c) >= 0.1,  c($c)
		rdrobust $Y $R if abs($R-$c) >= 0.2,  c($c)
		rdrobust $Y $R if abs($R-$c) >= 0.1,  c($c) kernel(triangular) p(1) bwselect(mserd)
		
		
	**9. Sensitivity Check, Bandwidth Choice- Choosing different h's
	************************************************************************
		rdrobust $Y $R,  c($c) covs($cov) kernel(triangular) p(1) bwselect(mserd) all
		rdrobust $Y $R,  c($c) covs($cov) kernel(triangular) p(1) bwselect(cerrd) all
		rdrobust $Y $R, kernel(triangular) p(1) bwselect(msetwo) c($c)  h(13.498  0.248)
		rdrandinf $Y R, wl(-13.498) wr(0.248) seed(50) statistic(ksmirnov)

		
	**10. Rdplot to show rdrobust estimate
	********************************************************************************
		** Figure 2C Rdplot to show rdrobust estimate
		********************************************************************************
		rdplot $Y $R if $R>=96 & $R<100, vce(nncluster oprov) c($c) p(1) ///
			   graph_options(title("RD Plot: Cutoff=99.75") ///
							 ytitle(First Job Income Logged) ///
							 xtitle(SCEE Score Index) ///
							 graphregion(color(white)))

		
		
**Step 3: Local Randamization Approach
***********************************************************************

	**1. Window Slection
		**finding an interval around the cutoff in which pretreatment covariates are balanced between treated and control units

		********************************************************************************
		** Figure 3: Window Selection
		********************************************************************************
		** Window Selection
			rdwinselect R $cov if track==1 &ccp==1, reps($wreps) stat(ksmirnov) wmin(.1) wstep(.1) level(.15)
			rdwinselect R $cov if track==1, seed(50) wstep(0.1) nwindows(20) plot

		** Generate p-values plot 
		** NOTE: the plot is drawn using the asymptotic p-value to speed up the process.
		** Remove the "approx" option to use randinf and replicate the results in the paper.

		rdwinselect R $cov, reps($wreps) stat(ksmirnov) nwin(40) wmin(.05) wstep(.05) level(.2) plot 
		mat Res = r(results)
		preserve
		svmat Res
		rename Res1 pvalues 
		rename Res6 w
		*replace w=-w
		gen red=pval if Res3==28
		twoway(scatter pval w)(scatter red w, msize(vlarge) msymbol(circle_hollow) mlwidth(medthick)), ///
			xline(0.35,lpattern(shortdash)) ytitle(p-values) xtitle(bandwidth) ///
			xlabel(0(.2)2, labsize(small)) legend(off) graphregion(color(white))
		restore
		
	
			
	**2. Estimation
		********************************************************************************
		** Table 5: Local Randomization Methods
		********************************************************************************
		mat T = J(8,6,.)
		gl w0 = 0.17

		rdrandinf $Y1 R, wl(-$w0) wr($w0) reps($rreps)
		mat T[1,1] = r(p)
		mat T[2,1] = round(r(wr),.001)
		mat T[3,1] = round(r(obs_stat),.001)
		mat T[4,1] = round(r(randpval),.001)
		mat T[5,1] = r(N_left)
		mat T[6,1] = r(N_right)

		rdrandinf $Y R, wl(-1.45) wr(1.45) reps($rreps)
		mat T[1,2] = r(p)
		mat T[2,2] = round(r(wr),.001)
		mat T[3,2] = round(r(obs_stat),.001)
		mat T[4,2] = round(r(randpval),.001)
		mat T[5,2] = r(N_left)
		mat T[6,2] = r(N_right)

		rdrandinf $Y R, wl(-1.7) wr(1.7) reps($rreps)
		mat T[1,3] = r(p)
		mat T[2,3] = round(r(wr),.001)
		mat T[3,3] = round(r(obs_stat),.001)
		mat T[4,3] = round(r(randpval),.001)
		mat T[5,3] = r(N_left)
		mat T[6,3] = r(N_right)

		rdrandinf $Y R, wl(-$w0) wr($w0) reps($rreps) p(1)
		mat T[1,4] = r(p)
		mat T[2,4] = round(r(wr),.001)
		mat T[3,4] = round(r(obs_stat),.001)
		mat T[4,4] = round(r(randpval),.001)
		mat T[5,4] = r(N_left)
		mat T[6,4] = r(N_right)

		rdrandinf $Y R, wl(-1.45) wr(1.45) reps($rreps) p(1)
		mat T[1,5] = r(p)
		mat T[2,5] = round(r(wr),.001)
		mat T[3,5] = round(r(obs_stat),.001)
		mat T[4,5] = round(r(randpval),.001)
		mat T[5,5] = r(N_left)
		mat T[6,5] = r(N_right)

		rdrandinf $Y R, wl(-1.7) wr(1.7) reps($rreps) p(1)
		mat T[1,6] = r(p)
		mat T[2,6] = round(r(wr),.001)
		mat T[3,6] = round(r(obs_stat),.001)
		mat T[4,6] = round(r(randpval),.001)
		mat T[5,6] = r(N_left)
		mat T[6,6] = r(N_right)

		** Placebo outcomes
		local i=7
		foreach var of varlist $Y1 $Y2 {
			rdrandinf `var' R, wl(-$w0) wr($w0) reps($rreps)
			mat T[`i',1] = round(r(randpval),.001)
			rdrandinf `var' R, wl(-1.45) wr(1.45) reps($rreps)
			mat T[`i',2] = round(r(randpval),.001)
			rdrandinf `var' R, wl(-1.7) wr(1.7) reps($rreps)
			mat T[`i',3] = round(r(randpval),.001)

			rdrandinf `var' R, wl(-$w0) wr($w0) reps($rreps) p(1)
			mat T[`i',4] = round(r(randpval),.001)
			rdrandinf `var' R, wl(-1.45) wr(1.45) reps($rreps) p(1)
			mat T[`i',5] = round(r(randpval),.001)
			rdrandinf `var' R, wl(-1.7) wr(1.7) reps($rreps) p(1)
			mat T[`i',6] = round(r(randpval),.001)
			
			local ++i
		}

		matlist T
		
		
	**3. Test Balance of Predetermined Covariates and Placebo Outcomes
	***********************************************************************
		**test no systematic differences between treated and control groups awithin the window for both placebo outcomes and predetermined covariates
		
		********************************************************************************
		** Figure 3A: Rdplots
		********************************************************************************
		gl w0=0.3
		
		local nombre = 1
		foreach var of varlist $Y $cov {
			rdplot `var' $R if abs(R)<$w0, c($c) h($w0) p(0) kernel(uniform) graph_options(graphregion(color(white)) ///
				ytitle("`lab'") title(""))
			local ++nombre
		}
				
		********************************************************************************
		** Table 5C: Formal Analysis for Covariates
		********************************************************************************
		local nombre = 1    
		foreach var of varlist $Y $cov {
			rdrandinf `var' R, wl(-$w0) wr($w0)
			local ++nombre
		}
	
	**4. Test Running variable manipulation, within the window
	********************************************************************
		** Figure 3B: Minipulation Testing Plot
		********************************************************************************
		rddensity $R if abs(R)<$w0, c($c) 
		local bandwidth_left = e(h_l)
		local bandwidth_right = e(h_r)
		rddensity $R if abs(R)<$w0, plot plot_range($c-`bandwidth_left' $c+`bandwidth_right') c($c)

		
	**5. Sensitivity to Window Length
		**test the null that the (constant) treatment effect is equal to τ and obtain the p-value, p>0.05 cannot reject the null		
		
		********************************************************************************
		** Figure 4: Sensitivity to bandwidth choice
		********************************************************************************
		rdsensitivity $Y R, wlist(0.1(0.1)0.8) tlist(-1(.1)1) p(0)  saving(graphdata) 
		preserve
		use graphdata, clear
		twoway contour pvalue t w, ccuts(0(0.05)1) ccolors(gray*0.01 gray*0.05 ///
			gray*0.1 gray*0.15 gray*0.2 gray*0.25 gray*0.3 gray*0.35 ///
			gray*0.4 gray*0.5 gray*0.6 gray*0.7 gray*0.8 gray*0.9 gray ///
			black*0.5  black*0.6 black*0.7 black*0.8 black*0.9 black) ///
			xlabel(.1(.1).8, labsize(small)) ylabel(-1(.1)1, nogrid labsize(small)) ///
			graphregion(color(white)) ytitle("null hypothesis") xtitle(bandwidth)
		restore

		rdsensitivity $Y R, wlist(0.1(0.1)0.8) tlist(-1(.1)1) p(1) saving(graphdata_p1)
		preserve
		use graphdata_p1, clear
		twoway contour pvalue t w, ccuts(0(0.05)1) ccolors(gray*0.01 gray*0.05 ///
			gray*0.1 gray*0.15 gray*0.2 gray*0.25 gray*0.3 gray*0.35 ///
			gray*0.4 gray*0.5 gray*0.6 gray*0.7 gray*0.8 gray*0.9 gray ///
			black*0.5  black*0.6 black*0.7 black*0.8 black*0.9 black) ///
			xlabel(.1(.1).8, labsize(small)) ylabel(-1(.1)1, nogrid labsize(small)) ///
			graphregion(color(white)) ytitle("null hypothesis") xtitle(bandwidth)
		restore

		
		
	**6. Test Local SUTVA
			**units do not interfere with each other, usually called the stable unit treatment value assumption (SUTVA).

		********************************************************************************
		** Table 6: Local Randomization Methods -- CI and Interference
		********************************************************************************
		gl w0 = 0.1

		mat T = J(10,2,.)

		rdrandinf $Y R , wl(-$w0) wr($w0) reps($rreps) interfci(.95) p(0)
		mat T[1,1] = r(p)
		mat T[2,1] = round(r(wr),.001)
		mat T[3,1] = round(r(obs_stat),.001)
		mat T[4,1] = round(r(randpval),.001)
		mat T[7,1] = round(r(int_lb),.001)
		mat T[8,1] = round(r(int_ub),.001)
		mat T[9,1] = r(N_left)
		mat T[10,1] = r(N_right)
		*mat CI[1,2] = round(r(obs_stat),.001)
		*rdsensitivity $Y R if wkbj==1, wlist($w0) tlist(-1(.025)0) ci($w0) reps($rreps) nodraw 
		mat T[5,1] = round(r(ci_lb),.001)
		mat T[6,1] = round(r(ci_ub),.001)
		*mat CI[1,1] = round(r(ci_lb),.001)
		*mat CI[1,3] = round(r(ci_ub),.001)

		rdrandinf $Y R , wl(-$w0) wr($w0) reps($rreps) interfci(.95) p(1)
		mat T[1,2] = r(p)
		mat T[2,2] = round(r(wr),.001)
		mat T[3,2] = round(r(obs_stat),.001)
		mat T[4,2] = round(r(randpval),.001)
		mat T[7,2] = round(r(int_lb),.001)
		mat T[8,2] = round(r(int_ub),.001)
		mat T[9,2] = r(N_left)
		mat T[10,2] = r(N_right)
		*mat CI[2,2] = round(r(obs_stat),.001)
		*rdsensitivity $Y R if wkbj==1, wlist($w0) tlist(-1(.025)0) ci($w0) reps($rreps) nodraw p(1)
		mat T[5,2] = round(r(ci_lb),.001)
		mat T[6,2] = round(r(ci_ub),.001)
		*mat CI[2,1] = round(r(ci_lb),.001)
		*mat CI[2,3] = round(r(ci_ub),.001)

		matlist T		
		
		
**Step 4: Summary of Results
***********************************************************************

	********************************************************************************
	** Additional empirical analysis
	********************************************************************************

	** NOTE: this analysis is not reported in the paper.

	** Robust Nonparametric Methods with Covariates
	rdrobust $Y R, covs($cov)

	** Robust Nonparametric Methods: Different Bandwdiths at Each Side
	rdrobust $Y R, bwselect(msetwo)		
	

	**Fuzzy RD
	rdrobust $Y $R, c($c) fuzzy(D) covs($cov) vce(nncluster oprov)


	




