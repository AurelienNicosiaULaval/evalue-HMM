# Paper review notes

Date: 2026-05-08

The current manuscript is ready for a first paper-based scientific rereading.

## Printable files generated locally

The following PDFs were generated in `manuscript_outputs/`:

- `predictive_e_diagnostics_hmm_improved_review_2026-05-08.pdf`
- `supplementary_material_review_2026-05-08.pdf`

The `manuscript_outputs/` directory is ignored by Git because PDFs are generated outputs. Regenerate them from the LaTeX sources before printing if the manuscript changes.

## What this version is ready for

- Reading the argument from introduction to discussion.
- Checking theorem statements and assumptions.
- Checking whether the simulations support the stated claims.
- Checking whether the elk application is interpreted cautiously.
- Annotating figure placement, captions and table readability.

## What this version is not yet ready for

- Journal submission.
- External circulation as a polished preprint.

Remaining visible placeholders:

- author information;
- acknowledgements.

Remaining reproducibility step:

- test `renv::restore()` in a fresh clone or on another machine.

## Suggested paper-review checklist

1. Circle every notation that feels ambiguous on first reading.
2. Mark every place where a validity claim depends on train/validation separation.
3. Check whether each simulation result is tied to a theorem or methodological claim.
4. Check whether the elk application avoids confirmatory ecological language.
5. Mark figures that are too dense when printed in grayscale.
6. Note any result that should move between the main article and supplement.
