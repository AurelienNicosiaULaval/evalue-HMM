# Simulate movement with localized residual copula dependence

Simulate movement with localized residual copula dependence

## Usage

``` r
simulate_hmm_movement_local_copula(
  n_times,
  parameters,
  rho_by_state,
  active_times,
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

  State-dependent Gaussian copula correlations during active times.

- active_times:

  Logical vector or numeric time indices where dependence is active.

- n_individuals:

  Number of independent individuals.

## Value

A simulated movement data frame including the active-dependence flag.
