# Compute block straightness

Compute net displacement divided by total path length for a block of
movement observations.

## Usage

``` r
compute_block_straightness(step_length, turning_angle, eps = 1e-05)
```

## Arguments

- step_length:

  Numeric step lengths.

- turning_angle:

  Numeric turning angles.

- eps:

  Clipping value used to keep the feature in `(0, 1)`.

## Value

A scalar straightness index.
