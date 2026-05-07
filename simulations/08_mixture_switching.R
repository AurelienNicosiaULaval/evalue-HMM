# S8: Predictable mixture and switching.
# This simulation compares individual diagnostics with an equal-weight mixture
# and a predictable recent-leader switching rule. The alternative has two
# successive defects: angular misspecification followed by step-angle dependence.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_angles.R")
source("R/diagnostics_copula.R")
source("R/diagnostics_combination.R")

set.seed(20260513)

n_replicates <- 250L
n_times <- 300L
change_time <- 150L
switch_lookback <- 25L
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

angle_parameters <- create_hmm_movement_parameters(
  initial_probs = null_parameters$initial_probs,
  transition_matrix = null_parameters$transition_matrix,
  step_shape = null_parameters$step_shape,
  step_rate = null_parameters$step_rate,
  angle_mean = c(0.35, -0.30),
  angle_sd = c(1.25, 0.65)
)

rho_by_state <- c(0.60, 0.60)
diagnostic_rho <- 0.55

scenario_names <- c("hmm_null", "angle_then_copula")
method_names <- c("angle", "step_angle", "mixture_equal", "switch_recent_leader")
method_colours <- c(
  angle = "steelblue3",
  step_angle = "darkorange3",
  mixture_equal = "darkgreen",
  switch_recent_leader = "firebrick"
)

simulate_angle_then_copula <- function(
    n_times,
    null_parameters,
    angle_parameters,
    rho_by_state,
    change_time) {
  n_states <- length(null_parameters$initial_probs)
  states <- integer(n_times)
  step_length <- numeric(n_times)
  turning_angle <- numeric(n_times)
  regime <- character(n_times)

  states[1L] <- sample.int(n_states, size = 1L, prob = null_parameters$initial_probs)
  if (n_times > 1L) {
    for (time_index in 2:n_times) {
      states[time_index] <- sample.int(
        n_states,
        size = 1L,
        prob = null_parameters$transition_matrix[states[time_index - 1L], ]
      )
    }
  }

  for (time_index in seq_len(n_times)) {
    state <- states[time_index]

    if (time_index <= change_time) {
      step_length[time_index] <- stats::rgamma(
        1L,
        shape = null_parameters$step_shape[state],
        rate = null_parameters$step_rate[state]
      )
      turning_angle[time_index] <- simulate_wrapped_normal(
        1L,
        mean = angle_parameters$angle_mean[state],
        sd = angle_parameters$angle_sd[state]
      )
      regime[time_index] <- "angle"
    } else {
      rho <- rho_by_state[state]
      z_step <- stats::rnorm(1L)
      z_angle <- rho * z_step + sqrt(1 - rho^2) * stats::rnorm(1L)
      step_length[time_index] <- stats::qgamma(
        stats::pnorm(z_step),
        shape = null_parameters$step_shape[state],
        rate = null_parameters$step_rate[state]
      )
      turning_angle[time_index] <- wrap_angle(stats::qnorm(
        stats::pnorm(z_angle),
        mean = null_parameters$angle_mean[state],
        sd = null_parameters$angle_sd[state]
      ))
      regime[time_index] <- "step_angle"
    }
  }

  data.frame(
    individual_id = 1L,
    time = seq_len(n_times),
    state = states,
    step_length = step_length,
    turning_angle = turning_angle,
    regime = regime,
    stringsAsFactors = FALSE
  )
}

crossing_time_for_alpha <- function(path, alpha) {
  threshold <- log(1 / alpha)
  crossing_index <- which(path$log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    return(NA_real_)
  }
  path$time[crossing_index]
}

replicate_results <- vector("list", n_replicates * length(scenario_names) * length(method_names))
path_results <- vector("list", min(20L, n_replicates) * length(scenario_names) * length(method_names))
mean_path_sum <- array(
  0,
  dim = c(n_times, length(method_names), length(scenario_names)),
  dimnames = list(NULL, method_names, scenario_names)
)
switch_angle_sum <- matrix(0, nrow = n_times, ncol = length(scenario_names))
colnames(switch_angle_sum) <- scenario_names

