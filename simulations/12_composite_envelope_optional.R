# S12: Conservative composite envelope.
#
# This optional scenario illustrates the finite-family envelope in the paper.
# A diagnostic density q is compared with either the true null model, the central
# null model, or the pointwise envelope over a small null family.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_composite.R")

set.seed(20260518)

n_replicates <- 300L
n_times <- 300L
alphas <- c(0.10, 0.05, 0.01)
alpha_labels <- c("010", "005", "001")

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

null_family <- list(
  center_null = create_hmm_movement_parameters(
    initial_probs = c(0.65, 0.35),
    transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
    step_shape = c(2.0, 7.0),
    step_rate = c(3.0, 2.0),
    angle_mean = c(0.0, 0.0),
    angle_sd = c(0.85, 0.30)
  ),
  persistent_null = create_hmm_movement_parameters(
    initial_probs = c(0.70, 0.30),
    transition_matrix = matrix(c(0.96, 0.04, 0.07, 0.93), nrow = 2, byrow = TRUE),
    step_shape = c(2.1, 6.6),
    step_rate = c(3.1, 1.9),
    angle_mean = c(-0.04, 0.03),
    angle_sd = c(0.75, 0.26)
  ),
  diffuse_angle_null = create_hmm_movement_parameters(
    initial_probs = c(0.58, 0.42),
    transition_matrix = matrix(c(0.88, 0.12, 0.16, 0.84), nrow = 2, byrow = TRUE),
    step_shape = c(1.9, 7.4),
    step_rate = c(2.8, 2.15),
    angle_mean = c(0.10, -0.08),
    angle_sd = c(1.10, 0.46)
  )
)

diagnostic_parameters <- create_hmm_movement_parameters(
  initial_probs = c(0.55, 0.45),
  transition_matrix = matrix(c(0.86, 0.14, 0.20, 0.80), nrow = 2, byrow = TRUE),
  step_shape = c(2.3, 6.4),
  step_rate = c(3.0, 1.75),
  angle_mean = c(0.22, -0.18),
  angle_sd = c(1.25, 0.60)
)

generator_names <- names(null_family)
method_names <- c("oracle_true_null", "center_only", "composite_envelope")
method_status <- c(
  oracle_true_null = "valid_for_known_generator",
  center_only = "not_uniform_over_family",
  composite_envelope = "uniform_finite_family_envelope"
)
method_colours <- c(
  oracle_true_null = "steelblue3",
  center_only = "darkorange3",
  composite_envelope = "darkgreen"
)

crossing_time_for_path <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

make_manual_path <- function(time, log_p0, log_q) {
  data.frame(
    time = time,
    log_p0 = log_p0,
    log_q = log_q,
    log_e_increment = log_q - log_p0,
    log_e_cumulative = cumsum(log_q - log_p0),
    stringsAsFactors = FALSE
  )
}

family_summary <- summarise_hmm_parameter_family(null_family)
diagnostic_summary <- summarise_hmm_parameter_family(
  list(diagnostic_alternative = diagnostic_parameters)
)

replicate_results <- vector("list", n_replicates * length(generator_names) * length(method_names))
path_results <- vector("list", min(20L, n_replicates) * length(generator_names) * length(method_names))
selected_model_results <- vector("list", n_replicates * length(generator_names))

result_index <- 1L
path_index <- 1L
selected_index <- 1L

