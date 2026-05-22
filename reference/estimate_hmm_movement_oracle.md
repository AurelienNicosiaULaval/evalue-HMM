# Estimate movement-HMM parameters from known states

Estimate the built-in movement-HMM parameters from simulated data where
latent states are observed. This helper is intended for controlled
simulation studies and is not a general HMM fitting routine.

## Usage

``` r
estimate_hmm_movement_oracle(
  data,
  n_states = NULL,
  initial_pseudocount = 1,
  transition_pseudocount = 1,
  min_step_variance = 1e-04,
  min_angle_sd = 0.05
)
```

## Arguments

- data:

  Data frame with `individual_id`, `time`, `state`, `step_length`, and
  `turning_angle`.

- n_states:

  Number of states. If `NULL`, inferred from `data$state`.

- initial_pseudocount, transition_pseudocount:

  Non-negative smoothing pseudo-counts.

- min_step_variance:

  Lower bound for within-state step-length variance.

- min_angle_sd:

  Lower bound for within-state angle standard deviation.

## Value

A parameter list compatible with
[`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).
