# Predictable mixtures and switching rules for diagnostic e-value increments.

validate_diagnostic_list <- function(diagnostics) {
  if (!is.list(diagnostics) || length(diagnostics) < 2L) {
    stop("`diagnostics` must be a list of at least two diagnostic objects.", call. = FALSE)
  }
  if (is.null(names(diagnostics)) || any(!nzchar(names(diagnostics)))) {
    names(diagnostics) <- paste0("diagnostic_", seq_along(diagnostics))
  }
  if (anyDuplicated(names(diagnostics))) {
    stop("Diagnostic names must be unique.", call. = FALSE)
  }
  if (!all(vapply(diagnostics, inherits, logical(1), what = "predictive_e_diagnostic"))) {
    stop("Every element of `diagnostics` must inherit from `predictive_e_diagnostic`.", call. = FALSE)
  }

  reference_path <- diagnostics[[1L]]$path
  reference_time <- reference_path$time
  reference_id <- reference_path$individual_id

  for (diagnostic_index in seq_along(diagnostics)) {
    path <- diagnostics[[diagnostic_index]]$path
    if (nrow(path) != nrow(reference_path)) {
      stop("All diagnostics must have the same path length.", call. = FALSE)
    }
    if (!identical(path$time, reference_time)) {
      stop("All diagnostics must use the same time index.", call. = FALSE)
    }
    if (!identical(path$individual_id, reference_id)) {
      stop("All diagnostics must use the same individual identifiers.", call. = FALSE)
    }
    if (any(!is.finite(path$log_e_increment))) {
      stop("Diagnostic log e-increments must be finite.", call. = FALSE)
    }
  }

  diagnostics
}

extract_log_e_matrix <- function(diagnostics) {
  diagnostics <- validate_diagnostic_list(diagnostics)
  log_e_matrix <- vapply(
    diagnostics,
    function(diagnostic) diagnostic$path$log_e_increment,
    numeric(nrow(diagnostics[[1L]]$path))
  )
  colnames(log_e_matrix) <- names(diagnostics)
  log_e_matrix
}

validate_combination_weights <- function(weights, n_observations, n_diagnostics) {
  if (is.null(weights)) {
    weights <- rep(1 / n_diagnostics, n_diagnostics)
  }

  if (is.vector(weights) && length(weights) == n_diagnostics) {
    weights <- matrix(
      rep(weights, each = n_observations),
      nrow = n_observations,
      ncol = n_diagnostics
    )
  } else {
    weights <- as.matrix(weights)
  }

  if (!all(dim(weights) == c(n_observations, n_diagnostics))) {
    stop("`weights` must have one value per diagnostic or one row per observation and diagnostic.", call. = FALSE)
  }
  if (any(!is.finite(weights)) || any(weights < 0)) {
    stop("`weights` must contain finite non-negative values.", call. = FALSE)
  }

  row_weight_sums <- rowSums(weights)
  if (any(row_weight_sums <= 0 | row_weight_sums > 1 + sqrt(.Machine$double.eps))) {
    stop("Each row of `weights` must have positive sum no greater than 1.", call. = FALSE)
  }

  weights
}

log_weighted_sum_exp <- function(log_values, weights) {
  if (length(log_values) != length(weights)) {
    stop("`log_values` and `weights` must have the same length.", call. = FALSE)
  }
  if (any(weights < 0) || sum(weights) <= 0) {
    stop("`weights` must be non-negative with positive sum.", call. = FALSE)
  }

  positive <- weights > 0
  log_values <- log_values[positive]
  weights <- weights[positive]
  normalizer <- max(log_values)
  normalizer + log(sum(weights * exp(log_values - normalizer)))
}

