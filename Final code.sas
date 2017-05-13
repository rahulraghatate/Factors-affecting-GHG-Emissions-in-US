proc import datafile="I:\SPEA P507\Project\Data\Finale.xlsx" out=data dbms=xlsx replace;
    getnames=yes;
	sheet = "Sheet1";
run;
quit();

proc contents;
run;
quit();

*Bivariate Regression Model: Air_transport__freight__million;
proc reg plots=none;
model ghg = airtrans;
run;
quit();

*Bivariate Regression Model: electric;
proc reg plots=none;
model ghg = electric;
run;
quit();

*Bivariate Regression Model: energy;
proc reg plots=none;
model ghg = energy;
run;
quit();

*Bivariate Regression Model: Exports_of_goods_and_services__c;
proc reg plots=none;
model ghg = export;
run;
quit();

*Bivariate Regression Model: fossil;
proc reg plots=none;
model ghg = fossil;
run;
quit();

*Bivariate Regression Model: pop;
proc reg plots=none;
model ghg = pop;
run;
quit();

*Bivariate Regression Model: Portland_Cement_Production__thou;
proc reg plots=none;
model ghg = cement;
run;
quit();

*Bivariate Regression Model: fish;
proc reg plots=none;
model ghg = fish;
run;
quit();

*Bivariate Regression Model: agriland;
proc reg plots=none;
model ghg = agriland;
run;
quit();

*Bivariate Regression Model: popgrowth;
proc reg plots=none;
model ghg = popgrowth;
run;
quit();

*Bivariate Regression Model: gdp;
proc reg plots=none;
model ghg = gdp;
run;
quit();

*Original Regression Model : w/o energy (ns) and popgrowth (ns) and fossil (taking electric);
proc reg;
model ghg = airtrans electric export pop cement fish agriland gdp/stb vif COLLIN;
run;
quit();

*Correlation;
proc corr;
var airtrans electric export pop cement fish agriland gdp;
run;
quit();

*Regression Model : w/o gdp (highly correlated with 5 features);
proc reg;
model ghg = airtrans electric export pop cement fish agriland/stb vif COLLIN;
run;
quit();

*Correlation: w/o gdp;
proc corr;
var airtrans electric export pop cement fish agriland;
run;
quit();

*Regression Model : w/o pop (highly correlated with 4 features);
proc reg;
model ghg = airtrans electric export cement fish agriland/stb vif COLLIN;
run;
quit();

*Correlation: w/o pop;
proc corr;
var airtrans electric export cement fish agriland;
run;
quit();

*Aux Regression Model : airtrans;
proc reg plots=none;
model airtrans = electric export cement fish agriland/stb vif;
run;
quit();

*Aux Regression Model : electric;
proc reg plots=none;
model electric = airtrans export cement fish agriland/stb vif;
run;
quit();

*Aux Regression Model : export;
proc reg plots=none;
model export = airtrans electric cement fish agriland/stb vif;
run;
quit();

*Aux Regression Model : agriland;
proc reg plots=none;
model agriland = airtrans electric export cement fish/stb vif;
run;
quit();

*Regression Model II: w/o airtrans (aux gave higher R-sqr only with airtrans);
proc reg;
model ghg = electric export cement fish agriland/stb vif COLLIN;
run;
quit();

*Aux Regression Model : electric;
proc reg plots=none;
model electric = export cement fish agriland/stb vif;
run;
quit();

*Aux Regression Model : export;
proc reg plots=none;
model export = electric cement fish agriland/stb vif;
run;
quit();

*Aux Regression Model : agriland;
proc reg plots=none;
model agriland = export electric cement fish/stb vif;
run;
quit();

*Correlation: since aux gave no results;
proc corr;
var electric export cement fish agriland;
run;
quit();


*Regression Model : w/o electric (correlated with exp, fish n agri);
proc reg plots=none;
model ghg = export cement fish agriland/stb vif COLLIN;
run;
quit();

*Regression Model : w/o export (correlated with electric n agri);
proc reg plots=none;
model ghg = electric cement fish agriland/stb vif COLLIN;
run;
quit();

*Regression Model : w/o agriland (correlated with electric n export);
proc reg plots=none;
model ghg = electric export cement fish/stb vif COLLIN;
run;
quit();

*Regression Model III: w/o agriland (lowest collin wrt w/o export and w/o electric);
proc reg plots=none;
model ghg = electric export cement fish/stb vif COLLIN;
run;
quit();

*Aux Regression Model : electric;
proc reg plots=none;
model electric = export cement fish/stb vif;
run;
quit();
*No use since R-sqr lesser than original;

*So checking correlation;
proc corr;
var electric export cement fish;
run;
quit();
*electric more correlated than others;

