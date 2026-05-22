# Create movement-HMM parameters

Construct a parameter list for the built-in Gamma step-length and
wrapped normal turning-angle HMM used in examples and simulations.

## Usage

``` r
create_hmm_movement_parameters(
  initial_probs = c(0.65, 0.35),
  transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
  step_shape = c(2, 7),
  step_rate = c(3, 2),
  angle_mean = c(0, 0),
  angle_sd = c(1.6, 0.35)
)
```

## Arguments

- initial_probs:

  Numeric probability vector for the initial latent state.

- transition_matrix:

  Square transition probability matrix.

- step_shape, step_rate:

  State-dependent Gamma shape and rate parameters.

- angle_mean, angle_sd:

  State-dependent wrapped-normal mean and standard deviation parameters.

## Value

A list of HMM movement parameters.

## Examples

``` r
parameters <- create_hmm_movement_parameters()
str(parameters)
#> List of 6
#>  $ initial_probs    : num [1:2] 0.65 0.35
#>  $ transition_matrix: num [1:2, 1:2] 0.92 0.12 0.08 0.88
#>  $ step_shape       : num [1:2] 2 7
#>  $ step_rate        : num [1:2] 3 2
#>  $ angle_mean       : num [1:2] 0 0
#>  $ angle_sd         : num [1:2] 1.6 0.35
```