#' Predictable mixture of diagnostic e-increments
#'
#' Combine diagnostics by a row-wise weighted average of e-increments. The
#' weights must be fixed or predictable and each row must have total mass no
#' larger than one.
#'
#' @param diagnostics List of `predictive_e_diagnostic` objects with matching
#'   time and individual identifiers.
#' @param weights Optional vector of diagnostic weights or matrix with one row
#'   per observation.
#' @param diagnostic_name Diagnostic name for the mixture.
#' @param alpha Monitoring level.
#' @param metadata Optional metadata list.
#'
#' @return A combined `predictive_e_diagnostic` object.
#' @export
diagnostic_mixture <- function(
    diagnostics,
    weights = NULL,
    diagnostic_name = "diagnostic_mixture",
    alpha = diagnostics[[1L]]$alpha,
    metadata = list()) {
  diagnostics <- validate_diagnostic_list(diagnostics)
  log_e_matrix <- extract_log_e_matrix(diagnostics)
  n_observations <- nrow(log_e_matrix)
  n_diagnostics <- ncol(log_e_matrix)
  weights <- validate_combination_weights(weights, n_observations, n_diagnostics)
  colnames(weights) <- colnames(log_e_matrix)

  mixture_log_e_increment <- vapply(
    seq_len(n_observations),
    function(row_index) log_weighted_sum_exp(log_e_matrix[row_index, ], weights[row_index, ]),
    numeric(1)
  )

  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = rep(0, n_observations),
    log_q = mixture_log_e_increment,
    alpha = alpha,
    time = diagnostics[[1L]]$path$time,
    individual_id = diagnostics[[1L]]$path$individual_id,
    metadata = utils::modifyList(
      list(
        diagnostic_type = "predictable_mixture_of_e_increments",
        component_names = colnames(log_e_matrix),
        weight_sums = unique(round(rowSums(weights), 12))
      ),
      metadata
    )
  )

  diagnostic$component_log_e_increment <- log_e_matrix
  diagnostic$component_weights <- weights
  diagnostic
}

#' Predictable switch between diagnostics
#'
#' Select one component diagnostic at each time using only previous log
#' e-increments over a lookback window.
#'
#' @param diagnostics List of `predictive_e_diagnostic` objects with matching
#'   time and individual identifiers.
#' @param lookback Positive integer lookback window.
#' @param initial_choice Initial component index.
#' @param diagnostic_name Diagnostic name for the switched process.
#' @param alpha Monitoring level.
#' @param metadata Optional metadata list.
#'
#' @return A combined `predictive_e_diagnostic` object.
#' @export
diagnostic_switch <- function(
    diagnostics,
    lookback = 30L,
    initial_choice = 1L,
    diagnostic_name = "diagnostic_switch",
    alpha = diagnostics[[1L]]$alpha,
    metadata = list()) {
  diagnostics <- validate_diagnostic_list(diagnostics)
  log_e_matrix <- extract_log_e_matrix(diagnostics)
  n_observations <- nrow(log_e_matrix)
  n_diagnostics <- ncol(log_e_matrix)

  if (!is.numeric(lookback) || length(lookback) != 1L || lookback < 1L) {
    stop("`lookback` must be a positive integer.", call. = FALSE)
  }
  if (!is.numeric(initial_choice) || length(initial_choice) != 1L ||
      initial_choice < 1L || initial_choice > n_diagnostics) {
    stop("`initial_choice` must be a valid diagnostic index.", call. = FALSE)
  }

  lookback <- as.integer(lookback)
  initial_choice <- as.integer(initial_choice)
  selected_index <- integer(n_observations)
  selected_index[1L] <- initial_choice

  if (n_observations > 1L) {
    for (time_index in 2:n_observations) {
      start_index <- max(1L, time_index - lookback)
      scores <- colSums(log_e_matrix[start_index:(time_index - 1L), , drop = FALSE])
      selected_index[time_index] <- which.max(scores)
    }
  }

  switch_log_e_increment <- log_e_matrix[cbind(seq_len(n_observations), selected_index)]

  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = diagnostic_name,
    log_p0 = rep(0, n_observations),
    log_q = switch_log_e_increment,
    alpha = alpha,
    time = diagnostics[[1L]]$path$time,
    individual_id = diagnostics[[1L]]$path$individual_id,
    metadata = utils::modifyList(
      list(
        diagnostic_type = "predictable_switching_of_e_increments",
        component_names = colnames(log_e_matrix),
        lookback = lookback,
        initial_choice = colnames(log_e_matrix)[initial_choice]
      ),
      metadata
    )
  )

  diagnostic$component_log_e_increment <- log_e_matrix
  diagnostic$path$selected_index <- selected_index
  diagnostic$path$selected_diagnostic <- colnames(log_e_matrix)[selected_index]
  diagnostic
}
