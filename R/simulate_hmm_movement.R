# Simulation and density helpers for a minimal movement HMM.

wrap_angle <- function(angle) {
  ((angle + pi) %% (2 * pi)) - pi
}

#' Create movement-HMM parameters
#'
#' Construct a parameter list for the built-in Gamma step-length and wrapped
#' normal turning-angle HMM used in examples and simulations.
#'
#' @param initial_probs Numeric probability vector for the initial latent state.
#' @param transition_matrix Square transition probability matrix.
#' @param step_shape,step_rate State-dependent Gamma shape and rate parameters.
#' @param angle_mean,angle_sd State-dependent wrapped-normal mean and standard
#'   deviation parameters.
#'
#' @return A list of HMM movement parameters.
#' @examples
#' parameters <- create_hmm_movement_parameters()
#' str(parameters)
#' @export
create_hmm_movement_parameters <- function(
    initial_probs = c(0.65, 0.35),
    transition_matrix = matrix(c(0.92, 0.08, 0.12, 0.88), nrow = 2, byrow = TRUE),
    step_shape = c(2, 7),
    step_rate = c(3, 2),
    angle_mean = c(0, 0),
    angle_sd = c(1.6, 0.35)) {
  n_states <- length(initial_probs)

  if (!all(dim(transition_matrix) == c(n_states, n_states))) {
    stop("`transition_matrix` must have one row and column per state.", call. = FALSE)
  }
  if (!isTRUE(all.equal(sum(initial_probs), 1))) {
    stop("`initial_probs` must sum to 1.", call. = FALSE)
  }
  if (any(initial_probs < 0) || any(transition_matrix < 0)) {
    stop("Probabilities must be non-negative.", call. = FALSE)
  }
  if (!isTRUE(all.equal(rowSums(transition_matrix), rep(1, n_states)))) {
    stop("Rows of `transition_matrix` must sum to 1.", call. = FALSE)
  }

  parameter_lengths <- vapply(
    list(step_shape, step_rate, angle_mean, angle_sd),
    length,
    integer(1)
  )
  if (any(parameter_lengths != n_states)) {
    stop("State-dependent parameters must have one value per state.", call. = FALSE)
  }
  if (any(step_shape <= 0) || any(step_rate <= 0) || any(angle_sd <= 0)) {
    stop("Step and angle scale parameters must be positive.", call. = FALSE)
  }

  list(
    initial_probs = initial_probs,
    transition_matrix = transition_matrix,
    step_shape = step_shape,
    step_rate = step_rate,
    angle_mean = wrap_angle(angle_mean),
    angle_sd = angle_sd
  )
}

#' Simulate wrapped-normal angles
#'
#' @param n Number of angles to simulate.
#' @param mean Circular mean.
#' @param sd Standard deviation before wrapping.
#'
#' @return A numeric vector of angles in \eqn{[-\pi, \pi)}.
#' @export
simulate_wrapped_normal <- function(n, mean, sd) {
  wrap_angle(stats::rnorm(n = n, mean = mean, sd = sd))
}

#' Wrapped-normal density
#'
#' @param theta Numeric vector of angles.
#' @param mean Circular mean.
#' @param sd Standard deviation before wrapping.
#' @param log Logical. Return log-density if `TRUE`.
#' @param n_terms Number of wrapped normal series terms on each side of zero.
#'
#' @return A numeric vector of densities or log-densities.
#' @examples
#' d_wrapped_normal(0, mean = 0, sd = 1)
#' @export
d_wrapped_normal <- function(theta, mean, sd, log = FALSE, n_terms = 5L) {
  if (sd <= 0) {
    stop("`sd` must be positive.", call. = FALSE)
  }
  if (n_terms < 1L) {
    stop("`n_terms` must be at least 1.", call. = FALSE)
  }

  theta <- wrap_angle(theta)
  shifts <- seq.int(-n_terms, n_terms)
  density_matrix <- vapply(
    shifts,
    function(k) stats::dnorm(theta + 2 * pi * k, mean = mean, sd = sd),
    numeric(length(theta))
  )
  density <- if (length(theta) == 1L) {
    sum(density_matrix)
  } else {
    rowSums(density_matrix)
  }

  if (log) {
    return(log(density))
  }
  density
}

