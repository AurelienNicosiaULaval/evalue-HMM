# Simulate movement with residual step-angle dependence

Simulate the same marginal HMM as
[`simulate_hmm_movement()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement.md)
but introduce a Gaussian copula between step length and turning angle
within each state.

## Usage

``` r
simulate_hmm_movement_copula(
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

  State-dependent Gaussian copula correlations.

- n_individuals:

  Number of independent individuals.

## Value

A simulated movement data frame.
