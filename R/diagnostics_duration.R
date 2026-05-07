# Blockwise diagnostics for duration misspecification.

make_contiguous_blocks <- function(n_observations, block_size) {
  if (!is.numeric(n_observations) || length(n_observations) != 1L || n_observations < 1L) {
    stop("`n_observations` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(block_size) || length(block_size) != 1L || block_size < 2L) {
    stop("`block_size` must be an integer of at least 2.", call. = FALSE)
  }

  n_observations <- as.integer(n_observations)
  block_size <- as.integer(block_size)
  starts <- seq.int(1L, n_observations, by = block_size)
  ends <- pmin(starts + block_size - 1L, n_observations)

  data.frame(
    block_id = seq_along(starts),
    start = starts,
    end = ends,
    block_length = ends - starts + 1L,
    stringsAsFactors = FALSE
  )
}

step_long_probabilities <- function(parameters, step_threshold) {
  if (!is.numeric(step_threshold) || length(step_threshold) != 1L || !is.finite(step_threshold)) {
    stop("`step_threshold` must be a single finite number.", call. = FALSE)
  }
  if (step_threshold <= 0) {
    stop("`step_threshold` must be positive.", call. = FALSE)
  }

  stats::pgamma(
    step_threshold,
    shape = parameters$step_shape,
    rate = parameters$step_rate,
    lower.tail = FALSE
  )
}

hmm_binary_switch_pmf <- function(initial_probs, transition_matrix, emission_prob, block_length) {
  if (!is.numeric(block_length) || length(block_length) != 1L || block_length < 1L) {
    stop("`block_length` must be a positive integer.", call. = FALSE)
  }
  block_length <- as.integer(block_length)
  n_states <- length(initial_probs)

  if (!all(dim(transition_matrix) == c(n_states, n_states))) {
    stop("`transition_matrix` must be square with one row and column per state.", call. = FALSE)
  }
  if (length(emission_prob) != n_states) {
    stop("`emission_prob` must contain one probability per state.", call. = FALSE)
  }
  if (any(initial_probs < 0) || !isTRUE(all.equal(sum(initial_probs), 1))) {
    stop("`initial_probs` must be a probability vector that sums to 1.", call. = FALSE)
  }
  if (any(emission_prob <= 0 | emission_prob >= 1)) {
    stop("`emission_prob` must lie strictly between 0 and 1.", call. = FALSE)
  }

  max_switches <- block_length - 1L
  current <- array(0, dim = c(n_states, 2L, max_switches + 1L))

  for (state in seq_len(n_states)) {
    current[state, 1L, 1L] <- initial_probs[state] * (1 - emission_prob[state])
    current[state, 2L, 1L] <- initial_probs[state] * emission_prob[state]
  }

  if (block_length > 1L) {
    for (time_index in 2:block_length) {
      next_array <- array(0, dim = c(n_states, 2L, max_switches + 1L))

      for (previous_state in seq_len(n_states)) {
        for (previous_binary in 0:1) {
          for (switch_count in 0:(time_index - 2L)) {
            previous_mass <- current[previous_state, previous_binary + 1L, switch_count + 1L]
            if (previous_mass > 0) {
              for (state in seq_len(n_states)) {
                transition_mass <- previous_mass * transition_matrix[previous_state, state]
                if (transition_mass > 0) {
                  for (binary_value in 0:1) {
                    emission_mass <- if (binary_value == 1L) {
                      emission_prob[state]
                    } else {
                      1 - emission_prob[state]
                    }
                    updated_count <- switch_count + as.integer(binary_value != previous_binary)
                    next_array[state, binary_value + 1L, updated_count + 1L] <-
                      next_array[state, binary_value + 1L, updated_count + 1L] +
                      transition_mass * emission_mass
                  }
                }
              }
            }
          }
        }
      }

      current <- next_array
    }
  }

  pmf <- apply(current, 3L, sum)
  pmf / sum(pmf)
}

observed_step_switch_count <- function(step_length, step_threshold) {
  if (length(step_length) == 0L) {
    stop("`step_length` must not be empty.", call. = FALSE)
  }
  long_step <- step_length > step_threshold
  if (length(long_step) == 1L) {
    return(0L)
  }
  sum(long_step[-1L] != long_step[-length(long_step)])
}

simulate_hsmm_binary_switch_count <- function(
    initial_probs,
    transition_matrix,
    emission_prob,
    dwell_mean,
    dwell_size,
    block_length) {
  block_length <- as.integer(block_length)
  n_states <- length(initial_probs)
  state <- sample.int(n_states, size = 1L, prob = initial_probs)
  remaining_dwell <- sample_hsmm_dwell_time(
    state = state,
    dwell_mean = dwell_mean,
    dwell_size = dwell_size
  )
  binary_values <- logical(block_length)

  for (time_index in seq_len(block_length)) {
    binary_values[time_index] <- stats::runif(1L) < emission_prob[state]
    remaining_dwell <- remaining_dwell - 1L

    if (time_index < block_length && remaining_dwell == 0L) {
      state <- sample_next_state_after_dwell(
        current_state = state,
        transition_matrix = transition_matrix
      )
      remaining_dwell <- sample_hsmm_dwell_time(
        state = state,
        dwell_mean = dwell_mean,
        dwell_size = dwell_size
      )
    }
  }

  if (block_length == 1L) {
    return(0L)
  }
  sum(binary_values[-1L] != binary_values[-block_length])
}

hsmm_binary_switch_pmf <- function(
    initial_probs,
    transition_matrix,
    emission_prob,
    dwell_mean,
    dwell_size,
    block_length,
    n_simulations = 1000L,
    pseudo_count = 1) {
  if (!is.numeric(n_simulations) || length(n_simulations) != 1L || n_simulations < 1L) {
    stop("`n_simulations` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(pseudo_count) || length(pseudo_count) != 1L || pseudo_count < 0) {
    stop("`pseudo_count` must be a non-negative number.", call. = FALSE)
  }

  block_length <- as.integer(block_length)
  simulated_counts <- replicate(
    as.integer(n_simulations),
    simulate_hsmm_binary_switch_count(
      initial_probs = initial_probs,
      transition_matrix = transition_matrix,
      emission_prob = emission_prob,
      dwell_mean = dwell_mean,
      dwell_size = dwell_size,
      block_length = block_length
    )
  )

  counts <- tabulate(simulated_counts + 1L, nbins = block_length)
  pmf <- counts + pseudo_count
  pmf / sum(pmf)
}

diagnostic_duration_blockwise <- function(
    data,
    null_parameters,
    dwell_mean,
    dwell_size,
    step_threshold,
    block_size = 30L,
    n_simulations = 1000L,
    pseudo_count = 1,
    alpha = 0.05,
    diagnostic_name = "duration_blockwise",
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

  if ("individual_id" %in% names(data) && length(unique(data$individual_id)) > 1L) {
    stop("The current blockwise duration diagnostic expects one validation individual at a time.", call. = FALSE)
  }

  blocks <- make_contiguous_blocks(nrow(data), block_size)
  emission_prob <- step_long_probabilities(
    parameters = null_parameters,
    step_threshold = step_threshold
  )

  log_emission <- hmm_movement_log_emission(data = data, parameters = null_parameters)
  filtered <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = null_parameters$transition_matrix,
    initial_probs = null_parameters$initial_probs
  )

  observed_switches <- integer(nrow(blocks))
  log_p0 <- numeric(nrow(blocks))
  log_q <- numeric(nrow(blocks))
  expected_null_switches <- numeric(nrow(blocks))
  expected_alternative_switches <- numeric(nrow(blocks))

  for (block_index in seq_len(nrow(blocks))) {
    block_rows <- blocks$start[block_index]:blocks$end[block_index]
    block_length <- blocks$block_length[block_index]
    initial_probs <- filtered$predicted_probs[blocks$start[block_index], ]
    initial_probs <- initial_probs / sum(initial_probs)

    observed_switches[block_index] <- observed_step_switch_count(
      step_length = data$step_length[block_rows],
      step_threshold = step_threshold
    )

    null_pmf <- hmm_binary_switch_pmf(
      initial_probs = initial_probs,
      transition_matrix = null_parameters$transition_matrix,
      emission_prob = emission_prob,
      block_length = block_length
    )
    alternative_pmf <- hsmm_binary_switch_pmf(
      initial_probs = initial_probs,
      transition_matrix = null_parameters$transition_matrix,
      emission_prob = emission_prob,
      dwell_mean = dwell_mean,
      dwell_size = dwell_size,
      block_length = block_length,
      n_simulations = n_simulations,
      pseudo_count = pseudo_count
    )

    feature_index <- observed_switches[block_index] + 1L
    log_p0[block_index] <- log(null_pmf[feature_index])
    log_q[block_index] <- log(alternative_pmf[feature_index])
    expected_null_switches[block_index] <- sum((seq_along(null_pmf) - 1L) * null_pmf)
    expected_alternative_switches[block_index] <- sum((seq_along(alternative_pmf) - 1L) * alternative_pmf)
  }

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
        diagnostic_type = "blockwise_duration_feature",
        feature = "switch_count_of_long_step_indicator",
        block_size = block_size,
        step_threshold = step_threshold,
        n_simulations = n_simulations,
        pseudo_count = pseudo_count,
        dwell_mean = dwell_mean,
        dwell_size = dwell_size,
        null_pmf = "exact_hmm_binary_feature",
        alternative_pmf = "independent_hsmm_simulation"
      ),
      metadata
    )
  )

  diagnostic$blocks <- data.frame(
    blocks,
    observed_switches = observed_switches,
    expected_null_switches = expected_null_switches,
    expected_alternative_switches = expected_alternative_switches,
    log_p0 = log_p0,
    log_q = log_q,
    log_e_increment = log_q - log_p0,
    stringsAsFactors = FALSE
  )
  diagnostic
}
