# Compute predictive e-diagnostics for the elk application under LOAO.
#
# For each individual, we compute the predictive e-diagnostics using the models
# fitted on the other three individuals. We also compute the population-level
# cross-fitted average e-values across the 4 individuals.

library(evalueHMM)

source("application/utils_movehmm_eprocess.R")

input_data_file <- "application/data_processed/elk_prepared.csv"
input_models_file <- "application/data_processed/elk_movehmm_selected_models.rds"
input_selection_file <- "results/application_tables/elk_hmm_model_selection.csv"

if (!file.exists(input_data_file)) {
  stop("Run application/01_preprocess.R before this script.", call. = FALSE)
}
if (!file.exists(input_models_file) || !file.exists(input_selection_file)) {
  stop("Run application/02_fit_hmm.R before this script.", call. = FALSE)
}

output_data_dir <- "application/data_processed"
output_table_dir <- "results/application_tables"
dir.create(output_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)

prepared <- read.csv(input_data_file, stringsAsFactors = FALSE)
model_selection <- read.csv(input_selection_file, stringsAsFactors = FALSE)
models_by_fold <- readRDS(input_models_file)
individual_ids <- unique(prepared$ID)

# We will collect path data and summary data for all individuals
all_paths <- list()
all_summaries <- list()
predicted_state_probs_list <- list()
diagnostics_by_fold <- list()

for (val_id in individual_ids) {
  fold_models <- models_by_fold[[val_id]]
  fold_selection <- model_selection[model_selection$validation_id == val_id, ]
  
  selected_null_k <- 3L
  null_model_name <- "K3"
  alternative_model_name <- "K4"
  
  if (!null_model_name %in% names(fold_models)) {
    stop("Selected null model was not found in fold: ", val_id, call. = FALSE)
  }
  if (!alternative_model_name %in% names(fold_models)) {
    stop("Alternative model K+1 was not found in fold: ", val_id, call. = FALSE)
  }
  
  validation_data <- prepared[prepared$ID == val_id, ]
  null_parameters <- extract_movehmm_parameters(fold_models[[null_model_name]])
  state_alt_parameters <- extract_movehmm_parameters(fold_models[[alternative_model_name]])
  angle_alt_parameters <- scale_angle_concentration(
    parameters = null_parameters,
    multiplier = 0.5
  )
  
  null_components <- movehmm_predictive_components(
    data = validation_data,
    parameters = null_parameters
  )
  state_alt_components <- movehmm_predictive_components(
    data = validation_data,
    parameters = state_alt_parameters
  )
  angle_alt_components <- movehmm_predictive_components(
    data = validation_data,
    parameters = angle_alt_parameters
  )
  
  diagnostic_data <- null_components$data
  log_p0 <- null_components$log_predictive_density
  log_q_state <- state_alt_components$log_predictive_density
  log_q_angle <- angle_alt_components$log_predictive_density
  log_q_mixture <- log_average_density(
    cbind(log_q_state, log_q_angle),
    weights = c(0.5, 0.5)
  )
  
  state_diagnostic <- make_predictive_diagnostic(
    diagnostic_name = "state_number_K3_vs_K4",
    log_p0 = log_p0,
    log_q = log_q_state,
    alpha = 0.05,
    time = diagnostic_data$time_index,
    individual_id = diagnostic_data$ID,
    metadata = list(
      null_model = null_model_name,
      alternative_model = alternative_model_name,
      diagnostic_type = "full_density_state_number"
    )
  )
  
  angle_diagnostic <- make_predictive_diagnostic(
    diagnostic_name = "angle_diffuse_K3",
    log_p0 = log_p0,
    log_q = log_q_angle,
    alpha = 0.05,
    time = diagnostic_data$time_index,
    individual_id = diagnostic_data$ID,
    metadata = list(
      null_model = null_model_name,
      angle_concentration_multiplier = 0.5,
      diagnostic_type = "full_density_angle_concentration"
    )
  )
  
  mixture_diagnostic <- make_predictive_diagnostic(
    diagnostic_name = "mixture_state_angle",
    log_p0 = log_p0,
    log_q = log_q_mixture,
    alpha = 0.05,
    time = diagnostic_data$time_index,
    individual_id = diagnostic_data$ID,
    metadata = list(
      null_model = null_model_name,
      component_diagnostics = paste(c(state_diagnostic$diagnostic_name, angle_diagnostic$diagnostic_name), collapse = "; "),
      weights = "0.5;0.5",
      diagnostic_type = "predictable_fixed_mixture"
    )
  )
  
  long_step_state <- which.max(null_parameters$step_mean)
  long_step_weights <- null_components$predicted_probs[, long_step_state]
  localized_state_diagnostic <- localize_predictive_diagnostic(
    diagnostic = state_diagnostic,
    weights = long_step_weights,
    localization_name = "predicted_state_3",
    mode = "linear",
    metadata = list(
      localized_state = long_step_state,
      localized_state_mean_step = null_parameters$step_mean[long_step_state]
    )
  )
  
  diagnostics <- list(
    state_diagnostic,
    angle_diagnostic,
    mixture_diagnostic,
    localized_state_diagnostic
  )
  names(diagnostics) <- vapply(diagnostics, `[[`, character(1), "diagnostic_name")
  diagnostics_by_fold[[val_id]] <- diagnostics
  
  # Summaries and paths
  fold_summaries <- do.call(
    rbind,
    lapply(diagnostics, summarise_predictive_diagnostic)
  )
  fold_summaries$placement <- "exploratory_real_data_application"
  fold_summaries$validation_id <- val_id
  fold_summaries$null_model <- null_model_name
  all_summaries[[val_id]] <- fold_summaries
  
  # Bind rows for path
  bind_rows_fill <- function(data_list) {
    all_names <- unique(unlist(lapply(data_list, names), use.names = FALSE))
    aligned <- lapply(data_list, function(data) {
      missing_names <- setdiff(all_names, names(data))
      for (missing_name in missing_names) {
        data[[missing_name]] <- NA
      }
      data[, all_names, drop = FALSE]
    })
    do.call(rbind, aligned)
  }
  
  fold_paths <- bind_rows_fill(
    lapply(diagnostics, function(diagnostic) diagnostic$path)
  )
  all_paths[[val_id]] <- fold_paths
  
  predicted_state_probs_list[[val_id]] <- data.frame(
    ID = diagnostic_data$ID,
    time_index = diagnostic_data$time_index,
    null_components$predicted_probs,
    stringsAsFactors = FALSE
  )
}

