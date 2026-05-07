# Utilities for applying predictive e-diagnostics to moveHMM fitted models.

wrap_angle <- function(angle) {
  ((angle + pi) %% (2 * pi)) - pi
}

log_sum_exp_vector <- function(x) {
  max_x <- max(x)
  if (!is.finite(max_x)) {
    return(max_x)
  }
  max_x + log(sum(exp(x - max_x)))
}

log_bessel_i0 <- function(kappa) {
  log(base::besselI(kappa, nu = 0, expon.scaled = TRUE)) + abs(kappa)
}

d_von_mises_log <- function(theta, mean, concentration) {
  if (!is.finite(concentration) || concentration < 0) {
    stop("`concentration` must be a finite non-negative number.", call. = FALSE)
  }
  theta <- wrap_angle(theta)
  mean <- wrap_angle(mean)
  concentration * cos(theta - mean) - log(2 * pi) - log_bessel_i0(concentration)
}

extract_movehmm_parameters <- function(fit) {
  if (!inherits(fit, "moveHMM")) {
    stop("`fit` must be a moveHMM object.", call. = FALSE)
  }

  step_par <- fit$mle$stepPar
  angle_par <- fit$mle$anglePar

  zero_mass <- if ("zero-mass" %in% rownames(step_par)) {
    as.numeric(step_par["zero-mass", ])
  } else {
    rep(0, ncol(step_par))
  }

  list(
    n_states = ncol(step_par),
    initial_probs = as.numeric(fit$mle$delta),
    transition_matrix = as.matrix(fit$mle$gamma),
    step_mean = as.numeric(step_par["mean", ]),
    step_sd = as.numeric(step_par["sd", ]),
    step_zero_mass = zero_mass,
    angle_mean = as.numeric(angle_par["mean", ]),
    angle_concentration = as.numeric(angle_par["concentration", ])
  )
}

movehmm_log_emission <- function(data, parameters) {
  required_columns <- c("step", "angle")
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      "`data` is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  n_states <- parameters$n_states
  log_emission <- matrix(NA_real_, nrow = nrow(data), ncol = n_states)
  colnames(log_emission) <- paste0("state_", seq_len(n_states))

  for (state in seq_len(n_states)) {
    step_mean <- parameters$step_mean[state]
    step_sd <- parameters$step_sd[state]
    step_shape <- (step_mean / step_sd)^2
    step_rate <- step_mean / step_sd^2
    zero_mass <- parameters$step_zero_mass[state]

    log_step <- rep(NA_real_, nrow(data))
    zero_step <- data$step == 0
    positive_step <- data$step > 0

    log_step[zero_step] <- log(zero_mass)
    log_step[positive_step] <- log1p(-zero_mass) +
      stats::dgamma(
        data$step[positive_step],
        shape = step_shape,
        rate = step_rate,
        log = TRUE
      )

    log_angle <- d_von_mises_log(
      theta = data$angle,
      mean = parameters$angle_mean[state],
      concentration = parameters$angle_concentration[state]
    )

    log_emission[, state] <- log_step + log_angle
  }

  log_emission
}

movehmm_predictive_components <- function(data, parameters) {
  if (!all(c("ID", "step", "angle") %in% names(data))) {
    stop("`data` must contain `ID`, `step`, and `angle`.", call. = FALSE)
  }

  complete_data <- data[is.finite(data$step) & is.finite(data$angle), , drop = FALSE]
  if (nrow(complete_data) == 0L) {
    stop("No complete step-angle observations are available.", call. = FALSE)
  }

  row_groups <- split(seq_len(nrow(complete_data)), complete_data$ID)
  log_predictive_density <- rep(NA_real_, nrow(complete_data))
  predicted_probs <- matrix(
    NA_real_,
    nrow = nrow(complete_data),
    ncol = parameters$n_states
  )
  filtered_probs <- predicted_probs
  colnames(predicted_probs) <- paste0("state_", seq_len(parameters$n_states))
  colnames(filtered_probs) <- paste0("state_", seq_len(parameters$n_states))

  for (row_index in row_groups) {
    log_emission <- movehmm_log_emission(
      data = complete_data[row_index, , drop = FALSE],
      parameters = parameters
    )
    filtered <- hmm_forward_filter(
      log_emission = log_emission,
      transition_matrix = parameters$transition_matrix,
      initial_probs = parameters$initial_probs
    )
    log_predictive_density[row_index] <- filtered$log_predictive_density
    predicted_probs[row_index, ] <- filtered$predicted_probs
    filtered_probs[row_index, ] <- filtered$filtered_probs
  }

  list(
    data = complete_data,
    log_predictive_density = log_predictive_density,
    predicted_probs = predicted_probs,
    filtered_probs = filtered_probs
  )
}

scale_angle_concentration <- function(parameters, multiplier) {
  if (!is.numeric(multiplier) || length(multiplier) != 1L || !is.finite(multiplier) || multiplier <= 0) {
    stop("`multiplier` must be a positive finite number.", call. = FALSE)
  }
  parameters$angle_concentration <- parameters$angle_concentration * multiplier
  parameters
}

log_average_density <- function(log_density_matrix, weights = NULL) {
  log_density_matrix <- as.matrix(log_density_matrix)
  if (is.null(weights)) {
    weights <- rep(1 / ncol(log_density_matrix), ncol(log_density_matrix))
  }
  if (length(weights) != ncol(log_density_matrix)) {
    stop("`weights` must have one entry per density column.", call. = FALSE)
  }
  if (any(weights < 0) || !isTRUE(all.equal(sum(weights), 1))) {
    stop("`weights` must be non-negative and sum to one.", call. = FALSE)
  }

  apply(
    log_density_matrix,
    1L,
    function(row) log_sum_exp_vector(log(weights) + row)
  )
}
