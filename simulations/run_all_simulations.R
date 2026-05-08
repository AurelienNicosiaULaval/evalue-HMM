# Run implemented simulation scripts in the order used by the current article plan.
# Each script is launched in a fresh R session to detect hidden state dependencies.

simulation_scripts <- c(
  "simulations/01_null_fixed_generator.R",
  "simulations/02_train_validation_estimated.R",
  "simulations/03_underfit_states.R",
  "simulations/04_angle_misspecification.R",
  "simulations/05_step_angle_dependence.R",
  "simulations/06_duration_or_blockwise.R",
  "simulations/07_localized_failure.R",
  "simulations/08_mixture_switching.R",
  "simulations/09_parallel_product_warning.R",
  "simulations/10_blockwise_long_horizon.R",
  "simulations/11_individual_validation_crossfit.R",
  "simulations/12_composite_envelope_optional.R"
)

run_script <- function(script) {
  message("Running ", script)
  status <- system2(file.path(R.home("bin"), "Rscript"), script)
  if (!identical(status, 0L)) {
    stop("Simulation script failed: ", script, call. = FALSE)
  }
}

for (script in simulation_scripts) {
  run_script(script)
}

message("All simulation scripts completed.")
