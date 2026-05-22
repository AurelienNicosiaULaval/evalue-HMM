# Localize or temper a predictive diagnostic

Transform a diagnostic using predictable weights, either through the
linear e-value localization `1 + w_t (E_t - 1)` or through power
tempering.

## Usage

``` r
localize_predictive_diagnostic(
  diagnostic,
  weights,
  localization_name,
  mode = c("linear", "power"),
  alpha = diagnostic$alpha,
  metadata = list()
)
```

## Arguments

- diagnostic:

  A `predictive_e_diagnostic` object.

- weights:

  Numeric weights in `[0, 1]`, either scalar or one per observation.

- localization_name:

  Label for the localized process.

- mode:

  Either `"linear"` or `"power"`.

- alpha:

  Monitoring level.

- metadata:

  Optional metadata list.

## Value

A localized `predictive_e_diagnostic` object.
