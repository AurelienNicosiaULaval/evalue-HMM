# Composite-envelope predictive log-density

Compute the pointwise maximum predictive log-density over a finite null
family.

## Usage

``` r
hmm_composite_envelope_log_density(data, parameter_family)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- parameter_family:

  Named list of HMM parameter sets.

## Value

A numeric vector of envelope log-densities.
