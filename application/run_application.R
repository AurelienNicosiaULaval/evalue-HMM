# Run the complete real-data application workflow.
# Each step is launched in a fresh R session while preserving file-based outputs.

application_scripts <- c(
  "application/01_preprocess.R",
  "application/02_fit_hmm.R",
  "application/03_compute_eprocess.R",
  "application/04_figures_application.R"
)

run_script <- function(script) {
  message("Running ", script)
  status <- system2(file.path(R.home("bin"), "Rscript"), script)
  if (!identical(status, 0L)) {
    stop("Application script failed: ", script, call. = FALSE)
  }
}

for (script in application_scripts) {
  run_script(script)
}

message("Application workflow completed.")
