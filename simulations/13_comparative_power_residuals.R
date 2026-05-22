# Comparative Power Simulations
# This script compares the empirical power of anytime-valid predictive e-processes
# against classical HMM diagnostics based on pseudo-residuals (Kolmogorov-Smirnov tests,
# Ljung-Box autocorrelation tests, and residual correlation tests) under scenarios S3 to S6.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_states.R")
source("R/diagnostics_angles.R")
source("R/diagnostics_copula.R")
source("R/diagnostics_duration.R")

set.seed(20260521)

n_replicates <- 300L
n_times <- 300L
alpha <- 0.05
threshold <- log(1 / alpha)

output_table_dir <- "results/simulation_tables"
output_figure_dir <- "results/simulation_figures"
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

# Utility to compute pseudo-residuals under the null HMM
compute_pseudo_residuals <- function(data, null_parameters) {
  log_emission <- hmm_movement_log_emission(data, null_parameters)
  filter_res <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = null_parameters$transition_matrix,
    initial_probs = null_parameters$initial_probs
  )
  
  predicted_probs <- filter_res$predicted_probs
  n_times <- nrow(data)
  n_states <- ncol(predicted_probs)
  
  u_step <- numeric(n_times)
  u_angle <- numeric(n_times)
  
  for (s in seq_len(n_states)) {
    step_cdfs <- pgamma(
      data$step_length,
      shape = null_parameters$step_shape[s],
      rate = null_parameters$step_rate[s]
    )
    u_step <- u_step + predicted_probs[, s] * step_cdfs
    
    angle_cdfs <- p_wrapped_normal(
      data$turning_angle,
      mean = null_parameters$angle_mean[s],
      sd = null_parameters$angle_sd[s]
    )
    u_angle <- u_angle + predicted_probs[, s] * angle_cdfs
  }
  
  # Clip to avoid infinite qnorm values
  u_step_clipped <- pmin(pmax(u_step, 1e-15), 1 - 1e-15)
  u_angle_clipped <- pmin(pmax(u_angle, 1e-15), 1 - 1e-15)
  
  z_step <- qnorm(u_step_clipped)
  z_angle <- qnorm(u_angle_clipped)
  
  list(
    u_step = u_step,
    u_angle = u_angle,
    z_step = z_step,
    z_angle = z_angle
  )
}

# Define models for S3, S4, S5, S6
# S3 Parameters
s3_true <- create_hmm_movement_parameters(
  initial_probs = c(0.50, 0.35, 0.15),
  transition_matrix = matrix(c(0.91, 0.06, 0.03, 0.08, 0.87, 0.05, 0.08, 0.10, 0.82), nrow = 3, byrow = TRUE),
  step_shape = c(2.0, 7.5, 4.0),
  step_rate = c(3.0, 2.0, 1.2),
  angle_mean = c(0.0, 0.0, 0.6),
  angle_sd = c(1.6, 0.35, 0.75)
)
s3_null <- create_hmm_movement_parameters(
  initial_probs = c(0.62, 0.38),
  transition_matrix = matrix(c(0.90, 0.10, 0.14, 0.86), nrow = 2, byrow = TRUE),
  step_shape = c(2.2, 6.8),
  step_rate = c(3.0, 1.8),
  angle_mean = c(0.0, 0.1),
  angle_sd = c(1.55, 0.45)
)

# S4 Parameters
s4_true <- create_hmm_movement_parameters(
  initial_probs = c(0.65, 0.35),
  transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 7.0),
  step_rate = c(3.0, 2.0),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(1.8, 0.25)
)
s4_null <- create_hmm_movement_parameters(
  initial_probs = s4_true$initial_probs,
  transition_matrix = s4_true$transition_matrix,
  step_shape = s4_true$step_shape,
  step_rate = s4_true$step_rate,
  angle_mean = c(0.0, 0.25),
  angle_sd = c(1.0, 0.75)
)

# S5 Parameters
s5_null <- create_hmm_movement_parameters(
  initial_probs = c(0.65, 0.35),
  transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 7.0),
  step_rate = c(3.0, 2.0),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(0.85, 0.30)
)
s5_rho <- c(0.60, 0.60)
s5_diag_rho <- 0.55

