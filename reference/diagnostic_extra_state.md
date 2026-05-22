# Diagnostic for an insufficient number of states

Compare a null movement HMM with a diagnostic HMM containing exactly one
additional state.

## Usage

``` r
diagnostic_extra_state(
  data,
  null_parameters,
  extra_state_parameters,
  alpha = 0.05,
  time = NULL,
  individual_id = NULL,
  diagnostic_name = "extra_state",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- null_parameters:

  Null HMM parameters.

- extra_state_parameters:

  Diagnostic HMM parameters with one extra state.

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
