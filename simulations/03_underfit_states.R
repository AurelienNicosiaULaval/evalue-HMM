# S3: Underfitted number of states.
# This simulation checks whether a K+1 predictive diagnostic accumulates evidence
# when validation data are generated from a 3-state HMM but evaluated against a
# 2-state null HMM.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_states.R")

set.seed(20260508)

n_replicates <- 300L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

true_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.50, 0.35, 0.15),
  transition_matrix = matrix(
    c(
      0.91, 0.06, 0.03,
      0.08, 0.87, 0.05,
      0.08, 0.10, 0.82
    ),
    nrow = 3,
    byrow = TRUE
  ),
  step_shape = c(2.0, 7.5, 4.0),
  step_rate = c(3.0, 2.0, 1.2),
  angle_mean = c(0.0, 0.0, 0.6),
  angle_sd = c(1.6, 0.35, 0.75)
)

# A deliberately underfitted two-state null. In this first implementation the
# parameters are fixed rather than estimated, matching the fixed-generator logic.
null_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.62, 0.38),
  transition_matrix = matrix(c(0.90, 0.10, 0.14, 0.86), nrow = 2, byrow = TRUE),
  step_shape = c(2.2, 6.8),
  step_rate = c(3.0, 1.8),
  angle_mean = c(0.0, 0.1),
  angle_sd = c(1.55, 0.45)
)

# The diagnostic competitor has one additional state and is fixed before validation.
extra_state_parameters <- true_parameters

replicate_results <- vector("list", n_replicates)
path_results <- vector("list", min(25L, n_replicates))

for (replicate_index in seq_len(n_replicates)) {
  simulated_data <- simulate_hmm_movement(
    n_times = n_times,
    parameters = true_parameters,
    n_individuals = 1L
  )

  diagnostic <- diagnostic_extra_state(
    data = simulated_data,
    null_parameters = null_parameters,
    extra_state_parameters = extra_state_parameters,
    alpha = 0.05,
    diagnostic_name = "extra_state_k2_vs_k3",
    metadata = list(scenario = "underfit_states")
  )

  summary <- summarise_predictive_diagnostic(diagnostic)
  state_3_fraction <- mean(simulated_data$state == 3L)

  replicate_results[[replicate_index]] <- data.frame(
    replicate = replicate_index,
    state_3_fraction = state_3_fraction,
    max_log_e = summary$max_log_e,
    final_log_e = summary$final_log_e,
    mean_log_increment = summary$mean_log_increment,
    crossing_time_alpha_005 = summary$crossing_time,
    signal_alpha_005 = summary$signal,
    stringsAsFactors = FALSE
  )

  if (replicate_index <= length(path_results)) {
    path_results[[replicate_index]] <- data.frame(
      replicate = replicate_index,
      time = diagnostic$path$time,
      log_e_cumulative = diagnostic$path$log_e_cumulative,
      log_e_increment = diagnostic$path$log_e_increment,
      stringsAsFactors = FALSE
    )
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(alphas, function(alpha) {
    threshold <- log(1 / alpha)
    signal <- replicate_results$max_log_e >= threshold
    signal_rate <- mean(signal)
    monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
    crossing_times <- replicate_results$crossing_time_alpha_005[replicate_results$signal_alpha_005]

    data.frame(
      scenario = "underfit_states",
      alpha = alpha,
      threshold = threshold,
      n_replicates = n_replicates,
      n_times = n_times,
      signal_rate = signal_rate,
      monte_carlo_se = monte_carlo_se,
      mean_max_log_e = mean(replicate_results$max_log_e),
      median_max_log_e = stats::median(replicate_results$max_log_e),
      mean_final_log_e = mean(replicate_results$final_log_e),
      median_final_log_e = stats::median(replicate_results$final_log_e),
      mean_state_3_fraction = mean(replicate_results$state_3_fraction),
      mean_crossing_time_alpha_005 = if (length(crossing_times) == 0L) NA_real_ else mean(crossing_times),
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s3_underfit_states_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s3_underfit_states_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s3_underfit_states_paths.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s3_underfit_states_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
plot(
  NA,
  xlim = range(path_results$time),
  ylim = range(c(path_results$log_e_cumulative, log(1 / alphas))),
  xlab = "Time",
  ylab = "Cumulative log e-value",
  main = "S3: K+1 diagnostic under a 3-state generator"
)
for (replicate_index in unique(path_results$replicate)) {
  replicate_path <- path_results[path_results$replicate == replicate_index, ]
  lines(
    replicate_path$time,
    replicate_path$log_e_cumulative,
    col = grDevices::adjustcolor("darkgreen", alpha.f = 0.35),
    lwd = 1
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("sample paths", "alpha = 0.05 threshold"),
  col = c("darkgreen", "firebrick"),
  lwd = c(1, 2),
  lty = c(1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s3_underfit_states_final_vs_state3.png"),
  width = 1800,
  height = 1100,
  res = 180
)
plot(
  replicate_results$state_3_fraction,
  replicate_results$final_log_e,
  pch = 19,
  col = grDevices::adjustcolor("darkgreen", alpha.f = 0.55),
  xlab = "Fraction of observations generated from state 3",
  ylab = "Final cumulative log e-value",
  main = "S3: evidence increases when the missing state is more present"
)
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
dev.off()

message("S3 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
