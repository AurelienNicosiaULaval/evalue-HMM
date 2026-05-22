# Fit beta approximations to block-straightness laws

Fit beta approximations to block-straightness laws

## Usage

``` r
fit_block_straightness_laws(
  parameters,
  rho_by_state,
  block_size,
  n_simulations = 10000L
)
```

## Arguments

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- rho_by_state:

  State-dependent autoregressive correlations for the diagnostic
  alternative.

- block_size:

  Number of observations per block.

- n_simulations:

  Number of simulated blocks for each law.

## Value

A data frame of fitted beta law parameters.
