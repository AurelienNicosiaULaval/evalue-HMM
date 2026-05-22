# Blockwise diagnostic for duration misspecification

Compare the observed number of switches in a binary long-step feature
within contiguous blocks to the predictive distribution under an HMM and
an HSMM-like diagnostic alternative.

## Usage

``` r
diagnostic_duration_blockwise(
  data,
  null_parameters,
  dwell_mean,
  dwell_size,
  step_threshold,
  block_size = 30L,
  n_simulations = 1000L,
  pseudo_count = 1,
  alpha = 0.05,
  diagnostic_name = "duration_blockwise",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- null_parameters:

  Null HMM parameters.

- dwell_mean, dwell_size:

  HSMM-like dwell-time parameters for the diagnostic alternative.

- step_threshold:

  Positive threshold defining long steps.

- block_size:

  Number of observations per block.

- n_simulations:

  Number of simulations for the HSMM block feature law.

- pseudo_count:

  Non-negative pseudo-count for the simulated alternative feature
  distribution.

- alpha:

  Monitoring level.

- diagnostic_name:

  Diagnostic name.

- metadata:

  Optional metadata list.

## Value

A `predictive_e_diagnostic` object with block-level features.
