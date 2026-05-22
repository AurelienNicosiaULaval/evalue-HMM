# Real-Data Application: Elk Movement Analysis

This directory implements the Leave-One-Animal-Out (LOAO) predictive validation protocol on the elk movement dataset from Michelot et al. (2016).

## Data Source

The raw elk trajectory data is distributed with the `moveHMM` R package:
- Michelot, T., Langrock, R., & Patterson, T. A. (2016). `moveHMM`: an R package for the analysis of animal movement data using hidden Markov models. *Methods in Ecology and Evolution*, 7(11), 1301-1307.
- Morales, J. M., Haydon, D. T., Frair, J., Holsinger, K. E., & Fryxell, J. M. (2004). Extracting more out of relocation data: building movement models as mixtures of random walks. *Ecology*, 85(9), 2433-2445.

## Analysis Pipeline

The empirical analysis is split into modular scripts:

1. `01_preprocess.R`: Loads and preprocesses the raw elk relocations, computes step lengths and turning angles, and prepares the LOAO folds.
2. `02_fit_hmm.R`: Fits candidate null HMMs (K = 2, 3, 4) on training folds using maximum likelihood estimation.
3. `03_compute_eprocess.R`: Integrates out latent states via forward filtering and computes the sequential predictive e-processes on the held-out validation trajectories.
4. `04_figures_application.R`: Generates the figures summarizing the individual and population-level diagnostics.
5. `utils_movehmm_eprocess.R`: Helper functions to convert fitted `moveHMM` models into observable predictive densities.

## Running the Pipeline

To run the entire pipeline from raw data to finished figures:
```bash
Rscript application/run_application.R
```
Outputs are written to `results/application_figures/` and copied to the `paper/figures/` directory for LaTeX compilation.
