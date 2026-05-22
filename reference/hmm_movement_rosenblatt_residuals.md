# Sequential Rosenblatt residuals for movement HMMs

Compute step PIT residuals and angle conditional PIT residuals under the
observable predictive mixture implied by a fitted movement HMM.

## Usage

``` r
hmm_movement_rosenblatt_residuals(data, parameters)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- parameters:

  Null HMM parameters.

## Value

A data frame with residual features.
