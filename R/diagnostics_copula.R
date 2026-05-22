# Diagnostic for conditional dependence between step length and turning angle.

clip_unit_interval <- function(x, eps = 1e-8) {
  pmin(pmax(x, eps), 1 - eps)
}

#' Gaussian copula log-density
#'
#' @param u,v Numeric vectors with values in `[0, 1]`.
#' @param rho Gaussian copula correlation parameter in `(-1, 1)`.
#'
#' @return A numeric vector of log-density values.
#' @export
gaussian_copula_log_density <- function(u, v, rho) {
  if (!is.numeric(rho) || length(rho) != 1L || !is.finite(rho) || abs(rho) >= 1) {
    stop("`rho` must be a single finite value in (-1, 1).", call. = FALSE)
  }

  u <- clip_unit_interval(u)
  v <- clip_unit_interval(v)
  z_u <- stats::qnorm(u)
  z_v <- stats::qnorm(v)

  -0.5 * log(1 - rho^2) -
    (rho^2 * (z_u^2 + z_v^2) - 2 * rho * z_u * z_v) / (2 * (1 - rho^2))
}

#' Sequential Rosenblatt residuals for movement HMMs
#'
#' Compute step PIT residuals and angle conditional PIT residuals under the
#' observable predictive mixture implied by a fitted movement HMM.
#'
#' @param data Movement data with `step_length` and `turning_angle`.
#' @param parameters Null HMM parameters.
#'
#' @return A data frame with residual features.
#' @export
hmm_movement_rosenblatt_residuals <- function(data, parameters) {
  required_columns <- c("step_length", "turning_angle")
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      "`data` is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  n_states <- length(parameters$initial_probs)
  n_times <- nrow(data)

  log_emission <- hmm_movement_log_emission(data = data, parameters = parameters)
  filtered <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = parameters$transition_matrix,
    initial_probs = parameters$initial_probs
  )
  predicted_probs <- filtered$predicted_probs

  step_density <- matrix(NA_real_, nrow = n_times, ncol = n_states)
  step_cdf <- matrix(NA_real_, nrow = n_times, ncol = n_states)
  angle_cdf <- matrix(NA_real_, nrow = n_times, ncol = n_states)

  for (state in seq_len(n_states)) {
    step_density[, state] <- stats::dgamma(
      data$step_length,
      shape = parameters$step_shape[state],
      rate = parameters$step_rate[state]
    )
    step_cdf[, state] <- stats::pgamma(
      data$step_length,
      shape = parameters$step_shape[state],
      rate = parameters$step_rate[state]
    )
    angle_cdf[, state] <- p_wrapped_normal(
      data$turning_angle,
      mean = parameters$angle_mean[state],
      sd = parameters$angle_sd[state]
    )
  }

  u_step <- rowSums(predicted_probs * step_cdf)

  step_weight_numerator <- predicted_probs * step_density
  step_weight_denominator <- rowSums(step_weight_numerator)
  if (any(step_weight_denominator <= 0) || any(!is.finite(step_weight_denominator))) {
    stop("Cannot compute conditional state weights after observing step length.", call. = FALSE)
  }
  conditional_weights <- step_weight_numerator / step_weight_denominator
  u_angle_given_step <- rowSums(conditional_weights * angle_cdf)

  data.frame(
    time = if ("time" %in% names(data)) data$time else seq_len(n_times),
    individual_id = if ("individual_id" %in% names(data)) data$individual_id else NA_integer_,
    u_step = clip_unit_interval(u_step),
    u_angle_given_step = clip_unit_interval(u_angle_given_step),
    stringsAsFactors = FALSE
  )
}

#' Diagnostic for residual step-angle dependence
#'
#' Build a feature-level e-process from sequential Rosenblatt residuals and a
#' Gaussian copula diagnostic alternative.
#'
#' @param data Movement data with `step_length` and `turning_angle`.
#' @param null_parameters Null HMM parameters.
#' @param rho Gaussian copula correlation used by the diagnostic alternative.
#' @param alpha Monitoring level.
#' @param time Optional time index.
#' @param individual_id Optional individual identifier.
#' @param diagnostic_name Diagnostic name.
#' @param metadata Optional metadata list.
#'
#' @return A `predictive_e_diagnostic` object with residual features attached.
#' @export
diagnostic_step_angle_dependence <- function(
    data,
    null_parameters,
    rho = 0.5,
    alpha = 0.05,
    time = NULL,
    individual_id = NULL,
    diagnostic_name = "step_angle_dependence",
    metadata = list()) {
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

  residuals <- hmm_movement_rosenblatt_residuals(
    data = data,
    parameters = null_parameters
  )

  log_p0 <- rep(0, nrow(residuals))
  log_q <- gaussian_copula_log_density(
    u = residuals$u_step,
    v = residuals$u_angle_given_step,
    rho = rho
  )

  metadata <- c(
    list(
      diagnostic_type = "feature_level_copula",
      target = "step_angle_dependence",
      copula = "gaussian",
      rho = rho
    ),
    metadata
  )

  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = log_p0,
    log_q = log_q,
    alpha = alpha,
    time = time,
    individual_id = individual_id,
    metadata = metadata
  )
  diagnostic$features <- residuals
  diagnostic
}
