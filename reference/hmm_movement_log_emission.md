# Compute state-dependent log-emission densities

Compute state-dependent log-emission densities

## Usage

``` r
hmm_movement_log_emission(data, parameters)
```

## Arguments

- data:

  Data frame with `step_length` and `turning_angle`.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

## Value

A numeric matrix of log-emission densities with one column per state.
