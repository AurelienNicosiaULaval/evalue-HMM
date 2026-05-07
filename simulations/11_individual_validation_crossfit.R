# S11: Individual validation and cross-fitted average.
#
# This simulation follows the article's recommendation for independent
# validation units. Each held-out individual is evaluated using a model fitted
# without that individual's validation responses. The default global summary is
# a weighted average of final individual e-values, not a product across folds.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/estimate_hmm_training.R")

set.seed(20260516)

n_replicates <- 250L
n_individuals <- 8L
n_times <- 220L
failure_individual <- 1L
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

scenario_names <- c(
  "true_null_crossfit",
  "fitted_null_crossfit",
  "single_failed_individual"
)
method_names <- c(
  "crossfit_average_final",
  "any_individual_eprocess",
  "naive_final_product"
)
method_status <- c(
  crossfit_average_final = "valid_final_average_evalue",
  any_individual_eprocess = "exploratory_multiple_individual_scan",
  naive_final_product = "not_valid_by_default"
)
method_colours <- c(
  crossfit_average_final = "darkgreen",
  any_individual_eprocess = "steelblue3",
  naive_final_product = "firebrick"
)
scenario_colours <- c(
  true_null_crossfit = "steelblue3",
  fitted_null_crossfit = "darkgreen",
  single_failed_individual = "firebrick"
)

individual_weights <- rep(1 / n_individuals, n_individuals)

log_weighted_average <- function(log_values, weights) {
  if (length(log_values) != length(weights)) {
    stop("`log_values` and `weights` must have the same length.", call. = FALSE)
  }
  if (any(!is.finite(log_values)) || any(!is.finite(weights))) {
    stop("`log_values` and `weights` must be finite.", call. = FALSE)
  }
  if (any(weights < 0) || sum(weights) <= 0 || sum(weights) > 1 + sqrt(.Machine$double.eps)) {
    stop("`weights` must be non-negative and sum to at most 1.", call. = FALSE)
  }

  positive <- weights > 0
  log_values <- log_values[positive]
  weights <- weights[positive]
  normalizer <- max(log_values)
  normalizer + log(sum(weights * exp(log_values - normalizer)))
}

crossing_time_for_path <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

