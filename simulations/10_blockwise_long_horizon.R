# S10: Blockwise long-horizon diagnostics.
#
# This simulation targets a failure that is not expressed as a simple one-step
# density change. The diagnostic feature is block straightness, defined as net
# displacement divided by total path length within a block. Feature laws are
# fitted from independent simulations, then frozen before validation.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_duration.R")
source("R/diagnostics_long_horizon.R")

set.seed(20260517)

n_replicates <- 250L
block_size <- 60L
n_blocks <- 16L
n_times <- block_size * n_blocks
n_law_simulations <- 10000L
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

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
rho_by_state <- c(0.985, 0.965)

law_parameters <- fit_block_straightness_laws(
  parameters = null_parameters,
  rho_by_state = rho_by_state,
  block_size = block_size,
  n_simulations = n_law_simulations
)

scenario_names <- c("hmm_null", "angle_ar_long_horizon")
scenario_colours <- c(
  hmm_null = "steelblue3",
  angle_ar_long_horizon = "firebrick"
)

crossing_time_for_alpha <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

replicate_results <- vector("list", n_replicates * length(scenario_names))
block_results <- vector("list", n_replicates * length(scenario_names))
path_results <- vector("list", min(25L, n_replicates) * length(scenario_names))

result_index <- 1L
block_index <- 1L
path_index <- 1L

