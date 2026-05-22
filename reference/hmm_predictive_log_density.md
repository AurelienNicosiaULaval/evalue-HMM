# Compute observable HMM predictive log-density

Convenience wrapper around
[`hmm_forward_filter()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_forward_filter.md)
returning only the observable one-step predictive log-density.

## Usage

``` r
hmm_predictive_log_density(log_emission, transition_matrix, initial_probs)
```

## Arguments

- log_emission:

  Numeric matrix of log-emission densities.

- transition_matrix:

  Square transition probability matrix.

- initial_probs:

  Initial state probability vector.

## Value

A numeric vector of predictive log-densities.
