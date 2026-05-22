# Wrapped-normal distribution function

Wrapped-normal distribution function

## Usage

``` r
p_wrapped_normal(theta, mean, sd, n_terms = 8L)
```

## Arguments

- theta:

  Numeric vector of angles.

- mean:

  Circular mean.

- sd:

  Standard deviation before wrapping.

- n_terms:

  Number of wrapped normal series terms on each side of zero.

## Value

A numeric vector of distribution function values clipped to `[0, 1]`.

## Examples

``` r
p_wrapped_normal(0, mean = 0, sd = 1)
#> [1] 0.5
```
