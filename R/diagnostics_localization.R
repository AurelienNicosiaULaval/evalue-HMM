# Predictable localization and tempering for predictive e-diagnostics.

validate_localization_weights <- function(weights, n_observations) {
  if (length(weights) == 1L) {
    weights <- rep(weights, n_observations)
  }
  if (length(weights) != n_observations) {
    stop("`weights` must have length 1 or match the diagnostic path length.", call. = FALSE)
  }
  if (!is.numeric(weights) || any(!is.finite(weights))) {
    stop("`weights` must be a finite numeric vector.", call. = FALSE)
  }
  if (any(weights < 0 | weights > 1)) {
    stop("`weights` must lie in [0, 1] for predictable localization.", call. = FALSE)
  }

  weights
}

linear_weighted_log_increment <- function(log_e_increment, weights) {
  if (!is.numeric(log_e_increment) || any(!is.finite(log_e_increment))) {
    stop("`log_e_increment` must be a finite numeric vector.", call. = FALSE)
  }

  weights <- validate_localization_weights(
    weights = weights,
    n_observations = length(log_e_increment)
  )

  output <- numeric(length(log_e_increment))
  zero_weight <- weights == 0
  unit_weight <- weights == 1
  middle_weight <- !(zero_weight | unit_weight)

  output[zero_weight] <- 0
  output[unit_weight] <- log_e_increment[unit_weight]

  if (any(middle_weight)) {
    log_null_part <- log1p(-weights[middle_weight])
    log_signal_part <- log(weights[middle_weight]) + log_e_increment[middle_weight]
    normalizer <- pmax(log_null_part, log_signal_part)
    output[middle_weight] <- normalizer +
      log(exp(log_null_part - normalizer) + exp(log_signal_part - normalizer))
  }

  output
}

power_tempered_log_increment <- function(log_e_increment, weights) {
  if (!is.numeric(log_e_increment) || any(!is.finite(log_e_increment))) {
    stop("`log_e_increment` must be a finite numeric vector.", call. = FALSE)
  }

  weights <- validate_localization_weights(
    weights = weights,
    n_observations = length(log_e_increment)
  )

  weights * log_e_increment
}

localize_predictive_diagnostic <- function(
    diagnostic,
    weights,
    localization_name,
    mode = c("linear", "power"),
    alpha = diagnostic$alpha,
    metadata = list()) {
  if (!inherits(diagnostic, "predictive_e_diagnostic")) {
    stop("`diagnostic` must be created by `make_predictive_diagnostic()`.", call. = FALSE)
  }
  if (!is.character(localization_name) || length(localization_name) != 1L || !nzchar(localization_name)) {
    stop("`localization_name` must be a non-empty string.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single number in (0, 1).", call. = FALSE)
  }

  mode <- match.arg(mode)
  path <- diagnostic$path
  weights <- validate_localization_weights(weights, nrow(path))

  base_log_e_increment <- path$log_e_increment
  if (mode == "linear") {
    localized_log_e_increment <- linear_weighted_log_increment(base_log_e_increment, weights)
  } else {
    localized_log_e_increment <- power_tempered_log_increment(base_log_e_increment, weights)
  }

  localized_log_e_cumulative <- cumsum(localized_log_e_increment)
  threshold <- log(1 / alpha)
  crossing_index <- which(localized_log_e_cumulative >= threshold)[1]
  crossing_time <- if (is.na(crossing_index)) NA else path$time[crossing_index]
  signal <- !is.na(crossing_index)

  localized_name <- paste(diagnostic$diagnostic_name, localization_name, sep = "__")
  localized_path <- path
  localized_path$diagnostic_name <- localized_name
  localized_path$base_log_e_increment <- base_log_e_increment
  localized_path$base_log_e_cumulative <- path$log_e_cumulative
  localized_path$log_e_increment <- localized_log_e_increment
  localized_path$log_e_cumulative <- localized_log_e_cumulative
  localized_path$threshold <- threshold
  localized_path$weight <- weights

  out <- list(
    diagnostic_name = localized_name,
    path = localized_path,
    alpha = alpha,
    threshold = threshold,
    crossing_time = crossing_time,
    signal = signal,
    metadata = utils::modifyList(
      diagnostic$metadata,
      utils::modifyList(
        list(
          base_diagnostic_name = diagnostic$diagnostic_name,
          localization_name = localization_name,
          localization_mode = mode
        ),
        metadata
      )
    ),
    base_diagnostic = diagnostic
  )
  class(out) <- c("predictive_e_diagnostic", "list")
  out
}

time_window_weights <- function(time, start, end) {
  if (!is.numeric(time) || any(!is.finite(time))) {
    stop("`time` must be a finite numeric vector.", call. = FALSE)
  }
  if (!is.numeric(start) || length(start) != 1L || !is.finite(start)) {
    stop("`start` must be a single finite number.", call. = FALSE)
  }
  if (!is.numeric(end) || length(end) != 1L || !is.finite(end)) {
    stop("`end` must be a single finite number.", call. = FALSE)
  }
  if (end < start) {
    stop("`end` must be greater than or equal to `start`.", call. = FALSE)
  }

  as.numeric(time >= start & time <= end)
}

hmm_predictive_state_weights <- function(data, parameters, state = NULL) {
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
  if (!is.null(state)) {
    if (!is.numeric(state) || length(state) != 1L || state < 1L || state > n_states) {
      stop("`state` must be a valid state index.", call. = FALSE)
    }
    state <- as.integer(state)
  }

  row_groups <- if ("individual_id" %in% names(data)) {
    split(seq_len(nrow(data)), data$individual_id)
  } else {
    list(seq_len(nrow(data)))
  }

  predicted_probs <- matrix(NA_real_, nrow = nrow(data), ncol = n_states)
  colnames(predicted_probs) <- paste0("state_", seq_len(n_states))

  for (row_index in row_groups) {
    log_emission <- hmm_movement_log_emission(data = data[row_index, , drop = FALSE], parameters = parameters)
    filtered <- hmm_forward_filter(
      log_emission = log_emission,
      transition_matrix = parameters$transition_matrix,
      initial_probs = parameters$initial_probs
    )
    predicted_probs[row_index, ] <- filtered$predicted_probs
  }

  if (is.null(state)) {
    return(predicted_probs)
  }

  predicted_probs[, state]
}
