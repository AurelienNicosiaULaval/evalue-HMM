# Compute predictive e-processes from log predictive densities.

Compute predictive e-processes from log predictive densities.

## Usage

``` r
compute_eprocess(log_p0, log_p1, alpha = 0.05, time = seq_along(log_p0))
```

## Arguments

- log_p0:

  Numeric vector. Log predictive density under the null.

- log_p1:

  Numeric vector. Log predictive density under the alternative.

- alpha:

  Numeric. Significance level (default is 0.05).

- time:

  Numeric vector. Time indices.

## Value

A list containing the e-process path and signal metrics.

## Examples

``` r
log_p0 <- c(-1.2, -0.8, -1.0)
log_q <- c(-1.0, -0.7, -0.9)
compute_eprocess(log_p0, log_q)
#> $path
#>   time log_p0 log_p1 log_e_increment log_e_cumulative threshold
#> 1    1   -1.2   -1.0             0.2              0.2  2.995732
#> 2    2   -0.8   -0.7             0.1              0.3  2.995732
#> 3    3   -1.0   -0.9             0.1              0.4  2.995732
#> 
#> $alpha
#> [1] 0.05
#> 
#> $threshold
#> [1] 2.995732
#> 
#> $crossing_time
#> [1] NA
#> 
#> $signal
#> [1] FALSE
#> 
```
