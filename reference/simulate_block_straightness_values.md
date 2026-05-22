# Simulate block straightness values

Simulate block straightness values

## Usage

``` r
simulate_block_straightness_values(
  n_simulations,
  block_size,
  parameters,
  generator = c("hmm", "ar_angle"),
  rho_by_state = NULL
)
```

## Arguments

- n_simulations:

  Number of simulated blocks.

- block_size:

  Number of observations per block.

- parameters:

  Parameter list from
  [`create_hmm_movement_parameters()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/create_hmm_movement_parameters.md).

- generator:

  Either `"hmm"` or `"ar_angle"`.

- rho_by_state:

  State-dependent autoregressive correlations for
  `generator = "ar_angle"`.

## Value

A numeric vector of straightness values.