evaluate_individual <- function(data, null_parameters, diagnostic_parameters) {
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

make_fold_diagnostic_parameters <- function(parameters) {
  perturb_hmm_movement_parameters(
    parameters = parameters,
    step_mean_multiplier = c(1.10, 0.90),
    angle_mean_shift = c(0.15, -0.12),
    angle_sd_multiplier = c(1.15, 1.25),
    transition_blend = 0.08,
    initial_blend = 0.03
  )
}

make_average_path <- function(individual_log_path_matrix, weights) {
  log_average <- vapply(
    seq_len(nrow(individual_log_path_matrix)),
    function(time_index) log_weighted_average(individual_log_path_matrix[time_index, ], weights),
    numeric(1)
  )

  data.frame(
    time = seq_len(nrow(individual_log_path_matrix)),
    log_e_cumulative = log_average,
    log_e_increment = c(log_average[1L], diff(log_average)),
    stringsAsFactors = FALSE
  )
}

replicate_results <- vector("list", n_replicates * length(scenario_names) * length(method_names))
individual_results <- vector("list", n_replicates * length(scenario_names) * n_individuals)
path_results <- vector("list", min(20L, n_replicates) * length(scenario_names) * (n_individuals + 1L))

result_index <- 1L
individual_index <- 1L
path_index <- 1L

for (replicate_index in seq_len(n_replicates)) {
  estimation_panel <- simulate_hmm_movement(
    n_times = n_times,
    parameters = true_parameters,
    n_individuals = n_individuals
  )

  fold_null_parameters <- vector("list", n_individuals)
  fold_diagnostic_parameters <- vector("list", n_individuals)

  for (held_out_id in seq_len(n_individuals)) {
    training_data <- estimation_panel[estimation_panel$individual_id != held_out_id, ]
    fold_null_parameters[[held_out_id]] <- estimate_hmm_movement_oracle(
      data = training_data,
      n_states = length(true_parameters$initial_probs)
    )
    fold_diagnostic_parameters[[held_out_id]] <- make_fold_diagnostic_parameters(
      fold_null_parameters[[held_out_id]]
    )
  }

  for (scenario in scenario_names) {
    individual_paths <- vector("list", n_individuals)
    final_log_e_by_individual <- numeric(n_individuals)
    max_log_e_by_individual <- numeric(n_individuals)
    crossing_time_matrix <- matrix(
      NA_real_,
      nrow = n_individuals,
      ncol = length(alphas),
      dimnames = list(NULL, alpha_labels)
    )
    generated_from <- character(n_individuals)

    for (held_out_id in seq_len(n_individuals)) {
      if (scenario == "true_null_crossfit") {
        validation_data <- estimation_panel[estimation_panel$individual_id == held_out_id, ]
        generated_from[held_out_id] <- "true_hmm"
      } else if (scenario == "fitted_null_crossfit") {
        validation_data <- simulate_hmm_movement(
          n_times = n_times,
          parameters = fold_null_parameters[[held_out_id]],
          n_individuals = 1L
        )
        generated_from[held_out_id] <- "fitted_hmm"
      } else if (scenario == "single_failed_individual" && held_out_id == failure_individual) {
        validation_data <- simulate_hmm_movement(
          n_times = n_times,
          parameters = fold_diagnostic_parameters[[held_out_id]],
          n_individuals = 1L
        )
        generated_from[held_out_id] <- "diagnostic_alternative"
      } else {
        validation_data <- simulate_hmm_movement(
          n_times = n_times,
          parameters = fold_null_parameters[[held_out_id]],
          n_individuals = 1L
        )
        generated_from[held_out_id] <- "fitted_hmm"
      }
      validation_data$individual_id <- held_out_id

      diagnostic <- evaluate_individual(
        data = validation_data,
        null_parameters = fold_null_parameters[[held_out_id]],
        diagnostic_parameters = fold_diagnostic_parameters[[held_out_id]]
      )

      individual_paths[[held_out_id]] <- diagnostic$path
      final_log_e_by_individual[held_out_id] <- tail(diagnostic$path$log_e_cumulative, 1L)
      max_log_e_by_individual[held_out_id] <- max(diagnostic$path$log_e_cumulative)

      crossing_times <- vapply(
        alphas,
        function(alpha) crossing_time_for_path(diagnostic$path, alpha),
        numeric(1)
      )
      crossing_time_matrix[held_out_id, ] <- crossing_times

      individual_row <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        individual_id = held_out_id,
        generated_from = generated_from[held_out_id],
        is_failed_individual = scenario == "single_failed_individual" &&
          held_out_id == failure_individual,
        max_log_e = max_log_e_by_individual[held_out_id],
        final_log_e = final_log_e_by_individual[held_out_id],
        mean_log_increment = mean(diagnostic$path$log_e_increment),
        stringsAsFactors = FALSE
      )
      for (alpha_index in seq_along(alphas)) {
        crossing_column <- paste0("crossing_time_alpha_", alpha_labels[alpha_index])
        signal_column <- paste0("signal_alpha_", alpha_labels[alpha_index])
        individual_row[[crossing_column]] <- crossing_times[alpha_index]
        individual_row[[signal_column]] <- !is.na(crossing_times[alpha_index])
      }
      individual_results[[individual_index]] <- individual_row
      individual_index <- individual_index + 1L

      if (replicate_index <= 20L) {
        path_results[[path_index]] <- data.frame(
          scenario = scenario,
          replicate = replicate_index,
          method = "individual_eprocess",
          individual_id = held_out_id,
          time = diagnostic$path$time,
          log_e_cumulative = diagnostic$path$log_e_cumulative,
          log_e_increment = diagnostic$path$log_e_increment,
          stringsAsFactors = FALSE
        )
        path_index <- path_index + 1L
      }
    }

    individual_log_path_matrix <- do.call(
      cbind,
      lapply(individual_paths, function(path) path$log_e_cumulative)
    )
    average_path <- make_average_path(
      individual_log_path_matrix = individual_log_path_matrix,
      weights = individual_weights
    )
    final_average_log_e <- tail(average_path$log_e_cumulative, 1L)
    final_product_log_e <- sum(final_log_e_by_individual)
    top_individual <- which.max(final_log_e_by_individual)

    if (replicate_index <= 20L) {
      path_results[[path_index]] <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        method = "crossfit_average_final",
        individual_id = NA_integer_,
        time = average_path$time,
        log_e_cumulative = average_path$log_e_cumulative,
        log_e_increment = average_path$log_e_increment,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L
    }

    for (method in method_names) {
      if (method == "crossfit_average_final") {
        method_log_path <- average_path$log_e_cumulative
        method_final_log_e <- final_average_log_e
        method_max_log_e <- max(method_log_path)
        method_detection_time <- rep(NA_real_, length(alphas))
        method_signals <- final_average_log_e >= log(1 / alphas)
        method_detection_time[method_signals] <- n_times
      } else if (method == "any_individual_eprocess") {
        method_final_log_e <- max(final_log_e_by_individual)
        method_max_log_e <- max(max_log_e_by_individual)
        method_signals <- vapply(
          alphas,
          function(alpha) any(max_log_e_by_individual >= log(1 / alpha)),
          logical(1)
        )
        method_detection_time <- vapply(
          seq_along(alphas),
          function(alpha_index) {
            crossing_times <- crossing_time_matrix[, alpha_index]
            if (all(is.na(crossing_times))) {
              return(NA_real_)
            }
            min(crossing_times, na.rm = TRUE)
          },
          numeric(1)
        )
      } else {
        method_final_log_e <- final_product_log_e
        method_max_log_e <- NA_real_
        method_detection_time <- rep(NA_real_, length(alphas))
        method_signals <- final_product_log_e >= log(1 / alphas)
        method_detection_time[method_signals] <- n_times
      }

      replicate_row <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        method = method,
        method_status = method_status[[method]],
        n_individuals = n_individuals,
        n_times = n_times,
        failure_individual = if (scenario == "single_failed_individual") failure_individual else NA_integer_,
        final_log_e = method_final_log_e,
        max_log_e = method_max_log_e,
        mean_individual_final_log_e = mean(final_log_e_by_individual),
        max_individual_final_log_e = max(final_log_e_by_individual),
        max_individual_path_log_e = max(max_log_e_by_individual),
        top_individual_id = top_individual,
        failed_individual_final_log_e = if (scenario == "single_failed_individual") {
          final_log_e_by_individual[failure_individual]
        } else {
          NA_real_
        },
        stringsAsFactors = FALSE
      )
      for (alpha_index in seq_along(alphas)) {
        crossing_column <- paste0("detection_time_alpha_", alpha_labels[alpha_index])
        signal_column <- paste0("signal_alpha_", alpha_labels[alpha_index])
        replicate_row[[crossing_column]] <- method_detection_time[alpha_index]
        replicate_row[[signal_column]] <- method_signals[alpha_index]
      }
      replicate_results[[result_index]] <- replicate_row
      result_index <- result_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
individual_results <- do.call(rbind, individual_results)
path_results <- do.call(rbind, path_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    do.call(
      rbind,
      lapply(method_names, function(method) {
        method_results <- replicate_results[
          replicate_results$scenario == scenario & replicate_results$method == method,
        ]
        do.call(
          rbind,
          lapply(seq_along(alphas), function(alpha_index) {
            alpha <- alphas[alpha_index]
            alpha_label <- alpha_labels[alpha_index]
            signal_column <- paste0("signal_alpha_", alpha_label)
            detection_column <- paste0("detection_time_alpha_", alpha_label)
            signal_rate <- mean(method_results[[signal_column]])
            detection_times <- method_results[[detection_column]]

            data.frame(
              scenario = scenario,
              method = method,
              method_status = method_status[[method]],
              alpha = alpha,
              threshold = log(1 / alpha),
              n_replicates = n_replicates,
              n_individuals = n_individuals,
              n_times = n_times,
              signal_rate = signal_rate,
              monte_carlo_se = sqrt(signal_rate * (1 - signal_rate) / n_replicates),
              signal_rate_minus_alpha = signal_rate - alpha,
              mean_final_log_e = mean(method_results$final_log_e),
              median_final_log_e = stats::median(method_results$final_log_e),
              mean_max_log_e = mean(method_results$max_log_e, na.rm = TRUE),
              mean_detection_time = mean(detection_times, na.rm = TRUE),
              mean_failed_individual_final_log_e = mean(
                method_results$failed_individual_final_log_e,
                na.rm = TRUE
              ),
              stringsAsFactors = FALSE
            )
          })
        )
      })
    )
  })
)
summary_by_alpha$mean_detection_time[is.nan(summary_by_alpha$mean_detection_time)] <- NA_real_
summary_by_alpha$mean_max_log_e[is.nan(summary_by_alpha$mean_max_log_e)] <- NA_real_
summary_by_alpha$mean_failed_individual_final_log_e[
  is.nan(summary_by_alpha$mean_failed_individual_final_log_e)
] <- NA_real_

