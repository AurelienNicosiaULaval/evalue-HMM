# Simulation and density helpers for a minimal movement HMM.

wrap_angle <- function(angle) {
  ((angle + pi) %% (2 * pi)) - pi
}

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

simulate_wrapped_normal <- function(n, mean, sd) {
  wrap_angle(stats::rnorm(n = n, mean = mean, sd = sd))
}

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
  density <- rowSums(density_matrix)

  if (log) {
    return(log(density))
  }
  density
}

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
  pmin(pmax(rowSums(cdf_matrix), 0), 1)
}

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

hmm_movement_predictive_log_density <- function(data, parameters) {
  log_emission <- hmm_movement_log_emission(data = data, parameters = parameters)
  hmm_predictive_log_density(
    log_emission = log_emission,
    transition_matrix = parameters$transition_matrix,
    initial_probs = parameters$initial_probs
  )
}