# S6 Parameters
s6_null <- create_hmm_movement_parameters(
  initial_probs = c(0.50, 0.50),
  transition_matrix = matrix(c(0.78, 0.22, 0.18, 0.82), nrow = 2, byrow = TRUE),
  step_shape = c(2.0, 12.0),
  step_rate = c(5.0, 2.4),
  angle_mean = c(0.0, 0.0),
  angle_sd = c(1.20, 0.35)
)
s6_dwell_mean <- c(18, 18)
s6_dwell_size <- c(12, 12)
s6_step_threshold <- 2.0
s6_block_size <- 30L
s6_n_simulations <- 150L
s6_pseudo_count <- 1

# Main simulation loop
power_results <- list()

# --- S3: Underfitted States ---
message("Running S3 comparative power...")
s3_signals_e <- logical(n_replicates)
s3_signals_ks_step <- logical(n_replicates)
s3_signals_ks_angle <- logical(n_replicates)
s3_signals_lb_step <- logical(n_replicates)

for (i in seq_len(n_replicates)) {
  sim_data <- simulate_hmm_movement(n_times = n_times, parameters = s3_true, n_individuals = 1L)
  
  # E-diagnostic
  diag <- diagnostic_extra_state(
    data = sim_data,
    null_parameters = s3_null,
    extra_state_parameters = s3_true,
    alpha = alpha,
    diagnostic_name = "extra_state_k2_vs_k3"
  )
  s3_signals_e[i] <- max(diag$path$log_e_cumulative) >= threshold
  
  # Pseudo-residuals
  res <- compute_pseudo_residuals(sim_data, s3_null)
  
  # KS tests
  s3_signals_ks_step[i] <- ks.test(res$u_step, "punif")$p.value < alpha
  s3_signals_ks_angle[i] <- ks.test(res$u_angle, "punif")$p.value < alpha
  
  # Ljung-Box test for steps
  s3_signals_lb_step[i] <- Box.test(res$z_step, lag = 5, type = "Ljung-Box")$p.value < alpha
}

power_results[["S3"]] <- data.frame(
  Scenario = "S3 (Underfitted States)",
  E_diagnostic = mean(s3_signals_e),
  KS_step = mean(s3_signals_ks_step),
  KS_angle = mean(s3_signals_ks_angle),
  LjungBox_step = mean(s3_signals_lb_step),
  Correlation_test = NA_real_
)

# --- S4: Angular Misspecification ---
message("Running S4 comparative power...")
s4_signals_e <- logical(n_replicates)
s4_signals_ks_step <- logical(n_replicates)
s4_signals_ks_angle <- logical(n_replicates)

for (i in seq_len(n_replicates)) {
  sim_data <- simulate_hmm_movement(n_times = n_times, parameters = s4_true, n_individuals = 1L)
  
  # E-diagnostic
  diag <- diagnostic_angle(
    data = sim_data,
    null_parameters = s4_null,
    angle_parameters = s4_true,
    alpha = alpha,
    diagnostic_name = "angle_full_density"
  )
  s4_signals_e[i] <- max(diag$path$log_e_cumulative) >= threshold
  
  # Pseudo-residuals
  res <- compute_pseudo_residuals(sim_data, s4_null)
  
  s4_signals_ks_step[i] <- ks.test(res$u_step, "punif")$p.value < alpha
  s4_signals_ks_angle[i] <- ks.test(res$u_angle, "punif")$p.value < alpha
}

power_results[["S4"]] <- data.frame(
  Scenario = "S4 (Angle Misspecified)",
  E_diagnostic = mean(s4_signals_e),
  KS_step = mean(s4_signals_ks_step),
  KS_angle = mean(s4_signals_ks_angle),
  LjungBox_step = NA_real_,
  Correlation_test = NA_real_
)

# --- S5: Step-Angle Dependence ---
message("Running S5 comparative power...")
s5_signals_e <- logical(n_replicates)
s5_signals_ks_step <- logical(n_replicates)
s5_signals_ks_angle <- logical(n_replicates)
s5_signals_cor <- logical(n_replicates)

for (i in seq_len(n_replicates)) {
  sim_data <- simulate_hmm_movement_copula(n_times = n_times, parameters = s5_null, rho_by_state = s5_rho, n_individuals = 1L)
  
  # E-diagnostic
  diag <- diagnostic_step_angle_dependence(
    data = sim_data,
    null_parameters = s5_null,
    rho = s5_diag_rho,
    alpha = alpha,
    diagnostic_name = "step_angle_gaussian_copula"
  )
  s5_signals_e[i] <- max(diag$path$log_e_cumulative) >= threshold
  
  # Extract Rosenblatt residuals computed by diagnostic
  u_step <- diag$features$u_step
  u_angle_given_step <- diag$features$u_angle_given_step
  
  s5_signals_ks_step[i] <- ks.test(u_step, "punif")$p.value < alpha
  s5_signals_ks_angle[i] <- ks.test(u_angle_given_step, "punif")$p.value < alpha
  
  # Correlation test
  z_step <- qnorm(u_step)
  z_angle_given_step <- qnorm(u_angle_given_step)
  s5_signals_cor[i] <- cor.test(z_step, z_angle_given_step)$p.value < alpha
}

