# Forward filtering for a finite-state HMM using log emission densities.

.log_sum_exp <- function(x) {
  max_x <- max(x)
  if (!is.finite(max_x)) {
    return(max_x)
  }
  max_x + log(sum(exp(x - max_x)))
}

.normalize_log_prob <- function(log_prob) {
  normalizer <- .log_sum_exp(log_prob)
  if (!is.finite(normalizer)) {
    stop("Cannot normalize log probabilities because all entries are zero on the probability scale.", call. = FALSE)
  }
  exp(log_prob - normalizer)
}

hmm_forward_filter <- function(log_emission, transition_matrix, initial_probs) {
  log_emission <- as.matrix(log_emission)
  n_times <- nrow(log_emission)
  n_states <- ncol(log_emission)

  if (n_times == 0L || n_states == 0L) {
    stop("`log_emission` must have at least one row and one column.", call. = FALSE)
  }
  if (!all(dim(transition_matrix) == c(n_states, n_states))) {
    stop("`transition_matrix` must be a square matrix with one row and column per state.", call. = FALSE)
  }
  if (length(initial_probs) != n_states) {
    stop("`initial_probs` must contain one probability per state.", call. = FALSE)
  }
  if (any(initial_probs < 0) || !isTRUE(all.equal(sum(initial_probs), 1))) {
    stop("`initial_probs` must be a probability vector that sums to 1.", call. = FALSE)
  }
  if (any(transition_matrix < 0) || any(!is.finite(transition_matrix))) {
    stop("`transition_matrix` must contain finite non-negative probabilities.", call. = FALSE)
  }
  row_sums <- rowSums(transition_matrix)
  if (!isTRUE(all.equal(row_sums, rep(1, n_states)))) {
    stop("Rows of `transition_matrix` must sum to 1.", call. = FALSE)
  }

  predicted_probs <- matrix(NA_real_, nrow = n_times, ncol = n_states)
  filtered_probs <- matrix(NA_real_, nrow = n_times, ncol = n_states)
  log_predictive_density <- numeric(n_times)

  state_names <- colnames(log_emission)
  if (!is.null(state_names)) {
    colnames(predicted_probs) <- state_names
    colnames(filtered_probs) <- state_names
  }

  predicted <- initial_probs

  for (time_index in seq_len(n_times)) {
    predicted_probs[time_index, ] <- predicted

    log_joint <- log(predicted) + log_emission[time_index, ]
    log_predictive_density[time_index] <- .log_sum_exp(log_joint)
    filtered <- .normalize_log_prob(log_joint)

    filtered_probs[time_index, ] <- filtered
    predicted <- as.numeric(filtered %*% transition_matrix)
  }

  list(
    predicted_probs = predicted_probs,
    filtered_probs = filtered_probs,
    log_predictive_density = log_predictive_density
  )
}