result_index <- 1L
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
      simulate_angle_then_copula(
        n_times = n_times,
        null_parameters = null_parameters,
        angle_parameters = angle_parameters,
        rho_by_state = rho_by_state,
        change_time = change_time
      )
    }

    angle_diagnostic <- diagnostic_angle(
      data = simulated_data,
      null_parameters = null_parameters,
      angle_parameters = angle_parameters,
      alpha = 0.05,
      diagnostic_name = "angle"
    )
    step_angle_diagnostic <- diagnostic_step_angle_dependence(
      data = simulated_data,
      null_parameters = null_parameters,
      rho = diagnostic_rho,
      alpha = 0.05,
      diagnostic_name = "step_angle"
    )

    diagnostic_menu <- list(
      angle = angle_diagnostic,
      step_angle = step_angle_diagnostic
    )
    mixture_diagnostic <- diagnostic_mixture(
      diagnostics = diagnostic_menu,
      weights = c(0.5, 0.5),
      diagnostic_name = "mixture_equal",
      alpha = 0.05
    )
    switch_diagnostic <- diagnostic_switch(
      diagnostics = diagnostic_menu,
      lookback = switch_lookback,
      initial_choice = 1L,
      diagnostic_name = "switch_recent_leader",
      alpha = 0.05
    )

    diagnostics <- list(
      angle = angle_diagnostic,
      step_angle = step_angle_diagnostic,
      mixture_equal = mixture_diagnostic,
      switch_recent_leader = switch_diagnostic
    )

    switch_angle_sum[, scenario] <- switch_angle_sum[, scenario] +
      as.numeric(switch_diagnostic$path$selected_diagnostic == "angle")

    for (method in method_names) {
      diagnostic <- diagnostics[[method]]
      summary <- summarise_predictive_diagnostic(diagnostic)
      crossing_times <- vapply(
        alphas,
        function(alpha) crossing_time_for_alpha(diagnostic$path, alpha),
        numeric(1)
      )

      before_change <- diagnostic$path$time <= change_time
      after_change <- diagnostic$path$time > change_time
      replicate_row <- data.frame(
        scenario = scenario,
        replicate = replicate_index,
        method = method,
        max_log_e = summary$max_log_e,
        final_log_e = summary$final_log_e,
        mean_log_increment = summary$mean_log_increment,
        mean_log_increment_before_change = mean(diagnostic$path$log_e_increment[before_change]),
        mean_log_increment_after_change = mean(diagnostic$path$log_e_increment[after_change]),
        switch_fraction_angle_before_change = if (method == "switch_recent_leader") {
          mean(diagnostic$path$selected_diagnostic[before_change] == "angle")
        } else {
          NA_real_
        },
        switch_fraction_step_angle_after_change = if (method == "switch_recent_leader") {
          mean(diagnostic$path$selected_diagnostic[after_change] == "step_angle")
        } else {
          NA_real_
        },
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

      mean_path_sum[, method, scenario] <- mean_path_sum[, method, scenario] +
        diagnostic$path$log_e_cumulative

      if (replicate_index <= 20L) {
        path_results[[path_index]] <- data.frame(
          scenario = scenario,
          replicate = replicate_index,
          method = method,
          time = diagnostic$path$time,
          log_e_cumulative = diagnostic$path$log_e_cumulative,
          log_e_increment = diagnostic$path$log_e_increment,
          selected_diagnostic = if (method == "switch_recent_leader") {
            diagnostic$path$selected_diagnostic
          } else {
            NA_character_
          },
          stringsAsFactors = FALSE
        )
        path_index <- path_index + 1L
      }
    }
  }
}

replicate_results <- do.call(rbind, replicate_results)
path_results <- do.call(rbind, path_results)

mean_path_results <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    do.call(
      rbind,
      lapply(method_names, function(method) {
        data.frame(
          scenario = scenario,
          method = method,
          time = seq_len(n_times),
          mean_log_e_cumulative = mean_path_sum[, method, scenario] / n_replicates,
          stringsAsFactors = FALSE
        )
      })
    )
  })
)

