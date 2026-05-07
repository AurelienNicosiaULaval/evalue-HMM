# S4: Angular misspecification.
# This simulation checks whether an angular predictive diagnostic accumulates
# evidence when the null HMM has the correct state structure and step model but
# a misspecified turning-angle distribution.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_angles.R")

set.seed(20260509)

n_replicates <- 300L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

true_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.65, 0.35),
  transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 7.0),
  step_rate = c(3.0, 2.0),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(1.8, 0.25)
)

# The null has the correct step and transition structure but a poor angular model.
# State 1 is too concentrated and state 2 is too diffuse and slightly off-centre.
null_parameters <- create_hmm_movement_parameters(
  initial_probs = true_parameters$initial_probs,
  transition_matrix = true_parameters$transition_matrix,
  step_shape = true_parameters$step_shape,
  step_rate = true_parameters$step_rate,
  angle_mean = c(0.0, 0.25),
  angle_sd = c(1.0, 0.75)
)

# The diagnostic alternative targets the angular distribution and is fixed before validation.
angle_parameters <- true_parameters

replicate_results <- vector("list", n_replicates)
path_results <- vector("list", min(25L, n_replicates))

for (replicate_index in seq_len(n_replicates)) {
  simulated_data <- simulate_hmm_movement(
    n_times = n_times,
    parameters = true_parameters,
    n_individuals = 1L
  )

  diagnostic <- diagnostic_angle(
    data = simulated_data,
    null_parameters = null_parameters,
    angle_parameters = angle_parameters,
    alpha = 0.05,
    diagnostic_name = "angle_full_density",
    metadata = list(scenario = "angle_misspecification")
  )

  summary <- summarise_predictive_diagnostic(diagnostic)

  replicate_results[[replicate_index]] <- data.frame(
    replicate = replicate_index,
    state_2_fraction = mean(simulated_data$state == 2L),
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
      scenario = "angle_misspecification",
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
      mean_state_2_fraction = mean(replicate_results$state_2_fraction),
      mean_crossing_time_alpha_005 = if (length(crossing_times) == 0L) NA_real_ else mean(crossing_times),
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s4_angle_misspecification_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s4_angle_misspecification_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s4_angle_misspecification_paths.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s4_angle_misspecification_paths.png"),
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
  main = "S4: angular diagnostic under misspecified turning angles"
)
for (replicate_index in unique(path_results$replicate)) {
  replicate_path <- path_results[path_results$replicate == replicate_index, ]
  lines(
    replicate_path$time,
    replicate_path$log_e_cumulative,
    col = grDevices::adjustcolor("purple4", alpha.f = 0.35),
    lwd = 1
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("sample paths", "alpha = 0.05 threshold"),
  col = c("purple4", "firebrick"),
  lwd = c(1, 2),
  lty = c(1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s4_angle_misspecification_final_vs_state2.png"),
  width = 1800,
  height = 1100,
  res = 180
)
plot(
  replicate_results$state_2_fraction,
  replicate_results$final_log_e,
  pch = 19,
  col = grDevices::adjustcolor("purple4", alpha.f = 0.55),
  xlab = "Fraction of observations generated from state 2",
  ylab = "Final cumulative log e-value",
  main = "S4: angular evidence versus directional-state frequency"
)
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
dev.off()

message("S4 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
