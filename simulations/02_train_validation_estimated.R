# S2: Train/validation with estimated parameters.
#
# The fitted null and the diagnostic competitor are constructed on training data,
# then frozen before validation. In this first controlled version, training uses
# the simulated state labels through estimate_hmm_movement_oracle(). This isolates
# the train/validation logic before introducing a full hidden-state HMM fitter.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/estimate_hmm_training.R")

set.seed(20260515)

n_replicates <- 300L
n_train_individuals <- 12L
n_train_times <- 250L
n_validation_times <- 300L
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

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
  angle_sd = c(0.85, 0.30)
)

known_diagnostic_parameters <- perturb_hmm_movement_parameters(
  parameters = true_parameters,
  step_mean_multiplier = c(1.10, 0.90),
  angle_mean_shift = c(0.15, -0.12),
  angle_sd_multiplier = c(1.15, 1.25),
  transition_blend = 0.08,
  initial_blend = 0.03
)

scenario_names <- c(
  "known_parameters",
  "estimated_true_null",
  "estimated_fitted_null"
)
validation_generator <- c(
  known_parameters = "true_hmm",
  estimated_true_null = "true_hmm",
  estimated_fitted_null = "fitted_hmm"
)
parameter_source <- c(
  known_parameters = "known",
  estimated_true_null = "oracle_estimated",
  estimated_fitted_null = "oracle_estimated"
)
scenario_colours <- c(
  known_parameters = "steelblue3",
  estimated_true_null = "darkorange3",
  estimated_fitted_null = "darkgreen"
)

crossing_time_for_alpha <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

evaluate_validation_sequence <- function(data, null_parameters, diagnostic_parameters) {
  log_p0 <- hmm_movement_predictive_log_density(
    data = data,
    parameters = null_parameters
  )
  log_q <- hmm_movement_predictive_log_density(
    data = data,
    parameters = diagnostic_parameters
  )
  compute_eprocess(
    log_p0 = log_p0,
    log_p1 = log_q,
    alpha = 0.05,
    time = data$time
  )
}

replicate_results <- vector("list", n_replicates * length(scenario_names))
path_results <- vector("list", min(20L, n_replicates) * length(scenario_names))
parameter_error_results <- vector("list", n_replicates)

result_index <- 1L
path_index <- 1L