*Final Regression Model IV: w/o electric;
proc reg plots=none;
model ghg = export cement fish/stb vif COLLIN;
run;
quit();

*Final Model: w/o electric 
*Check auto-correlation using Durbin-Watson statistic and heteroskedasticity using White test;
proc reg;
model ghg = export cement fish/stb vif spec COLLIN dwprob;
run;
quit();

* Final Model: Cochrane-Orcutt process;
* Step 1; 
* Execute the original model with Durbin-Watson statistic ; 
* to show auto-correlation exists ; 
proc reg plots=none;
model ghg = export cement fish/stb vif COLLIN dwprob;
OUTPUT R=resid OUT=data2; 
run;
quit();

* Step 2; 
* Begin the Cochrane-Orcutt process by generating the lagged residuals; 
DATA data3; 
SET data2; 
residl = LAG1(resid); 
RUN;
QUIT();

* Using the residuals and lagged residuals, generate a first-round estimate; 
* of rho by using proc reg to derive the autocorrelation coefficient as the; 
* slope coefficient of the resid variable.;
TITLE "First Round Estimate of Rho";
PROC REG plots=none data=data3; 
MODEL resid = residl/NOINT; 
RUN;
QUIT();

* Step 3; 
* After running Proc Reg to get the autocorrelation coefficient, the next; 
* steps provide the first-difference transforms for the Cochrane-Orcutt; 
* procedure. Note that the first round estimate of rho = 0.49669;
DATA chor; 
SET data2; 
rho = 0.49669; 
ghg2 = ghg - rho*LAG1(ghg);	
export2 = export - rho*LAG1(export); 
cement2 = cement - rho*LAG1(cement); 
fish2 = fish - rho*LAG1(fish);
RUN;
QUIT();

* Now run the transformed regression to generate the WLS estimates from; 
* the first round estimate of rho, ignoring the Prais-Winsten transforms.;
TITLE "First Round WLS Estimates"; 
PROC REG plots=none data=chor; 
MODEL ghg2 = export2 cement2 fish2/ VIF TOL COLLINOINT STB dwprob; 
RUN;
QUIT();

* Step 4; 
* To use the second round residuals to generate a new estimate of rho; 
* calculate the second round residuals from the original variables using the; 
* beta hats obtained from the above WLS regression.;
* Intercept = beta1/1-rho = 1903708/(1-0.49669) = 3782376.67;
DATA data4; 
SET data2; 
resid2 = ghg - 3782376.67 - (0.36245*export) - (25.38408*cement) - (61.28627*fish); 
* Lag the second round residuals; 
resid2l = LAG1(resid2); 
RUN;
QUIT();

* Now generate the second round estimate of rho by using Proc Reg again; 
TITLE "Second Round Estimate of Rho"; 
PROC REG plots=none data=data4; 
MODEL resid2 = resid2l/NOINT; 
RUN;
QUIT();

*Step 5; 
* The second round estimate of rho=0.59496. Now take this final estimate; 
* and carry out the Weighted Least Squares transforms but without Prais-Winsten;
DATA chor2; 
SET data2; 
rho = 0.59496; 
ghg3 = ghg - rho*LAG1(ghg);	
export3 = export - rho*LAG1(export); 
cement3 = cement - rho*LAG1(cement); 
fish3 = fish - rho*LAG1(fish);
RUN;
QUIT();

* Execute the Weighted Least Squares regression (finally!); 
* Remember to transform the intercept after estimating this by dividing by 1-rho; 
PROC REG data=chor2; 
MODEL ghg3 = export3 cement3 fish3 /dwprob; 
RUN;
QUIT();

*Step 6; 
*Calculate R-squared for final model; 
* Intercept = beta1/1-rho = 1611196/(1-0.59496) = 3977868.85; 
DATA new; 
SET data; 
ghghat = 3977868.85 + 0.32798*export + 23.74982*cement + 52.41416*fish; 
RUN;
QUIT();

*Step 7;
TITLE "R for final model"; 
PROC CORR; 
var ghg ghghat; 
RUN;
QUIT();
*0.93566^2 = 0.87546;

*Model 2: Yule-Walker WLS Estimates;
* Step 1;
TITLE "Yule-Walker WLS Estimates Using Proc AutoReg";
PROC AUTOREG DATA=data;
MODEL ghg = export cement fish/METHOD=YW NLAG=1 ITER;
RUN;
QUIT();

*Calculate R-squared for PROC AUTOREG;
DATA new1;
SET data;
ghghat2 = 3606443 + 0.3730*export + 25.4628*cement + 90.5568*fish;
RUN;
QUIT();

TITLE "R for PROC AUTOREG final model";
PROC CORR;
var ghg ghghat2;
RUN;
QUIT();
*0.93584^2 = 0.8758;