for (generator_name in generator_names) {
  generator_parameters <- null_family[[generator_name]]

  for (replicate_index in seq_len(n_replicates)) {
    simulated_data <- simulate_hmm_movement(
      n_times = n_times,
      parameters = generator_parameters,
      n_individuals = 1L
    )

    log_q <- hmm_movement_predictive_log_density(
      data = simulated_data,
      parameters = diagnostic_parameters
    )
    log_oracle <- hmm_movement_predictive_log_density(
      data = simulated_data,
      parameters = generator_parameters
    )
    log_center <- hmm_movement_predictive_log_density(
      data = simulated_data,
      parameters = null_family$center_null
    )
    envelope_diagnostic <- diagnostic_composite_envelope(
      data = simulated_data,
      null_family = null_family,
      diagnostic_parameters = diagnostic_parameters,
      alpha = 0.05,
      diagnostic_name = "composite_envelope",
      metadata = list(generator_name = generator_name)
    )
    log_envelope <- envelope_diagnostic$path$log_p0

    selected_model_results[[selected_index]] <- data.frame(
      generator_name = generator_name,
      replicate = replicate_index,
      selected_null_model = envelope_diagnostic$selected_null_model,
      time = simulated_data$time,
      stringsAsFactors = FALSE
    )
    selected_index <- selected_index + 1L

    method_paths <- list(
      oracle_true_null = make_manual_path(
        time = simulated_data$time,
        log_p0 = log_oracle,
        log_q = log_q
      ),
      center_only = make_manual_path(
        time = simulated_data$time,
        log_p0 = log_center,
        log_q = log_q
      ),
      composite_envelope = make_manual_path(
        time = simulated_data$time,
        log_p0 = log_envelope,
        log_q = log_q
      )
    )

    for (method in method_names) {
      path <- method_paths[[method]]
      crossing_times <- vapply(
        alphas,
        function(alpha) crossing_time_for_path(path, alpha),
        numeric(1)
      )

      replicate_row <- data.frame(
        generator_name = generator_name,
        replicate = replicate_index,
        method = method,
        method_status = method_status[[method]],
        n_times = n_times,
        family_size = length(null_family),
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

      if (replicate_index <= 20L) {
        path_results[[path_index]] <- data.frame(
          generator_name = generator_name,
          replicate = replicate_index,
          method = method,
          method_status = method_status[[method]],
          time = path$time,
          log_e_cumulative = path$log_e_cumulative,
          log_e_increment = path$log_e_increment,
          stringsAsFactors = FALSE
        )
        path_index <- path_index + 1L
      }
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)
selected_model_results <- do.call(rbind, selected_model_results)

summary_by_alpha <- do.call(
  rbind,
  lapply(generator_names, function(generator_name) {
    do.call(
      rbind,
      lapply(method_names, function(method) {
        method_results <- replicate_results[
          replicate_results$generator_name == generator_name &
            replicate_results$method == method,
        ]
        do.call(
          rbind,
          lapply(seq_along(alphas), function(alpha_index) {
            alpha <- alphas[alpha_index]
            alpha_label <- alpha_labels[alpha_index]
            crossing_column <- paste0("crossing_time_alpha_", alpha_label)
            signal <- method_results$max_log_e >= log(1 / alpha)
            signal_rate <- mean(signal)
            crossing_times <- method_results[[crossing_column]]

            data.frame(
              generator_name = generator_name,
              method = method,
              method_status = method_status[[method]],
              alpha = alpha,
              threshold = log(1 / alpha),
              n_replicates = n_replicates,
              n_times = n_times,
              family_size = length(null_family),
              signal_rate = signal_rate,
              monte_carlo_se = sqrt(signal_rate * (1 - signal_rate) / n_replicates),
              signal_rate_minus_alpha = signal_rate - alpha,
              mean_max_log_e = mean(method_results$max_log_e),
              median_max_log_e = stats::median(method_results$max_log_e),
              mean_final_log_e = mean(method_results$final_log_e),
              median_final_log_e = stats::median(method_results$final_log_e),
              mean_log_increment = mean(method_results$mean_log_increment),
              mean_crossing_time = mean(crossing_times, na.rm = TRUE),
              stringsAsFactors = FALSE
            )
          })
        )
      })
    )
  })
)
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_

selected_model_summary <- as.data.frame(table(
  generator_name = selected_model_results$generator_name,
  selected_null_model = selected_model_results$selected_null_model
))
generator_counts <- table(selected_model_results$generator_name)
selected_model_summary$selection_fraction <- selected_model_summary$Freq /
  as.numeric(generator_counts[as.character(selected_model_summary$generator_name)])

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s12_composite_envelope_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s12_composite_envelope_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s12_composite_envelope_paths.csv"),
  row.names = FALSE
)
write.csv(
  family_summary,
  file = file.path(output_table_dir, "s12_composite_envelope_null_family.csv"),
  row.names = FALSE
)
write.csv(
  diagnostic_summary,
  file = file.path(output_table_dir, "s12_composite_envelope_diagnostic_alternative.csv"),
  row.names = FALSE
)
write.csv(
  selected_model_summary,
  file = file.path(output_table_dir, "s12_composite_envelope_selected_model_summary.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s12_composite_envelope_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
envelope_paths <- path_results[path_results$method %in% c("center_only", "composite_envelope"), ]
y_range <- range(c(envelope_paths$log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = range(envelope_paths$time),
  ylim = y_range,
  xlab = "Time",
  ylab = "Cumulative log e-value",
  main = "S12: center-only denominator versus composite envelope"
)
for (method in c("center_only", "composite_envelope")) {
  method_paths <- envelope_paths[envelope_paths$method == method, ]
  for (path_id in unique(paste(method_paths$generator_name, method_paths$replicate, sep = "_"))) {
    replicate_path <- method_paths[
      paste(method_paths$generator_name, method_paths$replicate, sep = "_") == path_id,
    ]
    lines(
      replicate_path$time,
      replicate_path$log_e_cumulative,
      col = grDevices::adjustcolor(method_colours[[method]], alpha.f = 0.18),
      lwd = 1
    )
  }
}
abline(h = log(1 / 0.05), col = "black", lwd = 2, lty = 2)
legend(
  "topleft",
  legend = c("center_only", "composite_envelope", "alpha = 0.05 threshold"),
  col = c(method_colours[["center_only"]], method_colours[["composite_envelope"]], "black"),
  lwd = c(2, 2, 2),
  lty = c(1, 1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s12_composite_envelope_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
bar_heights <- matrix(
  alpha_005_summary$signal_rate,
  nrow = length(method_names),
  ncol = length(generator_names),
  byrow = FALSE,
  dimnames = list(method_names, generator_names)
)
barplot(
  height = bar_heights,
  beside = TRUE,
  las = 2,
  ylim = c(0, 1),
  col = unname(method_colours[method_names]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S12: finite-family composite envelope controls false signals"
)
abline(h = 0.05, col = "black", lty = 2, lwd = 2)
legend(
  "topleft",
  legend = method_names,
  fill = unname(method_colours[method_names]),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s12_composite_envelope_final_log_e.png"),
  width = 1800,
  height = 1100,
  res = 180
)
boxplot(
  final_log_e ~ generator_name + method,
  data = replicate_results,
  las = 2,
  col = "grey85",
  border = "grey30",
  ylab = "Final log e-value",
  main = "S12: cost of the composite envelope"
)
abline(h = log(1 / 0.05), col = "firebrick", lty = 2, lwd = 2)
dev.off()

message("S12 completed. Summary:")
print(summary_by_alpha)
message("Selected model summary:")
print(selected_model_summary)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
