# Diagnostic for angular distribution misspecification

Compare a null movement HMM with a diagnostic HMM using the same number
of states but altered turning-angle parameters.

## Usage

``` r
diagnostic_angle(
  data,
  null_parameters,
  angle_parameters,
  alpha = 0.05,
  time = NULL,
  individual_id = NULL,
  diagnostic_name = "angle_misspecification",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- null_parameters:

  Null HMM parameters.

- angle_parameters:

  Diagnostic HMM parameters with the same number of states.

- alpha:

  Monitoring level.

- time:

  Optional time index.

- individual_id:

  Optional individual identifier.

- diagnostic_name:

  Diagnostic name.

- metadata:

  Optional metadata list.

## Value

A `predictive_e_diagnostic` object.
