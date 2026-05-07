# Run the complete real-data application workflow.

application_scripts <- c(
  "application/01_preprocess.R",
  "application/02_fit_hmm.R",
  "application/03_compute_eprocess.R",
  "application/04_figures_application.R"
)

for (script in application_scripts) {
  message("Running ", script)
  source(script)
}
