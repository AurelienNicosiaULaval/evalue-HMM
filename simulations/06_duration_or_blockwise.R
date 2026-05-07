# S6: Duration misspecification through a blockwise observable feature.
# The diagnostic uses the number of switches of a pre-specified long-step
# indicator inside each block. This targets non-geometric behavioural persistence
# without treating latent state durations as observed.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_duration.R")

set.seed(20260512)

n_replicates <- 250L
n_times <- 300L
block_size <- 30L
n_simulations <- 600L
pseudo_count <- 1
step_threshold <- 2.0
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

null_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.50, 0.50),
  transition_matrix = matrix(c(0.78, 0.22, 0.18, 0.82), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 12.0),
  step_rate = c(5.0, 2.4),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(1.20, 0.35)
)

# The alternative has the same state-specific emission distributions, but longer
# non-geometric dwell times than the geometric durations implied by the HMM.
alternative_dwell_mean <- c(18, 18)
alternative_dwell_size <- c(12, 12)

scenario_names <- c("hmm_null", "hsmm_duration")
scenario_colours <- c(hmm_null = "grey35", hsmm_duration = "darkorange3")

crossing_time_for_alpha <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

replicate_results <- vector("list", n_replicates * length(scenario_names))
path_results <- vector("list", min(25L, n_replicates) * length(scenario_names))
block_results <- vector("list", min(25L, n_replicates) * length(scenario_names))

result_index <- 1L
path_index <- 1L
block_index <- 1L

