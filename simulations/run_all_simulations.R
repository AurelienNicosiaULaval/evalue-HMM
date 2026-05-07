# Run all implemented simulation scripts.
# Scripts are listed explicitly to keep execution order reproducible.

simulation_scripts <- c(
  "simulations/01_null_control.R",
  "simulations/02_underfit_states.R",
  "simulations/03_angle_misspecification.R",
  "simulations/04_step_angle_dependence.R",
  "simulations/05_duration_misspecification.R",
  "simulations/06_local_failure.R"
)

for (script in simulation_scripts) {
  message("Running ", script)
  source(script)
}
