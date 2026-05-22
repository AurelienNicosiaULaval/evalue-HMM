# Training-time helpers for the simulation study.
#
# estimate_hmm_movement_oracle() uses the simulated state labels available in
# our controlled experiments. It is not a general HMM fitting routine.

.state_vector <- function(x, n_states, argument_name) {
  if (length(x) == 1L) {
    x <- rep(x, n_states)
  }
  if (length(x) != n_states) {
    stop("`", argument_name, "` must have length 1 or one value per state.", call. = FALSE)
  }
  x
}

#' Estimate movement-HMM parameters from known states
#'
#' Estimate the built-in movement-HMM parameters from simulated data where latent
#' states are observed. This helper is intended for controlled simulation studies
#' and is not a general HMM fitting routine.
#'
#' @param data Data frame with `individual_id`, `time`, `state`, `step_length`,
#'   and `turning_angle`.
#' @param n_states Number of states. If `NULL`, inferred from `data$state`.
#' @param initial_pseudocount,transition_pseudocount Non-negative smoothing
#'   pseudo-counts.
#' @param min_step_variance Lower bound for within-state step-length variance.
#' @param min_angle_sd Lower bound for within-state angle standard deviation.
#'
#' @return A parameter list compatible with [create_hmm_movement_parameters()].
#' @export
estimate_hmm_movement_oracle <- function(
    data,
    n_states = NULL,
    initial_pseudocount = 1,
    transition_pseudocount = 1,
    min_step_variance = 1e-4,
    min_angle_sd = 0.05) {
  required_columns <- c("individual_id", "time", "state", "step_length", "turning_angle")
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      "`data` is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(data) == 0L) {
    stop("`data` must contain at least one row.", call. = FALSE)
  }
  if (is.null(n_states)) {
    n_states <- max(as.integer(data$state), na.rm = TRUE)
  }
  if (!is.numeric(n_states) || length(n_states) != 1L || n_states < 1L) {
    stop("`n_states` must be a positive integer.", call. = FALSE)
  }
  n_states <- as.integer(n_states)
  if (initial_pseudocount < 0 || transition_pseudocount < 0) {
    stop("Pseudocounts must be non-negative.", call. = FALSE)
  }
  if (min_step_variance <= 0 || min_angle_sd <= 0) {
    stop("Minimum variance and standard deviation bounds must be positive.", call. = FALSE)
  }

  data <- data[order(data$individual_id, data$time), ]
  state <- as.integer(data$state)
  if (any(is.na(state)) || any(state < 1L) || any(state > n_states)) {
    stop("`state` must contain integer labels in 1, ..., `n_states`.", call. = FALSE)
  }
  if (any(!is.finite(data$step_length)) || any(data$step_length <= 0)) {
    stop("`step_length` must contain finite positive values.", call. = FALSE)
  }
  if (any(!is.finite(data$turning_angle))) {
    stop("`turning_angle` must contain finite values.", call. = FALSE)
  }

  initial_counts <- rep(initial_pseudocount, n_states)
  transition_counts <- matrix(
    transition_pseudocount,
    nrow = n_states,
    ncol = n_states
  )

  individual_ids <- unique(data$individual_id)
  for (individual_id in individual_ids) {
    individual_data <- data[data$individual_id == individual_id, ]
    individual_state <- as.integer(individual_data$state)
    initial_counts[individual_state[1L]] <- initial_counts[individual_state[1L]] + 1

    if (length(individual_state) > 1L) {
      for (time_index in 2:length(individual_state)) {
        previous_state <- individual_state[time_index - 1L]
        current_state <- individual_state[time_index]
        transition_counts[previous_state, current_state] <-
          transition_counts[previous_state, current_state] + 1
      }
    }
  }

  initial_probs <- initial_counts / sum(initial_counts)
  transition_matrix <- sweep(
    transition_counts,
    MARGIN = 1,
    STATS = rowSums(transition_counts),
    FUN = "/"
  )

  step_shape <- numeric(n_states)
  step_rate <- numeric(n_states)
  angle_mean <- numeric(n_states)
  angle_sd <- numeric(n_states)

  for (state_index in seq_len(n_states)) {
    state_data <- data[state == state_index, ]
    if (nrow(state_data) < 2L) {
      stop("Each state must appear at least twice in the oracle training data.", call. = FALSE)
    }

    step_mean <- mean(state_data$step_length)
    step_variance <- stats::var(state_data$step_length)
    if (!is.finite(step_variance) || step_variance < min_step_variance) {
      step_variance <- max(min_step_variance, step_mean^2 / 20)
    }
    step_shape[state_index] <- max(step_mean^2 / step_variance, 0.05)
    step_rate[state_index] <- max(step_mean / step_variance, 0.05)

    sine_mean <- mean(sin(state_data$turning_angle))
    cosine_mean <- mean(cos(state_data$turning_angle))
    angle_mean[state_index] <- wrap_angle(atan2(sine_mean, cosine_mean))
    centered_angle <- wrap_angle(state_data$turning_angle - angle_mean[state_index])
    angle_sd[state_index] <- max(sqrt(mean(centered_angle^2)), min_angle_sd)
  }

  create_hmm_movement_parameters(
    initial_probs = initial_probs,
    transition_matrix = transition_matrix,
    step_shape = step_shape,
    step_rate = step_rate,
    angle_mean = angle_mean,
    angle_sd = angle_sd
  )
}

