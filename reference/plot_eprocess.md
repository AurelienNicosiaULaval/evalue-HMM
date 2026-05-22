# Plot a predictive e-process

Plot a predictive e-process

## Usage

``` r
plot_eprocess(eprocess, title = "Predictive e-process")
```

## Arguments

- eprocess:

  Object returned by
  [`compute_eprocess()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/compute_eprocess.md).

- title:

  Plot title.

## Value

A `ggplot` object.

## Examples

``` r
eprocess <- compute_eprocess(c(-1, -1), c(-0.8, -0.9))
plot_eprocess(eprocess)
```
