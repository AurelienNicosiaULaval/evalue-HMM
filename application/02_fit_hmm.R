# Fit candidate HMMs for the elk application.
#
# The fitted null is selected by BIC among K = 2, 3, 4 models fitted on the
# training individuals only. This script uses moveHMM for model fitting and
# stores the fitted objects for downstream predictive e-diagnostics.

required_packages <- c("moveHMM")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    ". Install them before running this script.",
    call. = FALSE
  )
}

input_data_file <- "application/data_processed/elk_prepared.csv"
if (!file.exists(input_data_file)) {
  stop("Run application/01_preprocess.R before this script.", call. = FALSE)
}

output_data_dir <- "application/data_processed"
output_table_dir <- "results/application_tables"
dir.create(output_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)

prepared <- read.csv(input_data_file, stringsAsFactors = FALSE)
train_data <- prepared[prepared$split == "train", ]
class(train_data) <- c("moveData", "data.frame")

make_initial_values <- function(data, n_states, profile) {
  step <- data$step[is.finite(data$step) & data$step > 0]
  if (length(step) == 0L) {
    stop("No positive steps are available for initialization.", call. = FALSE)
  }

  probabilities <- switch(
    profile,
    compact = seq(0.15, 0.85, length.out = n_states),
    spread = seq(0.05, 0.95, length.out = n_states),
    upper = seq(0.20, 0.95, length.out = n_states),
    reversed_angle = seq(0.10, 0.90, length.out = n_states),
    long_tail = seq(0.15, 0.95, length.out = n_states),
    stop("Unknown initialization profile.", call. = FALSE)
  )
  means <- as.numeric(stats::quantile(step, probs = probabilities, names = FALSE))

  sd_scale <- switch(
    profile,
    compact = 1,
    spread = 2,
    upper = 1,
    reversed_angle = 1.5,
    long_tail = 1.5
  )
  sds <- pmax(means * sd_scale, stats::sd(step, na.rm = TRUE) / n_states)

  step_par0 <- c(means, sds)
  if (any(data$step == 0, na.rm = TRUE)) {
    step_par0 <- c(step_par0, rep(0.005, n_states))
  }

  concentration <- switch(
    profile,
    compact = seq(0.2, 1.4, length.out = n_states),
    spread = seq(0.1, 1.2, length.out = n_states),
    upper = seq(0.3, 1.5, length.out = n_states),
    reversed_angle = rev(seq(0.2, 1.4, length.out = n_states)),
    long_tail = rev(seq(0.2, 1.4, length.out = n_states))
  )
  angle_par0 <- c(rep(0, n_states), concentration)

  list(
    stepPar0 = step_par0,
    anglePar0 = angle_par0,
    profile = profile
  )
}

fit_one_start <- function(data, n_states, initial_values) {
  warnings <- character()
  fit <- tryCatch(
    withCallingHandlers(
      moveHMM::fitHMM(
        data = data,
        nbStates = n_states,
        stepPar0 = initial_values$stepPar0,
        anglePar0 = initial_values$anglePar0,
        stepDist = "gamma",
        angleDist = "vm",
        formula = ~1,
        nlmPar = list(iterlim = 1000)
      ),
      warning = function(warning_condition) {
        warnings <<- c(warnings, conditionMessage(warning_condition))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error_condition) error_condition
  )

  list(
    fit = fit,
    warnings = warnings,
    profile = initial_values$profile
  )
}

summarise_fit <- function(fit, n_states, profile, warning_count) {
  if (inherits(fit, "error")) {
    return(data.frame(
      n_states = n_states,
      profile = profile,
      converged = FALSE,
      code = NA_integer_,
      iterations = NA_integer_,
      neg_log_likelihood = NA_real_,
      log_likelihood = NA_real_,
      n_parameters = NA_integer_,
      n_observations = sum(is.finite(train_data$step) & is.finite(train_data$angle)),
      AIC = NA_real_,
      BIC = NA_real_,
      warning_count = warning_count,
      error = conditionMessage(fit),
      stringsAsFactors = FALSE
    ))
  }

  n_parameters <- length(fit$mod$estimate)
  n_observations <- sum(is.finite(train_data$step) & is.finite(train_data$angle))
  neg_log_likelihood <- fit$mod$minimum

  data.frame(
    n_states = n_states,
    profile = profile,
    converged = fit$mod$code %in% c(1L, 2L),
    code = fit$mod$code,
    iterations = fit$mod$iterations,
    neg_log_likelihood = neg_log_likelihood,
    log_likelihood = -neg_log_likelihood,
    n_parameters = n_parameters,
    n_observations = n_observations,
    AIC = 2 * neg_log_likelihood + 2 * n_parameters,
    BIC = 2 * neg_log_likelihood + log(n_observations) * n_parameters,
    warning_count = warning_count,
    error = NA_character_,
    stringsAsFactors = FALSE
  )
}

profiles <- c("compact", "spread", "upper", "reversed_angle", "long_tail")
candidate_rows <- list()
candidate_fits <- list()
row_index <- 1L

for (n_states in 2:4) {
  message("Fitting moveHMM model with K = ", n_states)
  for (profile in profiles) {
    initial_values <- make_initial_values(
      data = train_data,
      n_states = n_states,
      profile = profile
    )
    fitted_start <- fit_one_start(
      data = train_data,
      n_states = n_states,
      initial_values = initial_values
    )
    candidate_rows[[row_index]] <- summarise_fit(
      fit = fitted_start$fit,
      n_states = n_states,
      profile = fitted_start$profile,
      warning_count = length(fitted_start$warnings)
    )
    candidate_fits[[row_index]] <- fitted_start
    names(candidate_fits)[row_index] <- paste0("K", n_states, "_", profile)
    row_index <- row_index + 1L
  }
}

candidate_summary <- do.call(rbind, candidate_rows)
usable_summary <- candidate_summary[
  candidate_summary$converged & is.finite(candidate_summary$BIC),
]
if (nrow(usable_summary) == 0L) {
  stop("No converged HMM fit was obtained.", call. = FALSE)
}

best_by_k <- do.call(
  rbind,
  lapply(split(usable_summary, usable_summary$n_states), function(rows) {
    rows[which.min(rows$neg_log_likelihood), , drop = FALSE]
  })
)
best_by_k$selected_null <- FALSE
best_by_k$selected_null[which.min(best_by_k$BIC)] <- TRUE

selected_null_k <- best_by_k$n_states[best_by_k$selected_null]

selected_models <- list()
for (k in best_by_k$n_states) {
  selected_profile <- best_by_k$profile[best_by_k$n_states == k]
  fit_name <- paste0("K", k, "_", selected_profile)
  selected_models[[paste0("K", k)]] <- candidate_fits[[fit_name]]$fit
}

write.csv(
  candidate_summary,
  file = file.path(output_table_dir, "elk_hmm_all_fit_attempts.csv"),
  row.names = FALSE
)
write.csv(
  best_by_k,
  file = file.path(output_table_dir, "elk_hmm_model_selection.csv"),
  row.names = FALSE
)
saveRDS(
  selected_models,
  file = file.path(output_data_dir, "elk_movehmm_selected_models.rds")
)

message("Application HMM fitting completed.")
message("Selected null model: K = ", selected_null_k)
message("Model selection table written to: ", file.path(output_table_dir, "elk_hmm_model_selection.csv"))
message("Selected model objects written to: ", file.path(output_data_dir, "elk_movehmm_selected_models.rds"))
