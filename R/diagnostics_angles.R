#' Diagnostic for angular distribution misspecification
#'
#' Compare a null movement HMM with a diagnostic HMM using the same number of
#' states but altered turning-angle parameters.
#'
#' @param data Movement data with `step_length` and `turning_angle`.
#' @param null_parameters Null HMM parameters.
#' @param angle_parameters Diagnostic HMM parameters with the same number of
#'   states.
#' @param alpha Monitoring level.
#' @param time Optional time index.
#' @param individual_id Optional individual identifier.
#' @param diagnostic_name Diagnostic name.
#' @param metadata Optional metadata list.
#'
#' @return A `predictive_e_diagnostic` object.
#' @export
diagnostic_angle <- function(
    data,
    null_parameters,
    angle_parameters,
    alpha = 0.05,
    time = NULL,
    individual_id = NULL,
    diagnostic_name = "angle_misspecification",
    metadata = list()) {
  n_null_states <- length(null_parameters$initial_probs)
  n_angle_states <- length(angle_parameters$initial_probs)

  if (n_angle_states != n_null_states) {
    stop(
      "`angle_parameters` must contain the same number of states as `null_parameters`.",
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
    parameters = angle_parameters
  )

  metadata <- c(
    list(
      n_states = n_null_states,
      diagnostic_type = "full_predictive_density",
      target = "turning_angle"
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
