# Compute movement-HMM observable predictive log-density

Compute movement-HMM observable predictive log-density

## Usage

``` r
hmm_movement_predictive_log_density(data, parameters)
```

## Arguments

- data:

  Data frame with `step_length` and `turning_angle`.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

## Value

A numeric vector of one-step predictive log-densities.

## Examples

``` r
set.seed(1)
parameters <- create_hmm_movement_parameters()
data <- simulate_hmm_movement(5, parameters)
hmm_movement_predictive_log_density(data, parameters)
#> [1] -2.869487 -2.793775 -2.952991 -2.189199 -2.983309
```
