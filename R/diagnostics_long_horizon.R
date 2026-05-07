# Blockwise long-horizon movement diagnostics.

clip_to_open_unit <- function(x, eps = 1e-5) {
  if (eps <= 0 || eps >= 0.5) {
    stop("`eps` must lie in (0, 0.5).", call. = FALSE)
  }
  pmin(pmax(x, eps), 1 - eps)
}

simulate_hmm_movement_ar_angles <- function(
    n_times,
    parameters,
    rho_by_state,
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
    stop("`rho_by_state` must contain one value per state.", call. = FALSE)
  }
  if (any(!is.finite(rho_by_state)) || any(abs(rho_by_state) >= 1)) {
    stop("Each element of `rho_by_state` must lie in (-1, 1).", call. = FALSE)
  }

  output <- vector("list", n_individuals)

  for (individual_index in seq_len(n_individuals)) {
    states <- integer(n_times)
    step_length <- numeric(n_times)
    turning_angle <- numeric(n_times)
    latent_angle_residual <- numeric(n_times)

    states[1L] <- sample.int(n_states, size = 1L, prob = parameters$initial_probs)
    if (n_times > 1L) {
      for (time_index in 2:n_times) {
        states[time_index] <- sample.int(
          n_states,
          size = 1L,
          prob = parameters$transition_matrix[states[time_index - 1L], ]
        )
      }
    }

    residual <- stats::rnorm(1L)
    for (time_index in seq_len(n_times)) {
      state <- states[time_index]
      residual <- rho_by_state[state] * residual +
        sqrt(1 - rho_by_state[state]^2) * stats::rnorm(1L)
      latent_angle_residual[time_index] <- residual
      step_length[time_index] <- stats::rgamma(
        1L,
        shape = parameters$step_shape[state],
        rate = parameters$step_rate[state]
      )
      turning_angle[time_index] <- wrap_angle(
        parameters$angle_mean[state] + parameters$angle_sd[state] * residual
      )
    }

    output[[individual_index]] <- data.frame(
      individual_id = individual_index,
      time = seq_len(n_times),
      state = states,
      step_length = step_length,
      turning_angle = turning_angle,
      latent_angle_residual = latent_angle_residual,
      stringsAsFactors = FALSE
    )
  }

  do.call(rbind, output)
}

compute_block_straightness <- function(step_length, turning_angle, eps = 1e-5) {
  if (length(step_length) == 0L || length(turning_angle) == 0L) {
    stop("`step_length` and `turning_angle` must not be empty.", call. = FALSE)
  }
  if (length(step_length) != length(turning_angle)) {
    stop("`step_length` and `turning_angle` must have the same length.", call. = FALSE)
  }
  if (any(!is.finite(step_length)) || any(step_length < 0)) {
    stop("`step_length` must contain finite non-negative values.", call. = FALSE)
  }
  if (any(!is.finite(turning_angle))) {
    stop("`turning_angle` must contain finite values.", call. = FALSE)
  }

  total_path_length <- sum(step_length)
  if (total_path_length <= 0) {
    return(eps)
  }

  heading <- cumsum(turning_angle)
  net_x <- sum(step_length * cos(heading))
  net_y <- sum(step_length * sin(heading))
  net_displacement <- sqrt(net_x^2 + net_y^2)
  clip_to_open_unit(net_displacement / total_path_length, eps = eps)
}

fit_beta_moments <- function(x, eps = 1e-5, min_precision = 1e-3) {
  x <- clip_to_open_unit(x, eps = eps)
  mean_x <- mean(x)
  variance_x <- stats::var(x)
  if (!is.finite(variance_x) || variance_x <= 0) {
    variance_x <- mean_x * (1 - mean_x) / 100
  }

  precision <- mean_x * (1 - mean_x) / variance_x - 1
  precision <- max(precision, min_precision)

  c(
    shape1 = max(mean_x * precision, min_precision),
    shape2 = max((1 - mean_x) * precision, min_precision)
  )
}

