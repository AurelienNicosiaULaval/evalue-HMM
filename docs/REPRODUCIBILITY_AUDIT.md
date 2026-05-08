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

This audit was run on the current local machine. It is not a fresh-clone audit on a separate computer, and the project does not yet include an `renv.lock` file.

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

The application regenerated the following model-selection table.

| States | Negative log-likelihood | AIC | BIC | Selected null |
|---:|---:|---:|---:|---:|
| 2 | 5190.649 | 10407.298 | 10462.919 | No |
| 3 | 4994.368 | 10034.736 | 10133.142 | Yes |
| 4 | 4976.707 | 10023.414 | 10173.162 | No |

The application regenerated the following diagnostic summary.

| Diagnostic | Signal | Crossing time | Max log e | Final log e |
|---|---:|---:|---:|---:|
| `state_number_K3_vs_K4` | Yes | 16 | 5.459 | 5.413 |
| `angle_diffuse_K3` | No | NA | 2.811 | 0.154 |
| `mixture_state_angle` | Yes | 22 | 11.089 | 10.981 |
| `state_number_K3_vs_K4__predicted_state_3` | Yes | 123 | 5.618 | 5.605 |

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
- The project does not yet have a package lockfile such as `renv.lock`.
- The application remains exploratory because it uses one held-out individual and a diagnostic menu chosen for this proof of concept.

## Recommended next step

Create a lightweight dependency lock or session record for the submission archive. The simplest next step is to add an `renv.lock` file or a documented package-version table before external sharing.