for (scenario in scenario_names) {
  for (replicate_index in seq_len(n_replicates)) {
    simulated_data <- if (scenario == "hmm_null") {
      simulate_hmm_movement(
        n_times = n_times,
        parameters = null_parameters,
        n_individuals = 1L
      )
    } else {
      simulate_hsmm_movement(
        n_times = n_times,
        parameters = null_parameters,
        dwell_mean = alternative_dwell_mean,
        dwell_size = alternative_dwell_size,
        n_individuals = 1L
      )
    }

    diagnostic <- diagnostic_duration_blockwise(
      data = simulated_data,
      null_parameters = null_parameters,
      dwell_mean = alternative_dwell_mean,
      dwell_size = alternative_dwell_size,
      step_threshold = step_threshold,
      block_size = block_size,
      n_simulations = n_simulations,
      pseudo_count = pseudo_count,
      alpha = 0.05,
      diagnostic_name = "duration_blockwise_switch_count",
      metadata = list(scenario = scenario)
    )

    summary <- summarise_predictive_diagnostic(diagnostic)
    crossing_times <- vapply(
      alphas,
      function(alpha) crossing_time_for_alpha(diagnostic$path, alpha),
      numeric(1)
    )

    replicate_row <- data.frame(
      scenario = scenario,
      replicate = replicate_index,
      max_log_e = summary$max_log_e,
      final_log_e = summary$final_log_e,
      mean_log_increment = summary$mean_log_increment,
      mean_observed_switches = mean(diagnostic$blocks$observed_switches),
      mean_expected_null_switches = mean(diagnostic$blocks$expected_null_switches),
      mean_expected_alternative_switches = mean(diagnostic$blocks$expected_alternative_switches),
      mean_true_state_switches = sum(simulated_data$state[-1L] != simulated_data$state[-nrow(simulated_data)]) /
        (nrow(simulated_data) - 1L),
      stringsAsFactors = FALSE
    )
    for (alpha_index in seq_along(alphas)) {
      crossing_column <- paste0("crossing_time_alpha_", alpha_labels[alpha_index])
      signal_column <- paste0("signal_alpha_", alpha_labels[alpha_index])
      replicate_row[[crossing_column]] <- crossing_times[alpha_index]
      replicate_row[[signal_column]] <- !is.na(crossing_times[alpha_index])
    }
    replicate_results[[result_index]] <- replicate_row
    result_index <- result_index + 1L

    if (replicate_index <= 25L) {
      path_results[[path_index]] <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        block_id = seq_len(nrow(diagnostic$path)),
        time = diagnostic$path$time,
        log_e_cumulative = diagnostic$path$log_e_cumulative,
        log_e_increment = diagnostic$path$log_e_increment,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L

      block_results[[block_index]] <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        diagnostic$blocks,
        stringsAsFactors = FALSE
      )
      block_index <- block_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)
block_results <- do.call(rbind, block_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    scenario_results <- replicate_results[replicate_results$scenario == scenario, ]
    do.call(
      rbind,
      lapply(alphas, function(alpha) {
        alpha_label <- alpha_labels[which(alphas == alpha)]
        crossing_column <- paste0("crossing_time_alpha_", alpha_label)
        threshold <- log(1 / alpha)
        signal <- scenario_results$max_log_e >= threshold
        signal_rate <- mean(signal)
        monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
        crossing_times <- scenario_results[[crossing_column]]

        data.frame(
          scenario = scenario,
          alpha = alpha,
          threshold = threshold,
          n_replicates = n_replicates,
          n_times = n_times,
          block_size = block_size,
          n_blocks = n_times / block_size,
          n_simulations = n_simulations,
          step_threshold = step_threshold,
          signal_rate = signal_rate,
          monte_carlo_se = monte_carlo_se,
          mean_max_log_e = mean(scenario_results$max_log_e),
          median_max_log_e = stats::median(scenario_results$max_log_e),
          mean_final_log_e = mean(scenario_results$final_log_e),
          median_final_log_e = stats::median(scenario_results$final_log_e),
          mean_crossing_time = mean(crossing_times, na.rm = TRUE),
          mean_observed_switches = mean(scenario_results$mean_observed_switches),
          mean_expected_null_switches = mean(scenario_results$mean_expected_null_switches),
          mean_expected_alternative_switches = mean(scenario_results$mean_expected_alternative_switches),
          mean_true_state_switch_rate = mean(scenario_results$mean_true_state_switches),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s6_duration_blockwise_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s6_duration_blockwise_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s6_duration_blockwise_paths.csv"),
  row.names = FALSE
)
write.csv(
  block_results,
  file = file.path(output_table_dir, "s6_duration_blockwise_blocks.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s6_duration_blockwise_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
y_range <- range(c(path_results$log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = range(path_results$time),
  ylim = y_range,
  xlab = "Time",
  ylab = "Cumulative log e-value",
  main = "S6: blockwise duration diagnostic"
)
for (scenario in scenario_names) {
  scenario_paths <- path_results[path_results$scenario == scenario, ]
  for (replicate_index in unique(scenario_paths$replicate)) {
    replicate_path <- scenario_paths[scenario_paths$replicate == replicate_index, ]
    lines(
      replicate_path$time,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(scenario_colours[[scenario]], alpha.f = 0.35),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("HMM null", "HSMM duration", "alpha = 0.05 threshold"),
  col = c(unname(scenario_colours), "firebrick"),
  lwd = c(2, 2, 2),
  lty = c(1, 1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s6_duration_blockwise_switch_counts.png"),
  width = 1800,
  height = 1100,
  res = 180
)
switch_values <- split(block_results$observed_switches, block_results$scenario)
boxplot(
  switch_values,
  col = unname(scenario_colours[names(switch_values)]),
  ylab = "Observed long-step switches per block",
  main = "S6: duration misspecification reduces observable switching"
)
abline(
  h = mean(block_results$expected_null_switches),
  col = "grey20",
  lty = 2,
  lwd = 2
)
abline(
  h = mean(block_results$expected_alternative_switches),
  col = "darkorange4",
  lty = 2,
  lwd = 2
)
legend(
  "topright",
  legend = c("mean null expectation", "mean alternative expectation"),
  col = c("grey20", "darkorange4"),
  lty = 2,
  lwd = 2,
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s6_duration_blockwise_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
barplot(
  height = alpha_005_summary$signal_rate,
  names.arg = alpha_005_summary$scenario,
  ylim = c(0, 1),
  col = unname(scenario_colours[alpha_005_summary$scenario]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S6: blockwise duration signal rates"
)
abline(h = 0.05, col = "firebrick", lty = 2, lwd = 2)
dev.off()

message("S6 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
