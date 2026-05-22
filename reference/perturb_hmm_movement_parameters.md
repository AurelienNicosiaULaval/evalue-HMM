# Perturb movement-HMM parameters

Create a nearby diagnostic parameter set by modifying step means, angle
means, angle standard deviations and transition or initial
probabilities.

## Usage

``` r
perturb_hmm_movement_parameters(
  parameters,
  step_mean_multiplier = NULL,
  angle_mean_shift = NULL,
  angle_sd_multiplier = NULL,
  transition_blend = 0.08,
  initial_blend = 0.03
)
```

## Arguments

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- step_mean_multiplier, angle_mean_shift, angle_sd_multiplier:

  Scalar or state-specific perturbations.

- transition_blend, initial_blend:

  Blend weights toward uniform transition or initial probabilities.

## Value

A perturbed parameter list.
