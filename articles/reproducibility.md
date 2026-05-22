# Reproducibility guide

This project has two layers:

1.  the installable R package `evalueHMM`;
2.  the research compendium containing simulations, the elk application
    and the LaTeX manuscript.

The package is designed to be checked and installed independently of the
heavy research outputs.

## Package checks

From the repository root, the package can be checked with:

``` bash
R CMD build --no-build-vignettes .
R CMD check --no-manual --no-build-vignettes evalueHMM_0.1.0.tar.gz
```

For a full vignette build:

``` bash
R CMD build .
R CMD check --no-manual evalueHMM_0.1.0.tar.gz
```

## Research workflow

The simulation scripts are kept outside the package build because they
are manuscript-scale computations.

``` bash
Rscript simulations/run_all_simulations.R
Rscript application/run_application.R
```

The manuscript can be compiled from the `paper/` directory.

``` bash
cd paper
pdflatex predictive_e_diagnostics_hmm_improved.tex
pdflatex predictive_e_diagnostics_hmm_improved.tex
pdflatex supplementary_material.tex
pdflatex supplementary_material.tex
```

## Reproducible environments

The repository includes `renv.lock` for recreating the local package
environment:

``` r

renv::restore()
```

The package tests and vignettes use small seeded examples. The
manuscript simulation scripts set their own random seeds and write
generated files under `results/`, while application outputs are written
under `application/data_processed/`, `results/application_*`, and
`paper/figures/`.

The generated research outputs are intentionally excluded from the
source package. They remain part of the research compendium workflow.