#' Wrapped-normal distribution function
#'
#' @param theta Numeric vector of angles.
#' @param mean Circular mean.
#' @param sd Standard deviation before wrapping.
#' @param n_terms Number of wrapped normal series terms on each side of zero.
#'
#' @return A numeric vector of distribution function values clipped to `[0, 1]`.
#' @examples
#' p_wrapped_normal(0, mean = 0, sd = 1)
#' @export
p_wrapped_normal <- function(theta, mean, sd, n_terms = 8L) {
  if (sd <= 0) {
    stop("`sd` must be positive.", call. = FALSE)
  }
  if (n_terms < 1L) {
    stop("`n_terms` must be at least 1.", call. = FALSE)
  }

  theta <- wrap_angle(theta)
  shifts <- seq.int(-n_terms, n_terms)
  cdf_matrix <- vapply(
    shifts,
    function(k) {
      stats::pnorm(theta + 2 * pi * k, mean = mean, sd = sd) -
        stats::pnorm(-pi + 2 * pi * k, mean = mean, sd = sd)
    },
    numeric(length(theta))
  )
  cdf <- if (length(theta) == 1L) {
    sum(cdf_matrix)
  } else {
    rowSums(cdf_matrix)
  }
  pmin(pmax(cdf, 0), 1)
}

