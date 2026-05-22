# Simulation Scenarios

This directory contains the R scripts to reproduce the simulation scenarios presented in the paper (S1 to S12). 

## Simulation Scripts

| Script | Scenario | Description | Location in Paper |
|---|---|---|---|
| `01_null_fixed_generator.R` | S1 | Calibration under a correctly specified 2-state HMM null generator. | Main Article |
| `02_train_validation_estimated.R` | S2 | Train/validation protocol with estimated parameters. | Supplementary Material |
| `03_underfit_states.R` | S3 | Underfitted model (null K=2 vs. true K=3). | Main Article |
| `04_angle_misspecification.R` | S4 | Angular component misspecification. | Main Article |
| `05_step_angle_dependence.R` | S5 | Residual step-angle dependence (copula violation). | Main Article |
| `06_duration_or_blockwise.R` | S6 | Non-geometric state dwell times (HSMM data). | Main Article |
| `07_localized_failure.R` | S7 | State-localized copula failure. | Main Article |
| `08_mixture_switching.R` | S8 | Multiple sequential failures (switching diagnostic). | Main Article |
| `09_parallel_product_warning.R` | S9 | Demonstration of the invalidity of naive parallel products. | Supplementary Material |
| `10_blockwise_long_horizon.R` | S10 | Blockwise long-horizon diagnostics. | Supplementary Material |
| `11_individual_validation_crossfit.R` | S11 | Multi-individual validation and population cross-fitting. | Supplementary Material |
| `12_composite_envelope_optional.R` | S12 | Conservative composite-null envelope. | Supplementary Material |
| `13_comparative_power_residuals.R` | - | Comparative power against classical pseudo-residual tests. | Main Article (Figure 1) |

## Running the Simulations

You can run all simulations sequentially by executing:
```bash
Rscript simulations/run_all_simulations.R
```
This script runs the scenarios and saves the outputs (CSV tables and PNG plots) to `results/simulation_tables/` and `results/simulation_figures/`.
