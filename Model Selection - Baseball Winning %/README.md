# Model Selection – Baseball Winning Percentage

## Overview  
This project explores how offensive and defensive team statistics influence **MLB team winning percentage** using **multiple linear regression and model selection techniques**.  
The analysis fits an initial full regression model and evaluates alternative models using **AIC (Akaike Information Criterion)** and **p-value-based backward selection (`fastbw()`)**.

This work was completed as part of a Linear Models assignment and has been refined into a self-contained GitHub project.

## Dataset
The analysis uses data from the **2011 MLB season** (Baseball2011 dataset). Derived variables include:

BA   <- H / AB
OBP  <- (H + BB + HBP) / (AB + BB + HBP + SF)
X1B  <- H - (X2B + X3B + HR)
SLG  <- (X1B + 2*X2B + 3*X3B + 4*HR) / AB
Win.p <- W / G   # Winning Percentage (response variable)

## Objectives

	1.	Fit a multiple linear regression model to predict winning percentage.
	2.	Perform model selection using:
      - Backward p-value elimination (fastbw()) with sls = 0.05 and sls = 0.75
	    - AIC-based stepwise selection (stepAIC())
	    - Forward AIC selection from intercept-only model
	3.	Compare full vs. reduced models (R², adjusted R², AIC, predictor significance).
	4.	Interpret results and assess which statistics most strongly relate to winning percentage.
  

## Methods & Model Selection:

- Full Model (lm): Win.p ~ BA + OBP + HR + ERA + FP + SLG
- P-value-based Selection (fastbw): Removes predictors based on significance threshold sls = 0.05 and 0.75
- AIC Value (extractAIC): Extracts AIC for full model; useful only when compared across models
- Stepwise AIC (stepAIC): Backward AIC-based variable selection starting from full model
- Forward AIC Selection: Adds predictors one at a time using `stepAIC`

## Results (High-Level Summary)

- The **initial full model** achieved strong explanatory power (high R² and adjusted R²).
- **Model selection methods did not always agree** — `fastbw()` and `stepAIC()` sometimes selected different predictors, demonstrating that criteria (AIC vs. p-values) optimize different objectives.
- Some predictors with **non-significant p-values in the full model became significant in smaller reduced models**, likely due to removal of collinear variables and changes in variance.
- AIC values were only useful **comparatively**, not in isolation.
