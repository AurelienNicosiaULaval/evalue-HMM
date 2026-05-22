# Diagnostic for residual step-angle dependence

Build a feature-level e-process from sequential Rosenblatt residuals and
a Gaussian copula diagnostic alternative.

## Usage

``` r
diagnostic_step_angle_dependence(
  data,
  null_parameters,
  rho = 0.5,
  alpha = 0.05,
  time = NULL,
  individual_id = NULL,
  diagnostic_name = "step_angle_dependence",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- null_parameters:

  Null HMM parameters.

- rho:

  Gaussian copula correlation used by the diagnostic alternative.

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

A `predictive_e_diagnostic` object with residual features attached.
