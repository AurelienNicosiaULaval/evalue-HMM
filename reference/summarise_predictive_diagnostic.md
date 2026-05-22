# Summarise predictive e-diagnostic results.

Summarise predictive e-diagnostic results.

## Usage

``` r
summarise_predictive_diagnostic(diagnostic)
```

## Arguments

- diagnostic:

  A `predictive_e_diagnostic` object.

## Value

A data frame summarizing the diagnostic.

## Examples

``` r
diagnostic <- make_predictive_diagnostic(
  diagnostic_name = "toy",
  log_p0 = c(-1.2, -0.8),
  log_q = c(-1.0, -0.7)
)
summarise_predictive_diagnostic(diagnostic)
#>   diagnostic_name alpha threshold signal crossing_time max_log_e final_log_e
#> 1             toy  0.05  2.995732  FALSE            NA       0.3         0.3
#>   mean_log_increment n_observations
#> 1               0.15              2
```