simulate_block_straightness_values <- function(
    n_simulations,
    block_size,
    parameters,
    generator = c("hmm", "ar_angle"),
    rho_by_state = NULL) {
  generator <- match.arg(generator)
  if (!is.numeric(n_simulations) || length(n_simulations) != 1L || n_simulations < 1L) {
    stop("`n_simulations` must be a positive integer.", call. = FALSE)
  }

  vapply(
    seq_len(as.integer(n_simulations)),
    function(simulation_index) {
      simulated_data <- if (generator == "hmm") {
        simulate_hmm_movement(
          n_times = block_size,
          parameters = parameters,
          n_individuals = 1L
        )
      } else {
        simulate_hmm_movement_ar_angles(
          n_times = block_size,
          parameters = parameters,
          rho_by_state = rho_by_state,
          n_individuals = 1L
        )
      }
      compute_block_straightness(
        step_length = simulated_data$step_length,
        turning_angle = simulated_data$turning_angle
      )
    },
    numeric(1)
  )
}

fit_block_straightness_laws <- function(
    parameters,
    rho_by_state,
    block_size,
    n_simulations = 10000L) {
  null_values <- simulate_block_straightness_values(
    n_simulations = n_simulations,
    block_size = block_size,
    parameters = parameters,
    generator = "hmm"
  )
  alternative_values <- simulate_block_straightness_values(
    n_simulations = n_simulations,
    block_size = block_size,
    parameters = parameters,
    generator = "ar_angle",
    rho_by_state = rho_by_state
  )

  null_beta <- fit_beta_moments(null_values)
  alternative_beta <- fit_beta_moments(alternative_values)

  data.frame(
    law = c("null_hmm", "alternative_ar_angle"),
    feature = "block_straightness",
    block_size = block_size,
    n_simulations = n_simulations,
    shape1 = c(null_beta[["shape1"]], alternative_beta[["shape1"]]),
    shape2 = c(null_beta[["shape2"]], alternative_beta[["shape2"]]),
    mean_feature = c(mean(null_values), mean(alternative_values)),
    sd_feature = c(stats::sd(null_values), stats::sd(alternative_values)),
    q10_feature = c(
      unname(stats::quantile(null_values, probs = 0.10)),
      unname(stats::quantile(alternative_values, probs = 0.10))
    ),
    q90_feature = c(
      unname(stats::quantile(null_values, probs = 0.90)),
      unname(stats::quantile(alternative_values, probs = 0.90))
    ),
    stringsAsFactors = FALSE
  )
}

diagnostic_long_horizon_straightness <- function(
    data,
    law_parameters,
    block_size = 60L,
    alpha = 0.05,
    diagnostic_name = "long_horizon_straightness",
    metadata = list()) {
  required_columns <- c("step_length", "turning_angle")
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      "`data` is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
  if (!all(c("law", "shape1", "shape2") %in% names(law_parameters))) {
    stop("`law_parameters` must contain `law`, `shape1` and `shape2`.", call. = FALSE)
  }

  null_law <- law_parameters[law_parameters$law == "null_hmm", ]
  alternative_law <- law_parameters[law_parameters$law == "alternative_ar_angle", ]
  if (nrow(null_law) != 1L || nrow(alternative_law) != 1L) {
    stop("`law_parameters` must contain one null and one alternative row.", call. = FALSE)
  }

  blocks <- make_contiguous_blocks(nrow(data), block_size)
  straightness <- numeric(nrow(blocks))

  for (block_index in seq_len(nrow(blocks))) {
    block_rows <- blocks$start[block_index]:blocks$end[block_index]
    straightness[block_index] <- compute_block_straightness(
      step_length = data$step_length[block_rows],
      turning_angle = data$turning_angle[block_rows]
    )
  }

  log_p0 <- stats::dbeta(
    straightness,
    shape1 = null_law$shape1,
    shape2 = null_law$shape2,
    log = TRUE
  )
  log_q <- stats::dbeta(
    straightness,
    shape1 = alternative_law$shape1,
    shape2 = alternative_law$shape2,
    log = TRUE
  )

  individual_id <- if ("individual_id" %in% names(data)) {
    as.character(unique(data$individual_id))
  } else {
    NA_character_
  }

  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = log_p0,
    log_q = log_q,
    alpha = alpha,
    time = blocks$end,
    individual_id = individual_id,
    metadata = utils::modifyList(
      list(
        diagnostic_type = "simulation_based_blockwise_feature",
        feature = "straightness_index",
        block_size = block_size,
        null_law = "beta_fit_to_independent_hmm_simulations",
        alternative_law = "beta_fit_to_independent_ar_angle_simulations"
      ),
      metadata
    )
  )

  diagnostic$blocks <- data.frame(
    blocks,
    straightness = straightness,
    log_p0 = log_p0,
    log_q = log_q,
    log_e_increment = log_q - log_p0,
    stringsAsFactors = FALSE
  )
  diagnostic
}
