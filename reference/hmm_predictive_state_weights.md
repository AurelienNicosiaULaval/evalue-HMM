# Predictive state weights from an HMM filter

Predictive state weights from an HMM filter

## Usage

``` r
hmm_predictive_state_weights(data, parameters, state = NULL)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- parameters:

  Null HMM parameters.

- state:

  Optional state index. If `NULL`, return all state weights.

## Value

A matrix of predicted state probabilities, or one numeric vector if
`state` is supplied.
