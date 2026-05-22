# Predictive E-Diagnostics for Hidden Markov Models of Animal Movement

This repository contains the R package, simulation code, and real-data application for the paper:
> **Predictive E-Diagnostics for Hidden Markov Models of Animal Movement**
> Aurélien Nicosia (Université Laval)

## Overview

Hidden Markov models (HMMs) are widely used to analyze animal movement trajectories by partitioning them into discrete behavioral states. Standard diagnostic workflows (such as AIC/BIC, decoded state paths, or pseudo-residuals) often fail to provide a sequentially valid account of model fit, or they rely on reconstructions of latent states rather than observable data.

This project implements a framework for **predictive e-diagnostics**. By treating a fitted HMM as a sequential generator of validation data, we define e-processes (nonnegative supermartingales) that evaluate model goodness-of-fit against targeted alternatives. 

This repository is structured as both a reproducible research directory and an R package (`evalueHMM`).

## Repository Structure

```text
.
├── DESCRIPTION                 # R package metadata
├── NAMESPACE                   # R package namespace exports
├── R/                          # Core package functions (filtering, e-processes, diagnostics)
├── simulations/                # Simulation scripts for scenarios S1 to S12
├── application/                # Empirical application on elk movement data (LOAO validation)
├── results/                    # Output directories for generated tables and figures (ignored by Git)
└── paper/                      # LaTeX source files for the manuscript and supplementary material
```

## Installation & Setup

To reproduce the environment and dependencies exactly as used in the paper, we use `renv`.

1. Clone the repository:
   ```bash
   git clone https://github.com/AurelienNicosiaULaval/predictive_e_diagnostics_hmm.git
   cd predictive_e_diagnostics_hmm
   ```

2. Open R and restore the package library:
   ```r
   renv::restore()
   ```

## Running Simulations

The simulation scenarios S1 to S12 presented in the main text and supplementary material can be run sequentially using:
```bash
Rscript simulations/run_all_simulations.R
```
Individual scenario scripts can also be executed independently (e.g., `Rscript simulations/03_underfit_states.R`). Tables and figures will be saved in `results/simulation_tables/` and `results/simulation_figures/`.

## Real-Data Application

The empirical application evaluates a 3-state HMM on elk movement data from the `moveHMM` package under a Leave-One-Animal-Out (LOAO) validation protocol.

To run the full application pipeline and generate the paper figures:
```bash
Rscript application/run_application.R
```
Generated plots are written to `results/application_figures/` and copied to `paper/figures/`.

## Manuscript Compilation

The LaTeX manuscript and supplementary material can be compiled using:
```bash
cd paper
pdflatex predictive_e_diagnostics_hmm_improved.tex
pdflatex supplementary_material.tex
```

## License

This project is licensed under the GPL-3 License.
