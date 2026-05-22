#' Common interface for predictive e-diagnostics.
#'
#' @param diagnostic_name A character string. Name of the diagnostic.
#' @param log_p0 Numeric vector. Log predictive density under the null.
#' @param log_q Numeric vector. Log predictive density under the alternative.
#' @param alpha Numeric. Significance level (default is 0.05).
#' @param time Numeric vector. Time indices.
#' @param individual_id Character vector or string. Identifiers for individuals.
#' @param weights Numeric vector or value. Observation weights.
#' @param metadata List. Additional metadata.
#'
#' @return A list of class \code{predictive_e_diagnostic}.
#' @export
make_predictive_diagnostic <- function(
    diagnostic_name,
    log_p0,
    log_q,
    alpha = 0.05,
    time = seq_along(log_p0),
    individual_id = NULL,
    weights = NULL,
    metadata = list()) {
  if (!is.character(diagnostic_name) || length(diagnostic_name) != 1L || !nzchar(diagnostic_name)) {
    stop("`diagnostic_name` must be a non-empty string.", call. = FALSE)
  }
  if (!is.numeric(log_p0) || !is.numeric(log_q)) {
    stop("`log_p0` and `log_q` must be numeric vectors.", call. = FALSE)
  }
  if (length(log_p0) != length(log_q)) {
    stop("`log_p0` and `log_q` must have the same length.", call. = FALSE)
  }
  if (length(log_p0) == 0L) {
    stop("`log_p0` and `log_q` must not be empty.", call. = FALSE)
  }
  if (any(!is.finite(log_p0)) || any(!is.finite(log_q))) {
    stop("`log_p0` and `log_q` must be finite for the current implementation.", call. = FALSE)
  }
  if (length(time) != length(log_p0)) {
    stop("`time` must have the same length as `log_p0`.", call. = FALSE)
  }

  if (is.null(individual_id)) {
    individual_id <- rep(NA_character_, length(log_p0))
  } else if (length(individual_id) == 1L) {
    individual_id <- rep(individual_id, length(log_p0))
  } else if (length(individual_id) != length(log_p0)) {
    stop("`individual_id` must have length 1 or the same length as `log_p0`.", call. = FALSE)
  }

  if (is.null(weights)) {
    weights <- rep(1, length(log_p0))
  } else if (length(weights) == 1L) {
    weights <- rep(weights, length(log_p0))
  } else if (length(weights) != length(log_p0)) {
    stop("`weights` must have length 1 or the same length as `log_p0`.", call. = FALSE)
  }
  if (any(!is.finite(weights)) || any(weights < 0)) {
    stop("`weights` must contain finite non-negative values.", call. = FALSE)
  }

  eprocess <- compute_eprocess(
    log_p0 = log_p0,
    log_p1 = log_q,
    alpha = alpha,
    time = time
  )

  path <- eprocess$path
  names(path)[names(path) == "log_p1"] <- "log_q"
  path$diagnostic_name <- diagnostic_name
  path$individual_id <- individual_id
  path$weight <- weights
  path <- path[, c(
    "diagnostic_name",
    "individual_id",
    "time",
    "log_p0",
    "log_q",
    "log_e_increment",
    "log_e_cumulative",
    "threshold",
    "weight"
  )]

  out <- list(
    diagnostic_name = diagnostic_name,
    path = path,
    alpha = alpha,
    threshold = eprocess$threshold,
    crossing_time = eprocess$crossing_time,
    signal = eprocess$signal,
    metadata = metadata
  )
  class(out) <- c("predictive_e_diagnostic", "list")
  out
}

#' Summarise predictive e-diagnostic results.
#'
#' @param diagnostic A \code{predictive_e_diagnostic} object.
#'
#' @importFrom utils tail
#' @return A data frame summarizing the diagnostic.
#' @export
summarise_predictive_diagnostic <- function(diagnostic) {
  if (!inherits(diagnostic, "predictive_e_diagnostic")) {
    stop("`diagnostic` must be created by `make_predictive_diagnostic()`.", call. = FALSE)
  }

  data.frame(
    diagnostic_name = diagnostic$diagnostic_name,
    alpha = diagnostic$alpha,
    threshold = diagnostic$threshold,
    signal = diagnostic$signal,
    crossing_time = diagnostic$crossing_time,
    max_log_e = max(diagnostic$path$log_e_cumulative),
    final_log_e = tail(diagnostic$path$log_e_cumulative, 1L),
    mean_log_increment = mean(diagnostic$path$log_e_increment),
    n_observations = nrow(diagnostic$path),
    stringsAsFactors = FALSE
  )
}

#' Print method for predictive_e_diagnostic.
#'
#' @param x A \code{predictive_e_diagnostic} object.
#' @param ... Unused.
#'
#' @export
print.predictive_e_diagnostic <- function(x, ...) {
  summary <- summarise_predictive_diagnostic(x)
  print(summary, row.names = FALSE)
  invisible(x)
}

