# Forward filter a finite-state HMM

Run the HMM forward filter using log-emission densities and return
observable predictive log-densities together with predicted and filtered
state probabilities.

## Usage

``` r
hmm_forward_filter(log_emission, transition_matrix, initial_probs)
```

## Arguments

- log_emission:

  Numeric matrix of log-emission densities with rows as observations and
  columns as states.

- transition_matrix:

  Square transition probability matrix.

- initial_probs:

  Initial state probability vector.

## Value

A list with `predicted_probs`, `filtered_probs`, and
`log_predictive_density`.

## Examples

``` r
log_emission <- log(matrix(c(0.6, 0.4, 0.5, 0.5), nrow = 2, byrow = TRUE))
transition_matrix <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
hmm_forward_filter(log_emission, transition_matrix, c(0.5, 0.5))
#> $predicted_probs
#>      [,1] [,2]
#> [1,] 0.50 0.50
#> [2,] 0.62 0.38
#> 
#> $filtered_probs
#>      [,1] [,2]
#> [1,] 0.60 0.40
#> [2,] 0.62 0.38
#> 
#> $log_predictive_density
#> [1] -0.6931472 -0.6931472
#> 
```
