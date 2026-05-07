# Conservative composite-null envelope diagnostics.

validate_hmm_parameter_family <- function(parameter_family, min_size = 2L) {
  if (!is.list(parameter_family) || length(parameter_family) < min_size) {
    stop(
      "`parameter_family` must be a list of at least ",
      min_size,
      " HMM parameter set(s).",
      call. = FALSE
    )
  }
  if (is.null(names(parameter_family)) || any(!nzchar(names(parameter_family)))) {
    names(parameter_family) <- paste0("null_model_", seq_along(parameter_family))
  }
  if (anyDuplicated(names(parameter_family))) {
    stop("Names in `parameter_family` must be unique.", call. = FALSE)
  }

  n_states <- vapply(parameter_family, function(parameters) {
    length(parameters$initial_probs)
  }, integer(1))
  if (length(unique(n_states)) != 1L) {
    stop("All models in `parameter_family` must have the same number of states.", call. = FALSE)
  }

  parameter_family
}

hmm_family_predictive_log_density <- function(data, parameter_family) {
  parameter_family <- validate_hmm_parameter_family(parameter_family)
  log_density_matrix <- vapply(
    parameter_family,
    function(parameters) {
      hmm_movement_predictive_log_density(
        data = data,
        parameters = parameters
      )
    },
    numeric(nrow(data))
  )
  colnames(log_density_matrix) <- names(parameter_family)
  log_density_matrix
}

hmm_composite_envelope_log_density <- function(data, parameter_family) {
  log_density_matrix <- hmm_family_predictive_log_density(
    data = data,
    parameter_family = parameter_family
  )
  apply(log_density_matrix, 1L, max)
}

diagnostic_composite_envelope <- function(
    data,
    null_family,
    diagnostic_parameters,
    alpha = 0.05,
    diagnostic_name = "composite_envelope",
    metadata = list()) {
  null_family <- validate_hmm_parameter_family(null_family)
  component_log_p0 <- hmm_family_predictive_log_density(
    data = data,
    parameter_family = null_family
  )
  envelope_log_p0 <- apply(component_log_p0, 1L, max)
  log_q <- hmm_movement_predictive_log_density(
    data = data,
    parameters = diagnostic_parameters
  )

  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = envelope_log_p0,
    log_q = log_q,
    alpha = alpha,
    time = data$time,
    individual_id = data$individual_id,
    metadata = utils::modifyList(
      list(
        diagnostic_type = "finite_family_composite_envelope",
        null_family = names(null_family),
        envelope = "pointwise_maximum_predictive_density"
      ),
      metadata
    )
  )
  diagnostic$component_log_p0 <- component_log_p0
  diagnostic$selected_null_model <- colnames(component_log_p0)[max.col(component_log_p0)]
  diagnostic
}

summarise_hmm_parameter_family <- function(parameter_family) {
  parameter_family <- validate_hmm_parameter_family(parameter_family, min_size = 1L)
  do.call(
    rbind,
    lapply(names(parameter_family), function(model_name) {
      parameters <- parameter_family[[model_name]]
      step_mean <- parameters$step_shape / parameters$step_rate
      data.frame(
        model = model_name,
        initial_prob_1 = parameters$initial_probs[1L],
        initial_prob_2 = parameters$initial_probs[2L],
        transition_11 = parameters$transition_matrix[1L, 1L],
        transition_22 = parameters$transition_matrix[2L, 2L],
        step_mean_1 = step_mean[1L],
        step_mean_2 = step_mean[2L],
        angle_mean_1 = parameters$angle_mean[1L],
        angle_mean_2 = parameters$angle_mean[2L],
        angle_sd_1 = parameters$angle_sd[1L],
        angle_sd_2 = parameters$angle_sd[2L],
        stringsAsFactors = FALSE
      )
    })
  )
}
