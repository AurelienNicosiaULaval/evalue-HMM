# Long-horizon straightness diagnostic

Build a blockwise e-process for a straightness feature using beta
approximations to null and diagnostic block-feature laws.

## Usage

``` r
diagnostic_long_horizon_straightness(
  data,
  law_parameters,
  block_size = 60L,
  alpha = 0.05,
  diagnostic_name = "long_horizon_straightness",
  metadata = list()
)
```

## Arguments

- data:

  Movement data with `step_length` and `turning_angle`.

- law_parameters:

  Output from
  [`fit_block_straightness_laws()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/fit_block_straightness_laws.md).

- block_size:

  Number of observations per block.

- alpha:

  Monitoring level.

- diagnostic_name:

  Diagnostic name.

- metadata:

  Optional metadata list.

## Value

A `predictive_e_diagnostic` object with block-level features.
