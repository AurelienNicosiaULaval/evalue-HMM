# Simulate movement from a finite-state HMM

Simulate one or more independent trajectories with state-dependent Gamma
step lengths and wrapped-normal turning angles.

## Usage

``` r
simulate_hmm_movement(n_times, parameters, n_individuals = 1L)
```

## Arguments

- n_times:

  Number of observations per individual.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- n_individuals:

  Number of independent individuals.

## Value

A data frame with individual id, time, latent state, step length and
turning angle.

## Examples

``` r
set.seed(1)
parameters <- create_hmm_movement_parameters()
simulate_hmm_movement(5, parameters)
#>   individual_id time state step_length turning_angle
#> 1             1    1     1   1.1543901    -0.4886214
#> 2             1    2     1   0.6836040     2.4188499
#> 3             1    3     1   1.2951363     0.6237492
#> 4             1    4     1   0.8468467    -0.9939849
#> 5             1    5     1   0.7626888     2.7396655
```