individual_summaries_df <- do.call(rbind, all_summaries)
paths_df <- do.call(rbind, all_paths)
predicted_state_probs_df <- do.call(rbind, predicted_state_probs_list)

# Now, we compute the Cross-Fitted population average e-values (Proposition 6)
# For each diagnostic, we average the final e-values across the 4 validation individuals.
diagnostic_names <- unique(individual_summaries_df$diagnostic_name)
population_summaries <- list()

for (diag_name in diagnostic_names) {
  diag_subset <- individual_summaries_df[individual_summaries_df$diagnostic_name == diag_name, ]
  
  # Retrieve final cumulative log e-value for each individual
  final_log_es <- diag_subset$final_log_e
  final_es <- exp(final_log_es)
  
  # Cross-fitted average e-value: E^cf = (1/N) * sum(E^(i))
  cross_fitted_e <- mean(final_es)
  cross_fitted_log_e <- log(cross_fitted_e)
  
  # Check if E^cf crosses the significance threshold (1/alpha = 20 for alpha = 0.05)
  alpha <- 0.05
  threshold <- log(1 / alpha)
  signal <- cross_fitted_log_e >= threshold
  
  pop_row <- data.frame(
    diagnostic_name = diag_name,
    alpha = alpha,
    threshold = threshold,
    signal = signal,
    crossing_time = NA,
    max_log_e = cross_fitted_log_e, # for the average, max is just the final log average
    final_log_e = cross_fitted_log_e,
    mean_log_increment = NA,
    n_observations = sum(diag_subset$n_observations),
    placement = "exploratory_real_data_application",
    validation_id = "population_average",
    null_model = "K3", # general null model
    stringsAsFactors = FALSE
  )
  population_summaries[[diag_name]] <- pop_row
}

population_summaries_df <- do.call(rbind, population_summaries)
diagnostic_summary_combined <- rbind(individual_summaries_df, population_summaries_df)

write.csv(
  diagnostic_summary_combined,
  file = file.path(output_table_dir, "elk_application_diagnostic_summary.csv"),
  row.names = FALSE
)
write.csv(
  paths_df,
  file = file.path(output_table_dir, "elk_application_diagnostic_paths.csv"),
  row.names = FALSE
)
write.csv(
  predicted_state_probs_df,
  file = file.path(output_table_dir, "elk_application_predicted_state_probs.csv"),
  row.names = FALSE
)
saveRDS(
  diagnostics_by_fold,
  file = file.path(output_data_dir, "elk_application_diagnostics.rds")
)

message("Application e-process computation completed under LOAO.")
message("Diagnostic summary (including population averages):")
print(diagnostic_summary_combined, row.names = FALSE)
