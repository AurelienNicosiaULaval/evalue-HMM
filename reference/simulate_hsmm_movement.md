# Simulate movement from an HSMM-like dwell-time generator

Simulate trajectories with non-geometric state dwell times while
retaining the same state-dependent movement emissions as the built-in
HMM generator.

## Usage

``` r
simulate_hsmm_movement(
  n_times,
  parameters,
  dwell_mean,
  dwell_size,
  n_individuals = 1L
)
```

## Arguments

- n_times:

  Number of observations per individual.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- dwell_mean, dwell_size:

  State-dependent negative-binomial dwell-time parameters.

- n_individuals:

  Number of independent individuals.

## Value

A simulated movement data frame.
