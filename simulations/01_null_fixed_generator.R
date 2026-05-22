# S1: Null fixed-generator calibration.
# This simulation verifies that a predictive e-process has controlled false-signal
# behaviour when validation data are generated from the fixed null HMM.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")

set.seed(20260507)

# Simulation controls. Keep these modest so the script is quick in a clean run.
n_replicates <- 1000L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

null_parameters <- create_hmm_movement_parameters()

# A fixed diagnostic competitor. It is intentionally misspecified but is a valid
# predictive density chosen before validation, so q_t / p_t is an e-increment.
diagnostic_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.55, 0.45),
  transition_matrix = matrix(c(0.86, 0.14, 0.18, 0.82), nrow = 2, byrow = TRUE),
  step_shape = c(2.5, 6.0),
  step_rate = c(3.2, 1.7),
  angle_mean = c(0.15, -0.10),
  angle_sd = c(1.25, 0.55)
)

replicate_results <- vector("list", n_replicates)
path_results <- vector("list", min(25L, n_replicates))

for (replicate_index in seq_len(n_replicates)) {
  simulated_data <- simulate_hmm_movement(
    n_times = n_times,
    parameters = null_parameters,
    n_individuals = 1L
  )

  log_p0 <- hmm_movement_predictive_log_density(
    data = simulated_data,
    parameters = null_parameters
  )
  log_q <- hmm_movement_predictive_log_density(
    data = simulated_data,
    parameters = diagnostic_parameters
  )

  eprocess <- compute_eprocess(
    log_p0 = log_p0,
    log_p1 = log_q,
    alpha = 0.05,
    time = simulated_data$time
  )

  max_log_e <- max(eprocess$path$log_e_cumulative)
  final_log_e <- tail(eprocess$path$log_e_cumulative, 1L)

  replicate_results[[replicate_index]] <- data.frame(
    replicate = replicate_index,
    max_log_e = max_log_e,
    final_log_e = final_log_e,
    mean_log_increment = mean(eprocess$path$log_e_increment),
    stringsAsFactors = FALSE
  )

  if (replicate_index <= length(path_results)) {
    path_results[[replicate_index]] <- data.frame(
      replicate = replicate_index,
      time = eprocess$path$time,
      log_e_cumulative = eprocess$path$log_e_cumulative,
      log_e_increment = eprocess$path$log_e_increment,
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
    false_signal_rate <- mean(signal)
    monte_carlo_se <- sqrt(false_signal_rate * (1 - false_signal_rate) / n_replicates)

    data.frame(
      scenario = "null_fixed_generator",
      alpha = alpha,
      threshold = threshold,
      n_replicates = n_replicates,
      n_times = n_times,
      false_signal_rate = false_signal_rate,
      monte_carlo_se = monte_carlo_se,
      mean_max_log_e = mean(replicate_results$max_log_e),
      median_max_log_e = stats::median(replicate_results$max_log_e),
      mean_final_log_e = mean(replicate_results$final_log_e),
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s1_null_fixed_generator_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s1_null_fixed_generator_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s1_null_fixed_generator_paths.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s1_null_fixed_generator_paths.png"),
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
  main = "S1: null fixed-generator calibration paths"
)
for (replicate_index in unique(path_results$replicate)) {
  replicate_path <- path_results[path_results$replicate == replicate_index, ]
  lines(
    replicate_path$time,
    replicate_path$log_e_cumulative,
    col = grDevices::adjustcolor("steelblue", alpha.f = 0.35),
    lwd = 1
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("sample paths", "alpha = 0.05 threshold"),
  col = c("steelblue", "firebrick"),
  lwd = c(1, 2),
  lty = c(1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s1_null_fixed_generator_max_log_e.png"),
  width = 1800,
  height = 1100,
  res = 180
)
hist(
  replicate_results$max_log_e,
  breaks = 35,
  col = "grey85",
  border = "white",
  xlab = "Maximum cumulative log e-value",
  main = "S1: distribution of maximum log e-process under the null"
)
abline(v = log(1 / alphas), col = c("orange3", "firebrick", "darkred"), lwd = 2, lty = 2)
legend(
  "topright",
  legend = paste0("alpha = ", alphas),
  col = c("orange3", "firebrick", "darkred"),
  lwd = 2,
  lty = 2,
  bty = "n"
)
dev.off()

message("S1 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
