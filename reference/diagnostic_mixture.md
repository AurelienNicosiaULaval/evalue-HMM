# Predictable mixture of diagnostic e-increments

Combine diagnostics by a row-wise weighted average of e-increments. The
weights must be fixed or predictable and each row must have total mass
no larger than one.

## Usage

``` r
diagnostic_mixture(
  diagnostics,
  weights = NULL,
  diagnostic_name = "diagnostic_mixture",
  alpha = diagnostics[[1L]]$alpha,
  metadata = list()
)
```

## Arguments

- diagnostics:

  List of `predictive_e_diagnostic` objects with matching time and
  individual identifiers.

- weights:

  Optional vector of diagnostic weights or matrix with one row per
  observation.

- diagnostic_name:

  Diagnostic name for the mixture.

- alpha:

  Monitoring level.

- metadata:

  Optional metadata list.

## Value

A combined `predictive_e_diagnostic` object.