#' Simulate movement from a finite-state HMM
#'
#' Simulate one or more independent trajectories with state-dependent Gamma
#' step lengths and wrapped-normal turning angles.
#'
#' @param n_times Number of observations per individual.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#' @param n_individuals Number of independent individuals.
#'
#' @return A data frame with individual id, time, latent state, step length and
#'   turning angle.
#' @examples
#' set.seed(1)
#' parameters <- create_hmm_movement_parameters()
#' simulate_hmm_movement(5, parameters)
#' @export
simulate_hmm_movement <- function(n_times, parameters, n_individuals = 1L) {
  if (!is.numeric(n_times) || length(n_times) != 1L || n_times < 1L) {
    stop("`n_times` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(n_individuals) || length(n_individuals) != 1L || n_individuals < 1L) {
    stop("`n_individuals` must be a positive integer.", call. = FALSE)
  }

  n_times <- as.integer(n_times)
  n_individuals <- as.integer(n_individuals)
  n_states <- length(parameters$initial_probs)
  output <- vector("list", n_individuals)

  for (individual_index in seq_len(n_individuals)) {
    states <- integer(n_times)
    step_length <- numeric(n_times)
    turning_angle <- numeric(n_times)

    states[1] <- sample.int(n_states, size = 1L, prob = parameters$initial_probs)
    if (n_times > 1L) {
      for (time_index in 2:n_times) {
        states[time_index] <- sample.int(
          n_states,
          size = 1L,
          prob = parameters$transition_matrix[states[time_index - 1L], ]
        )
      }
    }

    for (state in seq_len(n_states)) {
      state_index <- states == state
      n_state <- sum(state_index)
      if (n_state > 0L) {
        step_length[state_index] <- stats::rgamma(
          n_state,
          shape = parameters$step_shape[state],
          rate = parameters$step_rate[state]
        )
        turning_angle[state_index] <- simulate_wrapped_normal(
          n_state,
          mean = parameters$angle_mean[state],
          sd = parameters$angle_sd[state]
        )
      }
    }

    output[[individual_index]] <- data.frame(
      individual_id = individual_index,
      time = seq_len(n_times),
      state = states,
      step_length = step_length,
      turning_angle = turning_angle,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, output)
}

#' Simulate movement with residual step-angle dependence
#'
#' Simulate the same marginal HMM as [simulate_hmm_movement()] but introduce a
#' Gaussian copula between step length and turning angle within each state.
#'
#' @param n_times Number of observations per individual.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#' @param rho_by_state State-dependent Gaussian copula correlations.
#' @param n_individuals Number of independent individuals.
#'
#' @return A simulated movement data frame.
#' @export
simulate_hmm_movement_copula <- function(n_times, parameters, rho_by_state, n_individuals = 1L) {
  if (!is.numeric(n_times) || length(n_times) != 1L || n_times < 1L) {
    stop("`n_times` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(n_individuals) || length(n_individuals) != 1L || n_individuals < 1L) {
    stop("`n_individuals` must be a positive integer.", call. = FALSE)
  }

  n_times <- as.integer(n_times)
  n_individuals <- as.integer(n_individuals)
  n_states <- length(parameters$initial_probs)

  if (length(rho_by_state) != n_states) {
    stop("`rho_by_state` must contain one correlation per state.", call. = FALSE)
  }
  if (any(!is.finite(rho_by_state)) || any(abs(rho_by_state) >= 1)) {
    stop("Each element of `rho_by_state` must lie in (-1, 1).", call. = FALSE)
  }

  output <- vector("list", n_individuals)

  for (individual_index in seq_len(n_individuals)) {
    states <- integer(n_times)
    step_length <- numeric(n_times)
    turning_angle <- numeric(n_times)

    states[1] <- sample.int(n_states, size = 1L, prob = parameters$initial_probs)
    if (n_times > 1L) {
      for (time_index in 2:n_times) {
        states[time_index] <- sample.int(
          n_states,
          size = 1L,
          prob = parameters$transition_matrix[states[time_index - 1L], ]
        )
      }
    }

    for (state in seq_len(n_states)) {
      state_index <- states == state
      n_state <- sum(state_index)
      if (n_state > 0L) {
        z_step <- stats::rnorm(n_state)
        z_angle <- rho_by_state[state] * z_step +
          sqrt(1 - rho_by_state[state]^2) * stats::rnorm(n_state)
        u_step <- stats::pnorm(z_step)
        u_angle <- stats::pnorm(z_angle)

        step_length[state_index] <- stats::qgamma(
          u_step,
          shape = parameters$step_shape[state],
          rate = parameters$step_rate[state]
        )
        turning_angle[state_index] <- wrap_angle(stats::qnorm(
          u_angle,
          mean = parameters$angle_mean[state],
          sd = parameters$angle_sd[state]
        ))
      }
    }

    output[[individual_index]] <- data.frame(
      individual_id = individual_index,
      time = seq_len(n_times),
      state = states,
      step_length = step_length,
      turning_angle = turning_angle,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, output)
}

#' Simulate movement with localized residual copula dependence
#'
#' @param n_times Number of observations per individual.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#' @param rho_by_state State-dependent Gaussian copula correlations during
#'   active times.
#' @param active_times Logical vector or numeric time indices where dependence is
#'   active.
#' @param n_individuals Number of independent individuals.
#'
#' @return A simulated movement data frame including the active-dependence flag.
#' @export
simulate_hmm_movement_local_copula <- function(
    n_times,
    parameters,
    rho_by_state,
    active_times,
    n_individuals = 1L) {
  if (!is.numeric(n_times) || length(n_times) != 1L || n_times < 1L) {
    stop("`n_times` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(n_individuals) || length(n_individuals) != 1L || n_individuals < 1L) {
    stop("`n_individuals` must be a positive integer.", call. = FALSE)
  }

  n_times <- as.integer(n_times)
  n_individuals <- as.integer(n_individuals)
  n_states <- length(parameters$initial_probs)

  if (length(rho_by_state) != n_states) {
    stop("`rho_by_state` must contain one correlation per state.", call. = FALSE)
  }
  if (any(!is.finite(rho_by_state)) || any(abs(rho_by_state) >= 1)) {
    stop("Each element of `rho_by_state` must lie in (-1, 1).", call. = FALSE)
  }

  if (is.logical(active_times)) {
    if (length(active_times) != n_times) {
      stop("Logical `active_times` must have length `n_times`.", call. = FALSE)
    }
    active_indicator <- active_times
  } else if (is.numeric(active_times)) {
    if (any(!is.finite(active_times))) {
      stop("Numeric `active_times` must contain finite time indices.", call. = FALSE)
    }
    active_indicator <- seq_len(n_times) %in% as.integer(active_times)
  } else {
    stop("`active_times` must be a logical vector or numeric time indices.", call. = FALSE)
  }

  output <- vector("list", n_individuals)

  for (individual_index in seq_len(n_individuals)) {
    states <- integer(n_times)
    step_length <- numeric(n_times)
    turning_angle <- numeric(n_times)
    emission_rho <- numeric(n_times)

    states[1] <- sample.int(n_states, size = 1L, prob = parameters$initial_probs)
    if (n_times > 1L) {
      for (time_index in 2:n_times) {
        states[time_index] <- sample.int(
          n_states,
          size = 1L,
          prob = parameters$transition_matrix[states[time_index - 1L], ]
        )
      }
    }

    for (time_index in seq_len(n_times)) {
      state <- states[time_index]
      rho <- if (active_indicator[time_index]) rho_by_state[state] else 0
      z_step <- stats::rnorm(1L)
      z_angle <- rho * z_step + sqrt(1 - rho^2) * stats::rnorm(1L)
      u_step <- stats::pnorm(z_step)
      u_angle <- stats::pnorm(z_angle)

      step_length[time_index] <- stats::qgamma(
        u_step,
        shape = parameters$step_shape[state],
        rate = parameters$step_rate[state]
      )
      turning_angle[time_index] <- wrap_angle(stats::qnorm(
        u_angle,
        mean = parameters$angle_mean[state],
        sd = parameters$angle_sd[state]
      ))
      emission_rho[time_index] <- rho
    }

    output[[individual_index]] <- data.frame(
      individual_id = individual_index,
      time = seq_len(n_times),
      state = states,
      step_length = step_length,
      turning_angle = turning_angle,
      active_copula = active_indicator,
      emission_rho = emission_rho,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, output)
}

sample_hsmm_dwell_time <- function(state, dwell_mean, dwell_size) {
  if (dwell_mean[state] < 1) {
    stop("State dwell means must be at least 1.", call. = FALSE)
  }
  stats::rnbinom(1L, size = dwell_size[state], mu = dwell_mean[state] - 1) + 1L
}

sample_next_state_after_dwell <- function(current_state, transition_matrix) {
  transition_probs <- transition_matrix[current_state, ]
  transition_probs[current_state] <- 0
  if (sum(transition_probs) <= 0) {
    stop("Each state must allow at least one transition to another state.", call. = FALSE)
  }
  transition_probs <- transition_probs / sum(transition_probs)
  sample.int(length(transition_probs), size = 1L, prob = transition_probs)
}

#' Simulate movement from an HSMM-like dwell-time generator
#'
#' Simulate trajectories with non-geometric state dwell times while retaining the
#' same state-dependent movement emissions as the built-in HMM generator.
#'
#' @param n_times Number of observations per individual.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#' @param dwell_mean,dwell_size State-dependent negative-binomial dwell-time
#'   parameters.
#' @param n_individuals Number of independent individuals.
#'
#' @return A simulated movement data frame.
#' @export
simulate_hsmm_movement <- function(
    n_times,
    parameters,
    dwell_mean,
    dwell_size,
    n_individuals = 1L) {
  if (!is.numeric(n_times) || length(n_times) != 1L || n_times < 1L) {
    stop("`n_times` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(n_individuals) || length(n_individuals) != 1L || n_individuals < 1L) {
    stop("`n_individuals` must be a positive integer.", call. = FALSE)
  }

  n_times <- as.integer(n_times)
  n_individuals <- as.integer(n_individuals)
  n_states <- length(parameters$initial_probs)

  if (length(dwell_mean) != n_states || length(dwell_size) != n_states) {
    stop("`dwell_mean` and `dwell_size` must contain one value per state.", call. = FALSE)
  }
  if (any(!is.finite(dwell_mean)) || any(!is.finite(dwell_size))) {
    stop("Dwell parameters must be finite.", call. = FALSE)
  }
  if (any(dwell_mean < 1) || any(dwell_size <= 0)) {
    stop("Dwell means must be at least 1 and dwell sizes must be positive.", call. = FALSE)
  }

  output <- vector("list", n_individuals)

  for (individual_index in seq_len(n_individuals)) {
    states <- integer(n_times)
    step_length <- numeric(n_times)
    turning_angle <- numeric(n_times)

    current_state <- sample.int(n_states, size = 1L, prob = parameters$initial_probs)
    remaining_dwell <- sample_hsmm_dwell_time(
      state = current_state,
      dwell_mean = dwell_mean,
      dwell_size = dwell_size
    )

    for (time_index in seq_len(n_times)) {
      states[time_index] <- current_state
      remaining_dwell <- remaining_dwell - 1L

      if (time_index < n_times && remaining_dwell == 0L) {
        current_state <- sample_next_state_after_dwell(
          current_state = current_state,
          transition_matrix = parameters$transition_matrix
        )
        remaining_dwell <- sample_hsmm_dwell_time(
          state = current_state,
          dwell_mean = dwell_mean,
          dwell_size = dwell_size
        )
      }
    }

    for (state in seq_len(n_states)) {
      state_index <- states == state
      n_state <- sum(state_index)
      if (n_state > 0L) {
        step_length[state_index] <- stats::rgamma(
          n_state,
          shape = parameters$step_shape[state],
          rate = parameters$step_rate[state]
        )
        turning_angle[state_index] <- simulate_wrapped_normal(
          n_state,
          mean = parameters$angle_mean[state],
          sd = parameters$angle_sd[state]
        )
      }
    }

    output[[individual_index]] <- data.frame(
      individual_id = individual_index,
      time = seq_len(n_times),
      state = states,
      step_length = step_length,
      turning_angle = turning_angle,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, output)
}

#' Compute state-dependent log-emission densities
#'
#' @param data Data frame with `step_length` and `turning_angle`.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#'
#' @return A numeric matrix of log-emission densities with one column per state.
#' @export
hmm_movement_log_emission <- function(data, parameters) {
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
  log_emission <- matrix(NA_real_, nrow = n_times, ncol = n_states)
  colnames(log_emission) <- paste0("state_", seq_len(n_states))

  for (state in seq_len(n_states)) {
    log_step <- stats::dgamma(
      data$step_length,
      shape = parameters$step_shape[state],
      rate = parameters$step_rate[state],
      log = TRUE
    )
    log_angle <- d_wrapped_normal(
      data$turning_angle,
      mean = parameters$angle_mean[state],
      sd = parameters$angle_sd[state],
      log = TRUE
    )
    log_emission[, state] <- log_step + log_angle
  }

  log_emission
}

#' Compute movement-HMM observable predictive log-density
#'
#' @param data Data frame with `step_length` and `turning_angle`.
#' @param parameters Parameter list from [create_hmm_movement_parameters()].
#'
#' @return A numeric vector of one-step predictive log-densities.
#' @examples
#' set.seed(1)
#' parameters <- create_hmm_movement_parameters()
#' data <- simulate_hmm_movement(5, parameters)
#' hmm_movement_predictive_log_density(data, parameters)
#' @export
hmm_movement_predictive_log_density <- function(data, parameters) {
  log_emission <- hmm_movement_log_emission(data = data, parameters = parameters)
  hmm_predictive_log_density(
    log_emission = log_emission,
    transition_matrix = parameters$transition_matrix,
    initial_probs = parameters$initial_probs
  )
}