#' Perturb movement-HMM parameters
#'
#' Create a nearby diagnostic parameter set by modifying step means, angle means,
#' angle standard deviations and transition or initial probabilities.
#'
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#' @param step_mean_multiplier,angle_mean_shift,angle_sd_multiplier Scalar or
#'   state-specific perturbations.
#' @param transition_blend,initial_blend Blend weights toward uniform transition
#'   or initial probabilities.
#'
#' @return A perturbed parameter list.
#' @export
perturb_hmm_movement_parameters <- function(
    parameters,
    step_mean_multiplier = NULL,
    angle_mean_shift = NULL,
    angle_sd_multiplier = NULL,
    transition_blend = 0.08,
    initial_blend = 0.03) {
  n_states <- length(parameters$initial_probs)
  if (is.null(step_mean_multiplier)) {
    step_mean_multiplier <- seq(1.15, 0.90, length.out = n_states)
  }
  if (is.null(angle_mean_shift)) {
    angle_mean_shift <- seq(0.18, -0.14, length.out = n_states)
  }
  if (is.null(angle_sd_multiplier)) {
    angle_sd_multiplier <- seq(1.15, 1.30, length.out = n_states)
  }
  step_mean_multiplier <- .state_vector(step_mean_multiplier, n_states, "step_mean_multiplier")
  angle_mean_shift <- .state_vector(angle_mean_shift, n_states, "angle_mean_shift")
  angle_sd_multiplier <- .state_vector(angle_sd_multiplier, n_states, "angle_sd_multiplier")

  if (any(!is.finite(step_mean_multiplier)) || any(step_mean_multiplier <= 0)) {
    stop("`step_mean_multiplier` must contain finite positive values.", call. = FALSE)
  }
  if (any(!is.finite(angle_mean_shift))) {
    stop("`angle_mean_shift` must contain finite values.", call. = FALSE)
  }
  if (any(!is.finite(angle_sd_multiplier)) || any(angle_sd_multiplier <= 0)) {
    stop("`angle_sd_multiplier` must contain finite positive values.", call. = FALSE)
  }
  if (!is.numeric(transition_blend) || length(transition_blend) != 1L ||
      transition_blend < 0 || transition_blend > 1) {
    stop("`transition_blend` must be a single value in [0, 1].", call. = FALSE)
  }
  if (!is.numeric(initial_blend) || length(initial_blend) != 1L ||
      initial_blend < 0 || initial_blend > 1) {
    stop("`initial_blend` must be a single value in [0, 1].", call. = FALSE)
  }

  uniform_initial <- rep(1 / n_states, n_states)
  uniform_transition <- matrix(1 / n_states, nrow = n_states, ncol = n_states)

  create_hmm_movement_parameters(
    initial_probs = (1 - initial_blend) * parameters$initial_probs +
      initial_blend * uniform_initial,
    transition_matrix = (1 - transition_blend) * parameters$transition_matrix +
      transition_blend * uniform_transition,
    step_shape = parameters$step_shape,
    step_rate = parameters$step_rate / step_mean_multiplier,
    angle_mean = wrap_angle(parameters$angle_mean + angle_mean_shift),
    angle_sd = parameters$angle_sd * angle_sd_multiplier
  )
}

#' Summarise parameter error for simulated HMMs
#'
#' @param estimated_parameters Estimated parameter list.
#' @param true_parameters True parameter list.
#'
#' @return A one-row data frame of error summaries.
#' @export
summarise_hmm_parameter_error <- function(estimated_parameters, true_parameters) {
  estimated_step_mean <- estimated_parameters$step_shape / estimated_parameters$step_rate
  true_step_mean <- true_parameters$step_shape / true_parameters$step_rate

  data.frame(
    initial_l1_error = sum(abs(estimated_parameters$initial_probs - true_parameters$initial_probs)),
    transition_frobenius_error = sqrt(sum(
      (estimated_parameters$transition_matrix - true_parameters$transition_matrix)^2
    )),
    step_mean_rmse = sqrt(mean((estimated_step_mean - true_step_mean)^2)),
    step_shape_rmse = sqrt(mean((estimated_parameters$step_shape - true_parameters$step_shape)^2)),
    step_rate_rmse = sqrt(mean((estimated_parameters$step_rate - true_parameters$step_rate)^2)),
    angle_mean_mae = mean(abs(wrap_angle(
      estimated_parameters$angle_mean - true_parameters$angle_mean
    ))),
    angle_sd_rmse = sqrt(mean((estimated_parameters$angle_sd - true_parameters$angle_sd)^2)),
    stringsAsFactors = FALSE
  )
}
