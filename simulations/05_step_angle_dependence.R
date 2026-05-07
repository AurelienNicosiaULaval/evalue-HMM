# S5: Residual step-angle dependence.
# This simulation checks whether a Rosenblatt/copula feature-level diagnostic detects
# residual dependence between step length and turning angle after accounting for
# latent-state uncertainty under the null HMM.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_copula.R")

set.seed(20260510)

n_replicates <- 300L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

null_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.65, 0.35),
  transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 7.0),
  step_rate = c(3.0, 2.0),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(0.85, 0.30)
)

# Same HMM margins as the null, but with conditional step-angle dependence.
rho_by_state <- c(0.60, 0.60)
diagnostic_rho <- 0.55

replicate_results <- vector("list", n_replicates)
path_results <- vector("list", min(25L, n_replicates))
feature_results <- vector("list", min(8L, n_replicates))

for (replicate_index in seq_len(n_replicates)) {
  simulated_data <- simulate_hmm_movement_copula(
    n_times = n_times,
    parameters = null_parameters,
    rho_by_state = rho_by_state,
    n_individuals = 1L
  )

  diagnostic <- diagnostic_step_angle_dependence(
    data = simulated_data,
    null_parameters = null_parameters,
    rho = diagnostic_rho,
    alpha = 0.05,
    diagnostic_name = "step_angle_gaussian_copula",
    metadata = list(scenario = "step_angle_dependence")
  )

  summary <- summarise_predictive_diagnostic(diagnostic)
  feature_correlation <- stats::cor(
    stats::qnorm(diagnostic$features$u_step),
    stats::qnorm(diagnostic$features$u_angle_given_step)
  )

  replicate_results[[replicate_index]] <- data.frame(
    replicate = replicate_index,
    feature_correlation = feature_correlation,
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
  if (replicate_index <= length(feature_results)) {
    feature_results[[replicate_index]] <- data.frame(
      replicate = replicate_index,
      u_step = diagnostic$features$u_step,
      u_angle_given_step = diagnostic$features$u_angle_given_step,
      stringsAsFactors = FALSE
    )
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)
feature_results <- do.call(rbind, feature_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(alphas, function(alpha) {
    threshold <- log(1 / alpha)
    signal <- replicate_results$max_log_e >= threshold
    signal_rate <- mean(signal)
    monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
    crossing_times <- replicate_results$crossing_time_alpha_005[replicate_results$signal_alpha_005]

    data.frame(
      scenario = "step_angle_dependence",
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
      mean_feature_correlation = mean(replicate_results$feature_correlation),
      mean_crossing_time_alpha_005 = if (length(crossing_times) == 0L) NA_real_ else mean(crossing_times),
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s5_step_angle_dependence_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s5_step_angle_dependence_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s5_step_angle_dependence_paths.csv"),
  row.names = FALSE
)
write.csv(
  feature_results,
  file = file.path(output_table_dir, "s5_step_angle_dependence_features.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s5_step_angle_dependence_paths.png"),
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
  main = "S5: feature-level copula diagnostic for step-angle dependence"
)
for (replicate_index in unique(path_results$replicate)) {
  replicate_path <- path_results[path_results$replicate == replicate_index, ]
  lines(
    replicate_path$time,
    replicate_path$log_e_cumulative,
    col = grDevices::adjustcolor("darkorange3", alpha.f = 0.35),
    lwd = 1
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("sample paths", "alpha = 0.05 threshold"),
  col = c("darkorange3", "firebrick"),
  lwd = c(1, 2),
  lty = c(1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s5_step_angle_dependence_residuals.png"),
  width = 1200,
  height = 1200,
  res = 180
)
plot(
  feature_results$u_step,
  feature_results$u_angle_given_step,
  pch = 19,
  cex = 0.45,
  col = grDevices::adjustcolor("darkorange3", alpha.f = 0.35),
  xlab = "Rosenblatt residual for step length",
  ylab = "Rosenblatt residual for turning angle given step",
  main = "S5: residual dependence under the null transform"
)
abline(0, 1, col = "grey40", lty = 2)
dev.off()

message("S5 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
