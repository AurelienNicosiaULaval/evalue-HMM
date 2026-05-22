# Wrapped-normal density

Wrapped-normal density

## Usage

``` r
d_wrapped_normal(theta, mean, sd, log = FALSE, n_terms = 5L)
```

## Arguments

- theta:

  Numeric vector of angles.

- mean:

  Circular mean.

- sd:

  Standard deviation before wrapping.

- log:

  Logical. Return log-density if `TRUE`.

- n_terms:

  Number of wrapped normal series terms on each side of zero.

## Value

A numeric vector of densities or log-densities.

## Examples

``` r
d_wrapped_normal(0, mean = 0, sd = 1)
#> [1] 0.3989423
```
