# Predictive log-densities for a finite HMM family

Predictive log-densities for a finite HMM family

## Usage

``` r
hmm_family_predictive_log_density(data, parameter_family)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- parameter_family:

  Named list of HMM parameter sets.

## Value

A numeric matrix of predictive log-densities.
