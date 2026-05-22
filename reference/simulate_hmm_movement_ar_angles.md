# Simulate movement with autoregressive angle residuals

Simulate trajectories where the latent angle residual follows a
state-specific autoregressive process, useful as a long-horizon
diagnostic alternative.

## Usage

``` r
simulate_hmm_movement_ar_angles(
  n_times,
  parameters,
  rho_by_state,
  n_individuals = 1L
)
```

## Arguments

- n_times:

  Number of observations per individual.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- rho_by_state:

  State-dependent autoregressive correlations.

- n_individuals:

  Number of independent individuals.

## Value

A simulated movement data frame.