individual_summary <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    scenario_individuals <- individual_results[individual_results$scenario == scenario, ]
    data.frame(
      scenario = scenario,
      n_replicates = n_replicates,
      n_individuals = n_individuals,
      mean_final_log_e = mean(scenario_individuals$final_log_e),
      median_final_log_e = stats::median(scenario_individuals$final_log_e),
      mean_max_log_e = mean(scenario_individuals$max_log_e),
      signal_fraction_alpha_005 = mean(scenario_individuals$signal_alpha_005),
      failed_individual_signal_alpha_005 = if (scenario == "single_failed_individual") {
        mean(scenario_individuals$signal_alpha_005[scenario_individuals$is_failed_individual])
      } else {
        NA_real_
      },
      unaffected_signal_alpha_005 = if (scenario == "single_failed_individual") {
        mean(scenario_individuals$signal_alpha_005[!scenario_individuals$is_failed_individual])
      } else {
        NA_real_
      },
      stringsAsFactors = FALSE
    )
  })
)

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s11_individual_validation_crossfit_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s11_individual_validation_crossfit_replicates.csv"),
  row.names = FALSE
)
write.csv(
  individual_results,
  file = file.path(output_table_dir, "s11_individual_validation_crossfit_individuals.csv"),
  row.names = FALSE
)
write.csv(
  individual_summary,
  file = file.path(output_table_dir, "s11_individual_validation_crossfit_individual_summary.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s11_individual_validation_crossfit_paths.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s11_individual_validation_crossfit_average_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
average_paths <- path_results[path_results$method == "crossfit_average_final", ]
y_range <- range(c(average_paths$log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = range(average_paths$time),
  ylim = y_range,
  xlab = "Validation time",
  ylab = "Log weighted average e-value",
  main = "S11: cross-fitted average paths by scenario"
)
for (scenario in scenario_names) {
  scenario_paths <- average_paths[average_paths$scenario == scenario, ]
  for (replicate_index in unique(scenario_paths$replicate)) {
    replicate_path <- scenario_paths[scenario_paths$replicate == replicate_index, ]
    lines(
      replicate_path$time,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(scenario_colours[[scenario]], alpha.f = 0.28),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c(scenario_names, "alpha = 0.05 final threshold"),
  col = c(unname(scenario_colours), "black"),
  lwd = c(rep(2, length(scenario_names)), 2),
  lty = c(rep(1, length(scenario_names)), 2),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s11_individual_validation_crossfit_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
bar_heights <- matrix(
  alpha_005_summary$signal_rate,
  nrow = length(method_names),
  ncol = length(scenario_names),
  byrow = FALSE,
  dimnames = list(method_names, scenario_names)
)
barplot(
  height = bar_heights,
  beside = TRUE,
  las = 2,
  ylim = c(0, max(0.25, bar_heights)),
  col = unname(method_colours[method_names]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S11: individual scans versus cross-fitted average"
)
abline(h = 0.05, col = "black", lty = 2, lwd = 2)
legend(
  "topright",
  legend = method_names,
  fill = unname(method_colours[method_names]),
  bty = "n",
  cex = 0.80
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s11_individual_validation_crossfit_individual_boxplot.png"),
  width = 1800,
  height = 1100,
  res = 180
)
boxplot(
  final_log_e ~ scenario,
  data = individual_results,
  las = 2,
  col = "grey85",
  border = "grey30",
  ylab = "Final individual log e-value",
  main = "S11: distribution of individual final log e-values"
)
abline(h = log(1 / 0.05), col = "firebrick", lty = 2, lwd = 2)
dev.off()

message("S11 completed. Summary:")
print(summary_by_alpha)
message("Individual summary:")
print(individual_summary)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
