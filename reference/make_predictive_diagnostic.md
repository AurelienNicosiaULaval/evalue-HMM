# Common interface for predictive e-diagnostics.

Common interface for predictive e-diagnostics.

## Usage

``` r
make_predictive_diagnostic(
  diagnostic_name,
  log_p0,
  log_q,
  alpha = 0.05,
  time = seq_along(log_p0),
  individual_id = NULL,
  weights = NULL,
  metadata = list()
)
```

## Arguments

- diagnostic_name:

  A character string. Name of the diagnostic.

- log_p0:

  Numeric vector. Log predictive density under the null.

- log_q:

  Numeric vector. Log predictive density under the alternative.

- alpha:

  Numeric. Significance level (default is 0.05).

- time:

  Numeric vector. Time indices.

- individual_id:

  Character vector or string. Identifiers for individuals.

- weights:

  Numeric vector or value. Observation weights.

- metadata:

  List. Additional metadata.

## Value

A list of class `predictive_e_diagnostic`.

## Examples

``` r
diagnostic <- make_predictive_diagnostic(
  diagnostic_name = "toy",
  log_p0 = c(-1.2, -0.8, -1.0),
  log_q = c(-1.0, -0.7, -0.9)
)
summarise_predictive_diagnostic(diagnostic)
#>   diagnostic_name alpha threshold signal crossing_time max_log_e final_log_e
#> 1             toy  0.05  2.995732  FALSE            NA       0.4         0.4
#>   mean_log_increment n_observations
#> 1          0.1333333              3
```
