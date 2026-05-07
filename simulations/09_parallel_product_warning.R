# S9: Parallel product warning.
# This simulation gives a controlled negative example. A single predictive
# density-ratio diagnostic is valid under the HMM null. Averaging duplicated
# copies remains safe, but multiplying duplicated copies on the same observations
# can inflate false signals.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_combination.R")

set.seed(20260514)

n_replicates <- 1000L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

null_parameters <- create_hmm_movement_parameters()

# The competitor is fixed before validation. The base ratio q_t / p_t is a valid
# e-increment under the null generator, as in S1.
diagnostic_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.55, 0.45),
  transition_matrix = matrix(c(0.86, 0.14, 0.18, 0.82), nrow = 2, byrow = TRUE),
  step_shape = c(2.5, 6.0),
  step_rate = c(3.2, 1.7),
  angle_mean = c(0.15, -0.10),
  angle_sd = c(1.25, 0.55)
)

method_names <- c(
  "single_valid",
  "weighted_average_two_copies",
  "naive_product_two_copies",
  "naive_product_three_copies"
)
method_colours <- c(
  single_valid = "steelblue3",
  weighted_average_two_copies = "darkgreen",
  naive_product_two_copies = "darkorange3",
  naive_product_three_copies = "firebrick"
)
validity_status <- c(
  single_valid = "valid_e_process",
  weighted_average_two_copies = "valid_weighted_average",
  naive_product_two_copies = "not_valid_by_default",
  naive_product_three_copies = "not_valid_by_default"
)

crossing_time_for_path <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

make_manual_path <- function(time, log_e_increment) {
  data.frame(
    time = time,
    log_e_increment = log_e_increment,
    log_e_cumulative = cumsum(log_e_increment),
    stringsAsFactors = FALSE
  )
}

replicate_results <- vector("list", n_replicates * length(method_names))
path_results <- vector("list", min(25L, n_replicates) * length(method_names))

