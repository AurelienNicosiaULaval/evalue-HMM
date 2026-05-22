# Reproducibility audit

Date: 2026-05-08

Project: predictive e-diagnostics for multi-state movement models

Base commit before audit modifications: `6e5a561`

## Scope

This audit checks whether the current project can regenerate the main computational outputs from clean R sessions and compile the manuscript files.

The audit covered:

- all simulation scenarios S1 to S12;
- the complete elk application workflow;
- the main LaTeX manuscript;
- the supplementary material;
- ignored generated outputs and data products;
- basic R environment information.

This audit was run on the current local machine. It is not a fresh-clone audit on a separate computer. A first `renv.lock` file was added after the local audit to document the R package environment.

## Commands run

```bash
Rscript simulations/run_all_simulations.R
Rscript application/run_application.R
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=/tmp/evalue-HMM-latex-main paper/predictive_e_diagnostics_hmm_improved.tex
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=/tmp/evalue-HMM-latex-supp paper/supplementary_material.tex
```

The simulation and application runners now launch each component script in a fresh R session using `Rscript`. This checks that scripts do not silently depend on objects left in memory by earlier scripts.

## Results

| Component | Status | Runtime observed | Notes |
|---|---:|---:|---|
| Simulations S1 to S12 | Passed | 141.22 s | All scripts completed in fresh R sessions. |
| Elk application | Passed | 18.39 s | Preprocessing, HMM fitting, diagnostics and ggplot figures completed. |
| Main manuscript | Passed | 5.24 s | Compiled after repeated LaTeX runs, no warnings reported in final pass. |
| Supplement | Passed | 0.77 s | Compiled without warnings reported in final pass. |
| Git output policy | Passed | NA | Generated tables, generated figures and processed application data remain ignored by Git. |

## Key numerical checks at alpha = 0.05

### Main simulation scenarios

| Scenario | Quantity checked | Value |
|---|---:|---:|
| S1 null fixed generator | false signal rate | 0.030 |
| S3 underfit states | signal rate | 0.997 |
| S4 angle misspecification | signal rate | 1.000 |
| S5 step-angle dependence | signal rate | 1.000 |
| S6 HMM null | signal rate | 0.000 |
| S6 HSMM duration alternative | signal rate | 1.000 |
| S7 global diagnostic | signal rate | 0.063 |
| S7 failure-window and state-localized diagnostic | signal rate | 0.900 |
| S8 null mixture | signal rate | 0.036 |
| S8 null switching | signal rate | 0.036 |
| S8 changing alternative mixture | signal rate | 1.000 |
| S8 changing alternative switching | signal rate | 1.000 |

### Supplementary simulation scenarios

| Scenario | Quantity checked | Value |
|---|---:|---:|
| S9 single valid e-process | signal rate | 0.030 |
| S9 weighted average of two copies | signal rate | 0.030 |
| S9 naive product of two copies | signal rate | 0.117 |
| S9 naive product of three copies | signal rate | 0.215 |
| S10 HMM null | signal rate | 0.036 |
| S10 long-horizon alternative | signal rate | 0.796 |
| S11 true-null cross-fitted average | signal rate | 0.000 |
| S11 true-null any-individual scan | signal rate | 0.304 |
| S11 fitted-null cross-fitted average | signal rate | 0.004 |
| S11 fitted-null any-individual scan | signal rate | 0.228 |
| S11 single failed individual, cross-fitted average | signal rate | 0.996 |
| S12 diffuse-angle null, center-only denominator | signal rate | 0.980 |
| S12 diffuse-angle null, composite envelope | signal rate | 0.000 |

## Elk application checks

The current application output uses Leave-One-Animal-Out validation across the four elk individuals. The regenerated model-selection table selects `K = 3` by BIC for folds `elk-115`, `elk-287`, and `elk-363`, and `K = 4` for fold `elk-163`. For a common cross-fitted diagnostic comparison, the application fixes the null generator to `K = 3` and the diagnostic state-number alternative to `K = 4` across folds.

The current population-average diagnostic summary is:

| Diagnostic | Signal | Final log e |
|---|---:|---:|
| `state_number_K3_vs_K4` | Yes | 6.009 |
| `angle_diffuse_K3` | No | 1.706 |
| `mixture_state_angle` | Yes | 9.747 |
| `state_number_K3_vs_K4__predicted_state_3` | Yes | 4.573 |

## Generated outputs

Simulation outputs were regenerated in:

- `results/simulation_tables/`;
- `results/simulation_figures/`.

Application outputs were regenerated in:

- `application/data_processed/`;
- `results/application_tables/`;
- `results/application_figures/`;
- `paper/figures/`.

The `paper/figures/` application figures are tracked because they are manuscript-ready figures. The other generated outputs are ignored by Git by design.

## R environment

```text
R version 4.5.0 (2025-04-11)
Platform: aarch64-apple-darwin20
Running under: macOS 26.5
Time zone: America/Toronto
```

Package versions checked during the audit:

| Package | Version |
|---|---:|
| ggplot2 | 4.0.2 |
| dplyr | 1.2.1 |
| tidyr | 1.3.2 |
| scales | 1.4.0 |
| moveHMM | 1.10 |

## Issues and limitations

- No blocking issue was found in the local audit.
- This was not a clean install on a new machine.
- The project now has an `renv.lock` file, but `renv::restore()` has not yet been tested in a fresh clone.
- The application remains exploratory because it uses a four-individual Leave-One-Animal-Out analysis and a diagnostic menu chosen for this proof of concept.

## Recommended next step

Test `renv::restore()` in a fresh clone or on a separate machine before external sharing.
