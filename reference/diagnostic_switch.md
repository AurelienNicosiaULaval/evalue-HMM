# Predictable switch between diagnostics

Select one component diagnostic at each time using only previous log
e-increments over a lookback window.

## Usage

``` r
diagnostic_switch(
  diagnostics,
  lookback = 30L,
  initial_choice = 1L,
  diagnostic_name = "diagnostic_switch",
  alpha = diagnostics[[1L]]$alpha,
  metadata = list()
)
```

## Arguments

- diagnostics:

  List of `predictive_e_diagnostic` objects with matching time and
  individual identifiers.

- lookback:

  Positive integer lookback window.

- initial_choice:

  Initial component index.

- diagnostic_name:

  Diagnostic name for the switched process.

- alpha:

  Monitoring level.

- metadata:

  Optional metadata list.

## Value

A combined `predictive_e_diagnostic` object.