switch_choice_results <- do.call(
  rbind,
  lapply(scenario_names, function(scenario) {
    data.frame(
      scenario = scenario,
      time = seq_len(n_times),
      mean_switch_probability_angle = switch_angle_sum[, scenario] / n_replicates,
      mean_switch_probability_step_angle = 1 - switch_angle_sum[, scenario] / n_replicates,
      stringsAsFactors = FALSE
    )
  })
)

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
          lapply(alphas, function(alpha) {
            alpha_label <- alpha_labels[which(alphas == alpha)]
            crossing_column <- paste0("crossing_time_alpha_", alpha_label)
            threshold <- log(1 / alpha)
            signal <- method_results$max_log_e >= threshold
            signal_rate <- mean(signal)
            monte_carlo_se <- sqrt(signal_rate * (1 - signal_rate) / n_replicates)
            crossing_times <- method_results[[crossing_column]]

            data.frame(
              scenario = scenario,
              method = method,
              alpha = alpha,
              threshold = threshold,
              n_replicates = n_replicates,
              n_times = n_times,
              change_time = change_time,
              switch_lookback = switch_lookback,
              signal_rate = signal_rate,
              monte_carlo_se = monte_carlo_se,
              mean_max_log_e = mean(method_results$max_log_e),
              median_max_log_e = stats::median(method_results$max_log_e),
              mean_final_log_e = mean(method_results$final_log_e),
              median_final_log_e = stats::median(method_results$final_log_e),
              mean_crossing_time = mean(crossing_times, na.rm = TRUE),
              mean_log_increment_before_change = mean(method_results$mean_log_increment_before_change),
              mean_log_increment_after_change = mean(method_results$mean_log_increment_after_change),
              mean_switch_fraction_angle_before_change = mean(
                method_results$switch_fraction_angle_before_change,
                na.rm = TRUE
              ),
              mean_switch_fraction_step_angle_after_change = mean(
                method_results$switch_fraction_step_angle_after_change,
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
summary_by_alpha$mean_crossing_time[is.nan(summary_by_alpha$mean_crossing_time)] <- NA_real_
summary_by_alpha$mean_switch_fraction_angle_before_change[
  is.nan(summary_by_alpha$mean_switch_fraction_angle_before_change)
] <- NA_real_
summary_by_alpha$mean_switch_fraction_step_angle_after_change[
  is.nan(summary_by_alpha$mean_switch_fraction_step_angle_after_change)
] <- NA_real_

write.csv(
  summary_by_alpha,
  file = file.path(output_table_dir, "s8_mixture_switching_summary.csv"),
  row.names = FALSE
)
write.csv(
  replicate_results,
  file = file.path(output_table_dir, "s8_mixture_switching_replicates.csv"),
  row.names = FALSE
)
write.csv(
  path_results,
  file = file.path(output_table_dir, "s8_mixture_switching_paths.csv"),
  row.names = FALSE
)
write.csv(
  mean_path_results,
  file = file.path(output_table_dir, "s8_mixture_switching_mean_paths.csv"),
  row.names = FALSE
)
write.csv(
  switch_choice_results,
  file = file.path(output_table_dir, "s8_mixture_switching_switch_choices.csv"),
  row.names = FALSE
)

png(
  filename = file.path(output_figure_dir, "s8_mixture_switching_mean_paths.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alternative_paths <- mean_path_results[mean_path_results$scenario == "angle_then_copula", ]
y_range <- range(c(alternative_paths$mean_log_e_cumulative, log(1 / alphas)))
plot(
  NA,
  xlim = c(1, n_times),
  ylim = y_range,
  xlab = "Time",
  ylab = "Mean cumulative log e-value",
  main = "S8: mean paths under sequential diagnostic failures"
)
usr <- par("usr")
rect(
  xleft = 1,
  ybottom = usr[3],
  xright = change_time,
  ytop = usr[4],
  col = grDevices::adjustcolor("steelblue3", alpha.f = 0.12),
  border = NA
)
rect(
  xleft = change_time + 1,
  ybottom = usr[3],
  xright = n_times,
  ytop = usr[4],
  col = grDevices::adjustcolor("darkorange3", alpha.f = 0.12),
  border = NA
)
for (method in method_names) {
  method_path <- alternative_paths[alternative_paths$method == method, ]
  lines(
    method_path$time,
    method_path$mean_log_e_cumulative,
    col = method_colours[[method]],
    lwd = 2
  )
}
abline(h = log(1 / 0.05), col = "firebrick", lwd = 2, lty = 2)
abline(v = change_time, col = "grey30", lty = 3, lwd = 2)
legend(
  "topleft",
  legend = c(method_names, "alpha = 0.05 threshold", "change point"),
  col = c(unname(method_colours), "firebrick", "grey30"),
  lwd = c(rep(2, length(method_names)), 2, 2),
  lty = c(rep(1, length(method_names)), 2, 3),
  bty = "n",
  cex = 0.85
)
dev.off()

png(
  filename = file.path(output_figure_dir, "s8_mixture_switching_signal_rates.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alpha_005_summary <- summary_by_alpha[summary_by_alpha$alpha == 0.05, ]
bar_heights <- tapply(
  alpha_005_summary$signal_rate,
  list(alpha_005_summary$method, alpha_005_summary$scenario),
  identity
)
barplot(
  bar_heights,
  beside = TRUE,
  ylim = c(0, 1),
  col = unname(method_colours[rownames(bar_heights)]),
  ylab = "Signal rate at alpha = 0.05",
  main = "S8: signal rates for individual and combined diagnostics",
  legend.text = rownames(bar_heights),
  args.legend = list(x = "topleft", bty = "n", cex = 0.8)
)
abline(h = 0.05, col = "firebrick", lty = 2, lwd = 2)
dev.off()

png(
  filename = file.path(output_figure_dir, "s8_mixture_switching_switch_choices.png"),
  width = 1800,
  height = 1100,
  res = 180
)
alternative_switch <- switch_choice_results[switch_choice_results$scenario == "angle_then_copula", ]
plot(
  alternative_switch$time,
  alternative_switch$mean_switch_probability_angle,
  type = "l",
  col = method_colours[["angle"]],
  lwd = 2,
  ylim = c(0, 1),
  xlab = "Time",
  ylab = "Mean selected diagnostic probability",
  main = "S8: predictable recent-leader switching"
)
lines(
  alternative_switch$time,
  alternative_switch$mean_switch_probability_step_angle,
  col = method_colours[["step_angle"]],
  lwd = 2
)
abline(v = change_time, col = "grey30", lty = 3, lwd = 2)
legend(
  "right",
  legend = c("angle selected", "step-angle selected", "change point"),
  col = c(method_colours[["angle"]], method_colours[["step_angle"]], "grey30"),
  lwd = c(2, 2, 2),
  lty = c(1, 1, 3),
  bty = "n"
)
dev.off()

message("S8 completed. Summary:")
print(summary_by_alpha)
message("Tables written to: ", output_table_dir)
message("Figures written to: ", output_figure_dir)
