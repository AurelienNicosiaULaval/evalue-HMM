# Compute predictive e-diagnostics for the elk application.
#
# The current application uses the BIC-selected moveHMM model as the fitted null
# generator and evaluates pre-specified diagnostic alternatives on the held-out
# validation individual.

source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_localization.R")
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
models <- readRDS(input_models_file)

selected_null_k <- model_selection$n_states[model_selection$selected_null][1L]
null_model_name <- paste0("K", selected_null_k)
alternative_model_name <- paste0("K", selected_null_k + 1L)

if (!null_model_name %in% names(models)) {
  stop("Selected null model was not found in the saved model list.", call. = FALSE)
}
if (!alternative_model_name %in% names(models)) {
  stop(
    "The K+1 state diagnostic requires ",
    alternative_model_name,
    ", but this model is not available.",
    call. = FALSE
  )
}

validation_data <- prepared[prepared$split == "validation", ]
null_parameters <- extract_movehmm_parameters(models[[null_model_name]])
state_alt_parameters <- extract_movehmm_parameters(models[[alternative_model_name]])
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
if (!identical(diagnostic_data$ID, state_alt_components$data$ID) ||
    !identical(diagnostic_data$time_index, state_alt_components$data$time_index)) {
  stop("Null and K+1 diagnostic data rows are not aligned.", call. = FALSE)
}

log_p0 <- null_components$log_predictive_density
log_q_state <- state_alt_components$log_predictive_density
log_q_angle <- angle_alt_components$log_predictive_density
log_q_mixture <- log_average_density(
  cbind(log_q_state, log_q_angle),
  weights = c(0.5, 0.5)
)

state_diagnostic <- make_predictive_diagnostic(
  diagnostic_name = paste0("state_number_", null_model_name, "_vs_", alternative_model_name),
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
  diagnostic_name = paste0("angle_diffuse_", null_model_name),
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
  localization_name = paste0("predicted_state_", long_step_state),
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

diagnostic_summary <- do.call(
  rbind,
  lapply(diagnostics, summarise_predictive_diagnostic)
)
diagnostic_summary$placement <- "exploratory_real_data_application"
diagnostic_summary$validation_id <- unique(diagnostic_data$ID)
diagnostic_summary$null_model <- null_model_name

diagnostic_paths <- bind_rows_fill(
  lapply(diagnostics, function(diagnostic) diagnostic$path)
)

predicted_state_probs <- data.frame(
  ID = diagnostic_data$ID,
  time_index = diagnostic_data$time_index,
  null_components$predicted_probs,
  stringsAsFactors = FALSE
)

write.csv(
  diagnostic_summary,
  file = file.path(output_table_dir, "elk_application_diagnostic_summary.csv"),
  row.names = FALSE
)
write.csv(
  diagnostic_paths,
  file = file.path(output_table_dir, "elk_application_diagnostic_paths.csv"),
  row.names = FALSE
)
write.csv(
  predicted_state_probs,
  file = file.path(output_table_dir, "elk_application_predicted_state_probs.csv"),
  row.names = FALSE
)
saveRDS(
  diagnostics,
  file = file.path(output_data_dir, "elk_application_diagnostics.rds")
)

message("Application e-process computation completed.")
message("Null model: ", null_model_name)
message("K+1 diagnostic model: ", alternative_model_name)
message("Long-step localized state: ", long_step_state)
message("Diagnostic summary:")
print(diagnostic_summary, row.names = FALSE)