for (replicate_index in seq_len(n_replicates)) {
  training_data <- simulate_hmm_movement(
    n_times = n_train_times,
    parameters = true_parameters,
    n_individuals = n_train_individuals
  )
  estimated_parameters <- estimate_hmm_movement_oracle(
    data = training_data,
    n_states = length(true_parameters$initial_probs)
  )
  estimated_diagnostic_parameters <- perturb_hmm_movement_parameters(
    parameters = estimated_parameters,
    step_mean_multiplier = c(1.10, 0.90),
    angle_mean_shift = c(0.15, -0.12),
    angle_sd_multiplier = c(1.15, 1.25),
    transition_blend = 0.08,
    initial_blend = 0.03
  )

  parameter_error_results[[replicate_index]] <- cbind(
    data.frame(replicate = replicate_index),
    summarise_hmm_parameter_error(
      estimated_parameters = estimated_parameters,
      true_parameters = true_parameters
    )
  )

  true_validation_data <- simulate_hmm_movement(
    n_times = n_validation_times,
    parameters = true_parameters,
    n_individuals = 1L
  )
  fitted_validation_data <- simulate_hmm_movement(
    n_times = n_validation_times,
    parameters = estimated_parameters,
    n_individuals = 1L
  )

  scenario_inputs <- list(
    known_parameters = list(
      data = true_validation_data,
      null_parameters = true_parameters,
      diagnostic_parameters = known_diagnostic_parameters
    ),
    estimated_true_null = list(
      data = true_validation_data,
      null_parameters = estimated_parameters,
      diagnostic_parameters = estimated_diagnostic_parameters
    ),
    estimated_fitted_null = list(
      data = fitted_validation_data,
      null_parameters = estimated_parameters,
      diagnostic_parameters = estimated_diagnostic_parameters
    )
  )

  for (scenario in scenario_names) {
    diagnostic <- evaluate_validation_sequence(
      data = scenario_inputs[[scenario]]$data,
      null_parameters = scenario_inputs[[scenario]]$null_parameters,
      diagnostic_parameters = scenario_inputs[[scenario]]$diagnostic_parameters
    )

    crossing_times <- vapply(
      alphas,
      function(alpha) crossing_time_for_alpha(diagnostic$path, alpha),
      numeric(1)
    )

    replicate_row <- data.frame(
      scenario = scenario,
      replicate = replicate_index,
      validation_generator = validation_generator[[scenario]],
      parameter_source = parameter_source[[scenario]],
      max_log_e = max(diagnostic$path$log_e_cumulative),
      final_log_e = tail(diagnostic$path$log_e_cumulative, 1L),
      mean_log_increment = mean(diagnostic$path$log_e_increment),
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

    if (replicate_index <= 20L) {
      path_results[[path_index]] <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        validation_generator = validation_generator[[scenario]],
        parameter_source = parameter_source[[scenario]],
        time = diagnostic$path$time,
        log_e_cumulative = diagnostic$path$log_e_cumulative,
        log_e_increment = diagnostic$path$log_e_increment,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)
parameter_error_results <- do.call(rbind, parameter_error_results)

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
          validation_generator = validation_generator[[scenario]],
          parameter_source = parameter_source[[scenario]],
          alpha = alpha,
          threshold = threshold,
          n_replicates = n_replicates,
          n_train_individuals = n_train_individuals,
          n_train_times = n_train_times,
          n_validation_times = n_validation_times,
          signal_rate = signal_rate,
          monte_carlo_se = monte_carlo_se,
          signal_rate_minus_alpha = signal_rate - alpha,
          mean_max_log_e = mean(scenario_results$max_log_e),
          median_max_log_e = stats::median(scenario_results$max_log_e),
          mean_final_log_e = mean(scenario_results$final_log_e),
          median_final_log_e = stats::median(scenario_results$final_log_e),
          mean_crossing_time = mean(crossing_times, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_

parameter_error_summary <- data.frame(
  metric = names(parameter_error_results)[names(parameter_error_results) != "replicate"],
  mean = vapply(
    parameter_error_results[names(parameter_error_results) != "replicate"],
    mean,
    numeric(1)
  ),
  median = vapply(
    parameter_error_results[names(parameter_error_results) != "replicate"],
    stats::median,
    numeric(1)
  ),
  q95 = vapply(
    parameter_error_results[names(parameter_error_results) != "replicate"],
    stats::quantile,
    numeric(1),
    probs = 0.95
  ),
  stringsAsFactors = FALSE
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s2_train_validation_estimated_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s2_train_validation_estimated_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s2_train_validation_estimated_paths.csv"),
  row.names = FALSE
)
write.csv(
  parameter_error_results,
  file = file.path(output_table_dir, "s2_train_validation_estimated_parameter_errors.csv"),
  row.names = FALSE
)
write.csv(
  parameter_error_summary,
  file = file.path(output_table_dir, "s2_train_validation_estimated_parameter_error_summary.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s2_train_validation_estimated_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
y_range <- range(c(path_results$log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = range(path_results$time),
  ylim = y_range,
  xlab = "Validation time",
  ylab = "Cumulative log e-value",
  main = "S2: train/validation e-process paths"
)
for (scenario in scenario_names) {
  scenario_paths <- path_results[path_results$scenario == scenario, ]
  for (replicate_index in unique(scenario_paths$replicate)) {
    replicate_path <- scenario_paths[scenario_paths$replicate == replicate_index, ]
    lines(
      replicate_path$time,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(scenario_colours[[scenario]], alpha.f = 0.25),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "bottomleft",
  legend = c(scenario_names, "alpha = 0.05 threshold"),
  col = c(unname(scenario_colours), "black"),
  lwd = c(rep(2, length(scenario_names)), 2),
  lty = c(rep(1, length(scenario_names)), 2),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s2_train_validation_estimated_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
barplot(
  height = alpha_005_summary$signal_rate,
  names.arg = alpha_005_summary$scenario,
  las = 2,
  ylim = c(0, max(0.16, alpha_005_summary$signal_rate)),
  col = unname(scenario_colours[alpha_005_summary$scenario]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S2: known versus estimated train/validation",
  cex.names = 0.85
)
abline(h = 0.05, col = "black", lty = 2, lwd = 2)
dev.off()

png(
  filename = file.path(output_figure_dir, "s2_train_validation_estimated_parameter_errors.png"),
  width = 1800,
  height = 1100,
  res = 180
)
error_metrics <- c(
  "initial_l1_error",
  "transition_frobenius_error",
  "step_mean_rmse",
  "angle_mean_mae",
  "angle_sd_rmse"
)
boxplot(
  parameter_error_results[, error_metrics],
  las = 2,
  col = "grey85",
  border = "grey30",
  ylab = "Error",
  main = "S2: oracle training parameter errors"
)
dev.off()

message("S2 completed. Summary:")
print(summary_by_alpha)
message("Parameter error summary:")
print(parameter_error_summary)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