result_index <- 1L
path_index <- 1L

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

  copy_1 <- make_predictive_diagnostic(
    diagnostic_name = "copy_1",
    log_p0 = log_p0,
    log_q = log_q,
    alpha = 0.05,
    time = simulated_data$time,
    individual_id = simulated_data$individual_id,
    metadata = list(scenario = "parallel_product_warning")
  )
  copy_2 <- make_predictive_diagnostic(
    diagnostic_name = "copy_2",
    log_p0 = log_p0,
    log_q = log_q,
    alpha = 0.05,
    time = simulated_data$time,
    individual_id = simulated_data$individual_id,
    metadata = list(scenario = "parallel_product_warning")
  )
  copy_3 <- make_predictive_diagnostic(
    diagnostic_name = "copy_3",
    log_p0 = log_p0,
    log_q = log_q,
    alpha = 0.05,
    time = simulated_data$time,
    individual_id = simulated_data$individual_id,
    metadata = list(scenario = "parallel_product_warning")
  )

  average_two <- diagnostic_mixture(
    diagnostics = list(copy_1 = copy_1, copy_2 = copy_2),
    weights = c(0.5, 0.5),
    diagnostic_name = "weighted_average_two_copies",
    alpha = 0.05
  )

  base_increment <- copy_1$path$log_e_increment
  paths <- list(
    single_valid = copy_1$path[, c("time", "log_e_increment", "log_e_cumulative")],
    weighted_average_two_copies = average_two$path[, c("time", "log_e_increment", "log_e_cumulative")],
    naive_product_two_copies = make_manual_path(
      time = simulated_data$time,
      log_e_increment = copy_1$path$log_e_increment + copy_2$path$log_e_increment
    ),
    naive_product_three_copies = make_manual_path(
      time = simulated_data$time,
      log_e_increment = copy_1$path$log_e_increment +
        copy_2$path$log_e_increment +
        copy_3$path$log_e_increment
    )
  )

  for (method in method_names) {
    path <- paths[[method]]
    crossing_times <- vapply(
      alphas,
      function(alpha) crossing_time_for_path(path, alpha),
      numeric(1)
    )

    replicate_row <- data.frame(
      replicate = replicate_index,
      method = method,
      validity_status = validity_status[[method]],
      max_log_e = max(path$log_e_cumulative),
      final_log_e = tail(path$log_e_cumulative, 1L),
      mean_log_increment = mean(path$log_e_increment),
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
        replicate = replicate_index,
        method = method,
        validity_status = validity_status[[method]],
        path,
        stringsAsFactors = FALSE
      )
      path_index <- path_index + 1L
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(method_names, function(method) {
    method_results <- replicate_results[replicate_results$method == method, ]
    do.call(
      rbind,
      lapply(alphas, function(alpha) {
        alpha_label <- alpha_labels[which(alphas == alpha)]
        crossing_column <- paste0("crossing_time_alpha_", alpha_label)
        threshold <- log(1 / alpha)
        signal <- method_results$max_log_e >= threshold
        signal_rate <- mean(signal)
        monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
        crossing_times <- method_results[[crossing_column]]

        data.frame(
          scenario = "parallel_product_warning",
          method = method,
          validity_status = validity_status[[method]],
          alpha = alpha,
          threshold = threshold,
          n_replicates = n_replicates,
          n_times = n_times,
          signal_rate = signal_rate,
          monte_carlo_se = monte_carlo_se,
          signal_rate_minus_alpha = signal_rate - alpha,
          mean_max_log_e = mean(method_results$max_log_e),
          median_max_log_e = stats::median(method_results$max_log_e),
          mean_final_log_e = mean(method_results$final_log_e),
          median_final_log_e = stats::median(method_results$final_log_e),
          mean_crossing_time = mean(crossing_times, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s9_parallel_product_warning_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s9_parallel_product_warning_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s9_parallel_product_warning_paths.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s9_parallel_product_warning_paths.png"),
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
  main = "S9: naive products of parallel diagnostics inflate evidence"
)
for (method in method_names) {
  method_paths <- path_results[path_results$method == method, ]
  for (replicate_index in unique(method_paths$replicate)) {
    replicate_path <- method_paths[method_paths$replicate == replicate_index, ]
    lines(
      replicate_path$time,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(method_colours[[method]], alpha.f = 0.25),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "bottomleft",
  legend = c(method_names, "alpha = 0.05 threshold"),
  col = c(unname(method_colours), "black"),
  lwd = c(rep(2, length(method_names)), 2),
  lty = c(rep(1, length(method_names)), 2),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s9_parallel_product_warning_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
barplot(
  height = alpha_005_summary$signal_rate,
  names.arg = alpha_005_summary$method,
  las = 2,
  ylim = c(0, max(0.25, alpha_005_summary$signal_rate)),
  col = unname(method_colours[alpha_005_summary$method]),
  ylab = "False signal rate at alpha = 0.05",
  main = "S9: false signal inflation from naive products"
)
abline(h = 0.05, col = "black", lty = 2, lwd = 2)
dev.off()

png(
  filename = file.path(output_figure_dir, "s9_parallel_product_warning_max_log_e.png"),
  width = 1800,
  height = 1100,
  res = 180
)
hist(
  replicate_results$max_log_e[replicate_results$method == "single_valid"],
  breaks = 45,
  col = grDevices::adjustcolor(method_colours[["single_valid"]], alpha.f = 0.35),
  border = "white",
  xlim = range(replicate_results$max_log_e),
  xlab = "Maximum cumulative log e-value",
  main = "S9: maximum log e-value under the HMM null"
)
hist(
  replicate_results$max_log_e[replicate_results$method == "naive_product_three_copies"],
  breaks = 45,
  col = grDevices::adjustcolor(method_colours[["naive_product_three_copies"]], alpha.f = 0.35),
  border = "white",
  add = TRUE
)
abline(v = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "topright",
  legend = c("single valid diagnostic", "naive product of three copies", "alpha = 0.05 threshold"),
  col = c(method_colours[["single_valid"]], method_colours[["naive_product_three_copies"]], "black"),
  lwd = c(8, 8, 2),
  lty = c(1, 1, 2),
  bty = "n"
)
dev.off()

message("S9 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
