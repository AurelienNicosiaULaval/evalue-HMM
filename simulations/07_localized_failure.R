# S7: Localized failure.
# This simulation checks whether predictable weights can localize a diagnostic
# signal in a pre-specified time window and in a soft filtered state.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_copula.R")
source("R/diagnostics_localization.R")

set.seed(20260511)

n_replicates <- 300L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

failure_start <- 121L
failure_end <- 220L
failure_times <- failure_start:failure_end

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

# The failure is local: residual step-angle dependence appears only during the
# middle window, and mostly in the second latent state.
rho_by_state <- c(0.00, 0.80)
diagnostic_rho <- 0.55

variant_names <- c(
  "global",
  "failure_window",
  "early_control",
  "state_2",
  "failure_window_state_2"
)
variant_colours <- c(
  global = "grey25",
  failure_window = "darkorange3",
  early_control = "steelblue3",
  state_2 = "darkgreen",
  failure_window_state_2 = "firebrick"
)

crossing_time_for_alpha <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

replicate_results <- vector("list", n_replicates * length(variant_names))
path_results <- vector("list", min(20L, n_replicates) * length(variant_names))
mean_path_sum <- matrix(0, nrow = n_times, ncol = length(variant_names))
colnames(mean_path_sum) <- variant_names
mean_increment_sum <- numeric(n_times)
mean_state_2_weight_sum <- numeric(n_times)

result_index <- 1L
path_index <- 1L

