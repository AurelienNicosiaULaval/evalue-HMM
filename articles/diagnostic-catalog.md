# Diagnostic catalog

``` r

library(evalueHMM)
```

This vignette shows the main diagnostic families available in
`evalueHMM` on a small simulated trajectory.

``` r

set.seed(20260522)

null_parameters <- create_hmm_movement_parameters()
validation_data <- simulate_hmm_movement(
  n_times = 120,
  parameters = null_parameters
)
```

## Full-density diagnostics

A state-number diagnostic compares the null HMM with a diagnostic HMM
containing one additional state.

``` r

extra_state_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.55, 0.35, 0.10),
  transition_matrix = matrix(
    c(0.90, 0.08, 0.02,
      0.10, 0.85, 0.05,
      0.12, 0.10, 0.78),
    nrow = 3,
    byrow = TRUE
  ),
  step_shape = c(2, 7, 4),
  step_rate = c(3, 2, 1.5),
  angle_mean = c(0, 0, 0.4),
  angle_sd = c(1.6, 0.35, 0.8)
)

state_diagnostic <- diagnostic_extra_state(
  data = validation_data,
  null_parameters = null_parameters,
  extra_state_parameters = extra_state_parameters
)

summarise_predictive_diagnostic(state_diagnostic)
#>   diagnostic_name alpha threshold signal crossing_time max_log_e final_log_e
#> 1     extra_state  0.05  2.995732  FALSE            NA 0.3591196     -2.4075
#>   mean_log_increment n_observations
#> 1         -0.0200625            120
```

An angular diagnostic keeps the number of states fixed but modifies the
angular component.

``` r

angle_parameters <- perturb_hmm_movement_parameters(
  parameters = null_parameters,
  angle_sd_multiplier = c(1.2, 1.4)
)

angle_diagnostic <- diagnostic_angle(
  data = validation_data,
  null_parameters = null_parameters,
  angle_parameters = angle_parameters
)

summarise_predictive_diagnostic(angle_diagnostic)
#>          diagnostic_name alpha threshold signal crossing_time max_log_e
#> 1 angle_misspecification  0.05  2.995732  FALSE            NA 0.9907954
#>   final_log_e mean_log_increment n_observations
#> 1   -16.05119         -0.1337599            120
```

## Feature-level diagnostics

The step-angle diagnostic uses sequential Rosenblatt residuals and a
Gaussian copula diagnostic density.

``` r

copula_diagnostic <- diagnostic_step_angle_dependence(
  data = validation_data,
  null_parameters = null_parameters,
  rho = 0.35
)

summarise_predictive_diagnostic(copula_diagnostic)
#>         diagnostic_name alpha threshold signal crossing_time max_log_e
#> 1 step_angle_dependence  0.05  2.995732  FALSE            NA 0.1915168
#>   final_log_e mean_log_increment n_observations
#> 1   -6.168072         -0.0514006            120
head(copula_diagnostic$features)
#>   time individual_id    u_step u_angle_given_step
#> 1    1             1 0.5192033          0.5526524
#> 2    2             1 0.8533820          0.1120446
#> 3    3             1 0.3045583          0.8917249
#> 4    4             1 0.7906669          0.7526889
#> 5    5             1 0.9969001          0.2834269
#> 6    6             1 0.1707527          0.3835694
```

## Predictable combinations

Diagnostics can be combined by predictable mixture weights.

``` r

mixture <- diagnostic_mixture(
  diagnostics = list(
    angle = angle_diagnostic,
    copula = copula_diagnostic
  ),
  weights = c(0.5, 0.5)
)

summarise_predictive_diagnostic(mixture)
#>      diagnostic_name alpha threshold signal crossing_time max_log_e final_log_e
#> 1 diagnostic_mixture  0.05  2.995732  FALSE            NA 0.5295084   -5.323307
#>   mean_log_increment n_observations
#> 1        -0.04436089            120
```

## Localization

A diagnostic can be localized using predictable weights. The following
example only accumulates evidence over a time window.

``` r

window_weights <- time_window_weights(
  time = mixture$path$time,
  start = 40,
  end = 90
)

localized <- localize_predictive_diagnostic(
  diagnostic = mixture,
  weights = window_weights,
  localization_name = "time_window"
)

summarise_predictive_diagnostic(localized)
#>                   diagnostic_name alpha threshold signal crossing_time
#> 1 diagnostic_mixture__time_window  0.05  2.995732  FALSE            NA
#>   max_log_e final_log_e mean_log_increment n_observations
#> 1 0.7323388   -2.593072        -0.02160893            120
```

State-localized diagnostics can also use filtered predictive state
probabilities.

``` r

state_weights <- hmm_predictive_state_weights(
  data = validation_data,
  parameters = null_parameters,
  state = 2
)

summary(state_weights)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#> 0.08000 0.08000 0.08438 0.42445 0.87924 0.88000
```
