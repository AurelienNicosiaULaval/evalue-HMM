# Diagnostic for an insufficient number of states.

diagnostic_extra_state <- function(
    data,
    null_parameters,
    extra_state_parameters,
    alpha = 0.05,
    time = NULL,
    individual_id = NULL,
    diagnostic_name = "extra_state",
    metadata = list()) {
  n_null_states <- length(null_parameters$initial_probs)
  n_extra_states <- length(extra_state_parameters$initial_probs)

  if (n_extra_states != n_null_states + 1L) {
    stop(
      "`extra_state_parameters` must contain exactly one more state than `null_parameters`.",
      call. = FALSE
    )
  }

  if (is.null(time)) {
    if ("time" %in% names(data)) {
      time <- data$time
    } else {
      time <- seq_len(nrow(data))
    }
  }
  if (is.null(individual_id) && "individual_id" %in% names(data)) {
    individual_id <- data$individual_id
  }

  log_p0 <- hmm_movement_predictive_log_density(
    data = data,
    parameters = null_parameters
  )
  log_q <- hmm_movement_predictive_log_density(
    data = data,
    parameters = extra_state_parameters
  )

  metadata <- c(
    list(
      null_n_states = n_null_states,
      diagnostic_n_states = n_extra_states,
      diagnostic_type = "full_predictive_density"
    ),
    metadata
  )

  make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = log_p0,
    log_q = log_q,
    alpha = alpha,
    time = time,
    individual_id = individual_id,
    metadata = metadata
  )
}