power_results[["S5"]] <- data.frame(
  Scenario = "S5 (Step-Angle Dep.)",
  E_diagnostic = mean(s5_signals_e),
  KS_step = mean(s5_signals_ks_step),
  KS_angle = mean(s5_signals_ks_angle),
  LjungBox_step = NA_real_,
  Correlation_test = mean(s5_signals_cor)
)

# --- S6: Duration Misspecification ---
message("Running S6 comparative power...")
s6_signals_e <- logical(n_replicates)
s6_signals_ks_step <- logical(n_replicates)
s6_signals_lb_step <- logical(n_replicates)

for (i in seq_len(n_replicates)) {
  sim_data <- simulate_hsmm_movement(
    n_times = n_times,
    parameters = s6_null,
    dwell_mean = s6_dwell_mean,
    dwell_size = s6_dwell_size,
    n_individuals = 1L
  )
  
  # E-diagnostic
  diag <- diagnostic_duration_blockwise(
    data = sim_data,
    null_parameters = s6_null,
    dwell_mean = s6_dwell_mean,
    dwell_size = s6_dwell_size,
    step_threshold = s6_step_threshold,
    block_size = s6_block_size,
    n_simulations = s6_n_simulations,
    pseudo_count = s6_pseudo_count,
    alpha = alpha,
    diagnostic_name = "duration_blockwise_switch_count"
  )
  s6_signals_e[i] <- max(diag$path$log_e_cumulative) >= threshold
  
  # Pseudo-residuals
  res <- compute_pseudo_residuals(sim_data, s6_null)
  
  s6_signals_ks_step[i] <- ks.test(res$u_step, "punif")$p.value < alpha
  s6_signals_lb_step[i] <- Box.test(res$z_step, lag = 5, type = "Ljung-Box")$p.value < alpha
}

power_results[["S6"]] <- data.frame(
  Scenario = "S6 (Duration HSMM)",
  E_diagnostic = mean(s6_signals_e),
  KS_step = mean(s6_signals_ks_step),
  KS_angle = NA_real_,
  LjungBox_step = mean(s6_signals_lb_step),
  Correlation_test = NA_real_
)

# Combine and write results
power_table <- do.call(rbind, power_results)
write.csv(power_table, file.path(output_table_dir, "comparative_power_residuals.csv"), row.names = FALSE)

# Generate a comparative plot
png(file.path(output_figure_dir, "comparative_power_residuals.png"), width = 1800, height = 1100, res = 180)
par(mar = c(5, 5, 4, 12) + 0.1)

# Format data for plotting
scenarios <- power_table$Scenario
plot_data <- matrix(c(
  power_table$E_diagnostic,
  ifelse(is.na(power_table$KS_step), 0, power_table$KS_step),
  ifelse(is.na(power_table$KS_angle), 0, power_table$KS_angle),
  ifelse(is.na(power_table$LjungBox_step), 0, power_table$LjungBox_step),
  ifelse(is.na(power_table$Correlation_test), 0, power_table$Correlation_test)
), nrow = 5, byrow = TRUE)

colnames(plot_data) <- scenarios
rownames(plot_data) <- c("E-Diagnostic", "KS Step", "KS Angle / Rosenblatt", "Ljung-Box Step (Lag 5)", "Correlation Test")

barplot(
  plot_data,
  beside = TRUE,
  col = c("royalblue4", "skyblue", "aquamarine3", "orange", "tomato"),
  ylim = c(0, 1),
  ylab = "Empirical Power (Rejection / Signal Rate at alpha=0.05)",
  main = "Signal Rates: E-Diagnostics vs Pseudo-Residual Tests",
  las = 1,
  cex.names = 0.8
)

legend(
  x = "topright",
  inset = c(-0.25, 0),
  xpd = TRUE,
  legend = rownames(plot_data),
  fill = c("royalblue4", "skyblue", "aquamarine3", "orange", "tomato"),
  bty = "n"
)
dev.off()

message("Comparative power analysis completed. Results:")
print(power_table)
