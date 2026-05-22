# Conservative finite-family composite-null diagnostic

Use the pointwise maximum predictive density over a finite null family
as a conservative denominator.

## Usage

``` r
diagnostic_composite_envelope(
  data,
  null_family,
  diagnostic_parameters,
  alpha = 0.05,
  diagnostic_name = "composite_envelope",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length`, `turning_angle`, `time`, and
  `individual_id`.

- null_family:

  Named list of null HMM parameter sets.

- diagnostic_parameters:

  Diagnostic HMM parameters.

- alpha:

  Monitoring level.

- diagnostic_name:

  Diagnostic name.

- metadata:

  Optional metadata list.

## Value

A `predictive_e_diagnostic` object.