for (scenario in scenario_names) {
  for (replicate_index in seq_len(n_replicates)) {
    simulated_data <- if (scenario == "hmm_null") {
      simulate_hmm_movement(
        n_times = n_times,
        parameters = null_parameters,
        n_individuals = 1L
      )
    } else {
      simulate_hmm_movement_ar_angles(
        n_times = n_times,
        parameters = null_parameters,
        rho_by_state = rho_by_state,
        n_individuals = 1L
      )
    }

    diagnostic <- diagnostic_long_horizon_straightness(
      data = simulated_data,
      law_parameters = law_parameters,
      block_size = block_size,
      alpha = 0.05,
      diagnostic_name = "long_horizon_straightness",
      metadata = list(scenario = scenario)
    )

    crossing_times <- vapply(
      alphas,
      function(alpha) crossing_time_for_alpha(diagnostic$path, alpha),
      numeric(1)
    )
    summary <- summarise_predictive_diagnostic(diagnostic)

    replicate_row <- data.frame(
      scenario = scenario,
      replicate = replicate_index,
      n_times = n_times,
      block_size = block_size,
      n_blocks = n_blocks,
      n_law_simulations = n_law_simulations,
      max_log_e = summary$max_log_e,
      final_log_e = summary$final_log_e,
      mean_log_increment = summary$mean_log_increment,
      mean_straightness = mean(diagnostic$blocks$straightness),
      median_straightness = stats::median(diagnostic$blocks$straightness),
      min_straightness = min(diagnostic$blocks$straightness),
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

    block_results[[block_index]] <- data.frame(
      scenario = scenario,
      replicate = replicate_index,
      diagnostic$blocks,
      stringsAsFactors = FALSE
    )
    block_index <- block_index + 1L

    if (replicate_index <= 25L) {
      path_results[[path_index]] <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        time = diagnostic$path$time,
        block_id = seq_len(nrow(diagnostic$path)),
        log_e_cumulative = diagnostic$path$log_e_cumulative,
        log_e_increment = diagnostic$path$log_e_increment,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
block_results <- do.call(rbind, block_results)
path_results <- do.call(rbind, path_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    scenario_results <- replicate_results[replicate_results$scenario == scenario, ]
    do.call(
      rbind,
      lapply(seq_along(alphas), function(alpha_index) {
        alpha <- alphas[alpha_index]
        alpha_label <- alpha_labels[alpha_index]
        crossing_column <- paste0("crossing_time_alpha_", alpha_label)
        signal <- scenario_results$max_log_e >= log(1 / alpha)
        signal_rate <- mean(signal)
        crossing_times <- scenario_results[[crossing_column]]

        data.frame(
          scenario = scenario,
          alpha = alpha,
          threshold = log(1 / alpha),
          n_replicates = n_replicates,
          n_times = n_times,
          block_size = block_size,
          n_blocks = n_blocks,
          n_law_simulations = n_law_simulations,
          signal_rate = signal_rate,
          monte_carlo_se = sqrt(signal_rate * (1 - signal_rate) / n_replicates),
          signal_rate_minus_alpha = signal_rate - alpha,
          mean_max_log_e = mean(scenario_results$max_log_e),
          median_max_log_e = stats::median(scenario_results$max_log_e),
          mean_final_log_e = mean(scenario_results$final_log_e),
          median_final_log_e = stats::median(scenario_results$final_log_e),
          mean_log_increment = mean(scenario_results$mean_log_increment),
          mean_crossing_time = mean(crossing_times, na.rm = TRUE),
          mean_straightness = mean(scenario_results$mean_straightness),
          median_straightness = stats::median(scenario_results$median_straightness),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_

block_summary <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    scenario_blocks <- block_results[block_results$scenario == scenario, ]
    data.frame(
      scenario = scenario,
      mean_straightness = mean(scenario_blocks$straightness),
      median_straightness = stats::median(scenario_blocks$straightness),
      q10_straightness = unname(stats::quantile(scenario_blocks$straightness, probs = 0.10)),
      q90_straightness = unname(stats::quantile(scenario_blocks$straightness, probs = 0.90)),
      mean_log_e_increment = mean(scenario_blocks$log_e_increment),
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_replicates.csv"),
  row.names = FALSE
)
write.csv(
  block_results,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_blocks.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_paths.csv"),
  row.names = FALSE
)
write.csv(
  law_parameters,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_laws.csv"),
  row.names = FALSE
)
write.csv(
  block_summary,
  file = file.path(output_table_dir, "s10_blockwise_long_horizon_block_summary.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s10_blockwise_long_horizon_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
y_range <- range(c(path_results$log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = range(path_results$block_id),
  ylim = y_range,
  xlab = "Block",
  ylab = "Cumulative log e-value",
  main = "S10: blockwise long-horizon diagnostic paths"
)
for (scenario in scenario_names) {
  scenario_paths <- path_results[path_results$scenario == scenario, ]
  for (replicate_index in unique(scenario_paths$replicate)) {
    replicate_path <- scenario_paths[scenario_paths$replicate == replicate_index, ]
    lines(
      replicate_path$block_id,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(scenario_colours[[scenario]], alpha.f = 0.25),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c(scenario_names, "alpha = 0.05 threshold"),
  col = c(unname(scenario_colours), "black"),
  lwd = c(rep(2, length(scenario_names)), 2),
  lty = c(rep(1, length(scenario_names)), 2),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s10_blockwise_long_horizon_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
barplot(
  height = alpha_005_summary$signal_rate,
  names.arg = alpha_005_summary$scenario,
  las = 2,
  ylim = c(0, max(0.85, alpha_005_summary$signal_rate)),
  col = unname(scenario_colours[alpha_005_summary$scenario]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S10: signal rates for blockwise straightness diagnostic",
  cex.names = 0.90
)
abline(h = 0.05, col = "black", lty = 2, lwd = 2)
dev.off()

png(
  filename = file.path(output_figure_dir, "s10_blockwise_long_horizon_straightness.png"),
  width = 1800,
  height = 1100,
  res = 180
)
hist(
  block_results$straightness[block_results$scenario == "hmm_null"],
  breaks = 40,
  col = grDevices::adjustcolor(scenario_colours[["hmm_null"]], alpha.f = 0.45),
  border = "white",
  xlim = range(block_results$straightness),
  xlab = "Block straightness",
  main = "S10: block straightness under null and long-horizon alternative"
)
hist(
  block_results$straightness[block_results$scenario == "angle_ar_long_horizon"],
  breaks = 40,
  col = grDevices::adjustcolor(scenario_colours[["angle_ar_long_horizon"]], alpha.f = 0.45),
  border = "white",
  add = TRUE
)
legend(
  "topright",
  legend = scenario_names,
  fill = unname(scenario_colours[scenario_names]),
  bty = "n"
)
dev.off()

message("S10 completed. Summary:")
print(summary_by_alpha)
message("Block summary:")
print(block_summary)
message("Feature law parameters:")
print(law_parameters)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