for (replicate_index in seq_len(n_replicates)) {
  simulated_data <- simulate_hmm_movement_local_copula(
    n_times = n_times,
    parameters = null_parameters,
    rho_by_state = rho_by_state,
    active_times = failure_times,
    n_individuals = 1L
  )

  global_diagnostic <- diagnostic_step_angle_dependence(
    data = simulated_data,
    null_parameters = null_parameters,
    rho = diagnostic_rho,
    alpha = 0.05,
    diagnostic_name = "step_angle_local_failure",
    metadata = list(scenario = "localized_failure")
  )

  failure_window_weights <- time_window_weights(
    time = global_diagnostic$path$time,
    start = failure_start,
    end = failure_end
  )
  early_control_weights <- time_window_weights(
    time = global_diagnostic$path$time,
    start = 1,
    end = failure_start - 1L
  )
  state_2_weights <- hmm_predictive_state_weights(
    data = simulated_data,
    parameters = null_parameters,
    state = 2L
  )
  failure_window_state_2_weights <- failure_window_weights * state_2_weights

  diagnostics <- list(
    global = global_diagnostic,
    failure_window = localize_predictive_diagnostic(
      diagnostic = global_diagnostic,
      weights = failure_window_weights,
      localization_name = "failure_window",
      mode = "linear"
    ),
    early_control = localize_predictive_diagnostic(
      diagnostic = global_diagnostic,
      weights = early_control_weights,
      localization_name = "early_control",
      mode = "linear"
    ),
    state_2 = localize_predictive_diagnostic(
      diagnostic = global_diagnostic,
      weights = state_2_weights,
      localization_name = "state_2",
      mode = "linear"
    ),
    failure_window_state_2 = localize_predictive_diagnostic(
      diagnostic = global_diagnostic,
      weights = failure_window_state_2_weights,
      localization_name = "failure_window_state_2",
      mode = "linear"
    )
  )

  positive_increment <- pmax(global_diagnostic$path$log_e_increment, 0)
  positive_total <- sum(positive_increment)
  positive_fraction_in_failure_window <- if (positive_total > 0) {
    sum(positive_increment[failure_window_weights == 1]) / positive_total
  } else {
    NA_real_
  }

  mean_increment_sum <- mean_increment_sum + global_diagnostic$path$log_e_increment
  mean_state_2_weight_sum <- mean_state_2_weight_sum + state_2_weights

  for (variant in variant_names) {
    diagnostic <- diagnostics[[variant]]
    summary <- summarise_predictive_diagnostic(diagnostic)
    crossing_times <- vapply(
      alphas,
      function(alpha) crossing_time_for_alpha(diagnostic$path, alpha),
      numeric(1)
    )
    mean_path_sum[, variant] <- mean_path_sum[, variant] + diagnostic$path$log_e_cumulative

    replicate_row <- data.frame(
      replicate = replicate_index,
      variant = variant,
      max_log_e = summary$max_log_e,
      final_log_e = summary$final_log_e,
      mean_log_increment = summary$mean_log_increment,
      positive_fraction_in_failure_window = positive_fraction_in_failure_window,
      true_failure_fraction = mean(simulated_data$active_copula),
      true_state_2_failure_fraction = mean(simulated_data$active_copula & simulated_data$state == 2L),
      mean_weight = mean(diagnostic$path$weight),
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
        replicate = replicate_index,
        variant = variant,
        time = diagnostic$path$time,
        log_e_cumulative = diagnostic$path$log_e_cumulative,
        log_e_increment = diagnostic$path$log_e_increment,
        weight = diagnostic$path$weight,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)

mean_path_results <- do.call(
  rbind,
  lapply(variant_names, function(variant) {
    data.frame(
      variant = variant,
      time = seq_len(n_times),
      mean_log_e_cumulative = mean_path_sum[, variant] / n_replicates,
      stringsAsFactors = FALSE
    )
  })
)

mean_increment_results <- data.frame(
  time = seq_len(n_times),
  mean_global_log_e_increment = mean_increment_sum / n_replicates,
  mean_state_2_weight = mean_state_2_weight_sum / n_replicates,
  in_failure_window = seq_len(n_times) %in% failure_times,
  stringsAsFactors = FALSE
)
mean_increment_results$smoothed_global_log_e_increment <- as.numeric(stats::filter(
  mean_increment_results$mean_global_log_e_increment,
  rep(1 / 9, 9),
  sides = 2
))

summary_by_alpha <- do.call(
  rbind,
  lapply(variant_names, function(variant) {
    variant_results <- replicate_results[replicate_results$variant == variant, ]
    do.call(
      rbind,
      lapply(alphas, function(alpha) {
        alpha_label <- alpha_labels[which(alphas == alpha)]
        crossing_column <- paste0("crossing_time_alpha_", alpha_label)
        threshold <- log(1 / alpha)
        signal <- variant_results$max_log_e >= threshold
        signal_rate <- mean(signal)
        monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
        crossing_times <- variant_results[[crossing_column]]

        data.frame(
          scenario = "localized_failure",
          variant = variant,
          alpha = alpha,
          threshold = threshold,
          n_replicates = n_replicates,
          n_times = n_times,
          failure_start = failure_start,
          failure_end = failure_end,
          signal_rate = signal_rate,
          monte_carlo_se = monte_carlo_se,
          mean_max_log_e = mean(variant_results$max_log_e),
          median_max_log_e = stats::median(variant_results$max_log_e),
          mean_final_log_e = mean(variant_results$final_log_e),
          median_final_log_e = stats::median(variant_results$final_log_e),
          mean_crossing_time = mean(crossing_times, na.rm = TRUE),
          mean_positive_fraction_in_failure_window = mean(
            variant_results$positive_fraction_in_failure_window,
            na.rm = TRUE
          ),
          mean_weight = mean(variant_results$mean_weight),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[
  is.nan(summary_by_alpha$mean_crossing_time)
] <- NA_real_

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s7_localized_failure_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s7_localized_failure_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s7_localized_failure_paths.csv"),
  row.names = FALSE
)
write.csv(
  mean_path_results,
  file = file.path(output_table_dir, "s7_localized_failure_mean_paths.csv"),
  row.names = FALSE
)
write.csv(
  mean_increment_results,
  file = file.path(output_table_dir, "s7_localized_failure_mean_increments.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s7_localized_failure_mean_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
y_range <- range(c(mean_path_results$mean_log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = c(1, n_times),
  ylim = y_range,
  xlab = "Time",
  ylab = "Mean cumulative log e-value",
  main = "S7: predictable localization of a time-localized failure"
)
usr <- par("usr")
rect(
  xleft = failure_start,
  ybottom = usr[3],
  xright = failure_end,
  ytop = usr[4],
  col = grDevices::adjustcolor("grey70", alpha.f = 0.35),
  border = NA
)
for (variant in variant_names) {
  variant_path <- mean_path_results[mean_path_results$variant == variant, ]
  lines(
    variant_path$time,
    variant_path$mean_log_e_cumulative,
    col = variant_colours[[variant]],
    lwd = 2
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c(variant_names, "alpha = 0.05 threshold", "failure window"),
  col = c(unname(variant_colours), "firebrick", grDevices::adjustcolor("grey70", alpha.f = 0.35)),
  lwd = c(rep(2, length(variant_names)), 2, 8),
  lty = c(rep(1, length(variant_names)), 2, 1),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s7_localized_failure_mean_increment.png"),
  width = 1800,
  height = 1100,
  res = 180
)
y_range <- range(
  c(
    mean_increment_results$mean_global_log_e_increment,
    mean_increment_results$smoothed_global_log_e_increment
  ),
  na.rm = TRUE
)
plot(
  mean_increment_results$time,
  mean_increment_results$mean_global_log_e_increment,
  type = "n",
  xlab = "Time",
  ylab = "Mean global log e-increment",
  ylim = y_range,
  main = "S7: local increments identify the failure window"
)
usr <- par("usr")
rect(
  xleft = failure_start,
  ybottom = usr[3],
  xright = failure_end,
  ytop = usr[4],
  col = grDevices::adjustcolor("grey70", alpha.f = 0.35),
  border = NA
)
segments(
  x0 = mean_increment_results$time,
  y0 = 0,
  x1 = mean_increment_results$time,
  y1 = mean_increment_results$mean_global_log_e_increment,
  col = grDevices::adjustcolor("grey40", alpha.f = 0.45)
)
lines(
  mean_increment_results$time,
  mean_increment_results$smoothed_global_log_e_increment,
  col = "darkorange3",
  lwd = 2
)
abline(h = 0, col = "grey20", lty = 2)
legend(
  "topleft",
  legend = c("mean increment", "9-point moving average", "failure window"),
  col = c("grey40", "darkorange3", grDevices::adjustcolor("grey70", alpha.f = 0.35)),
  lwd = c(1, 2, 8),
  lty = c(1, 1, 1),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s7_localized_failure_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
barplot(
  height = alpha_005_summary$signal_rate,
  names.arg = alpha_005_summary$variant,
  las = 2,
  ylim = c(0, 1),
  col = unname(variant_colours[alpha_005_summary$variant]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S7: signal rates by localized diagnostic"
)
abline(h = 0.05, col = "firebrick", lty = 2, lwd = 2)
dev.off()

message("S7 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
