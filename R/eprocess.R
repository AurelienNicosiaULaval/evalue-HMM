#' Compute predictive e-processes from log predictive densities.
#'
#' @param log_p0 Numeric vector. Log predictive density under the null.
#' @param log_p1 Numeric vector. Log predictive density under the alternative.
#' @param alpha Numeric. Significance level (default is 0.05).
#' @param time Numeric vector. Time indices.
#'
#' @return A list containing the e-process path and signal metrics.
#' @export
compute_eprocess <- function(log_p0, log_p1, alpha = 0.05, time = seq_along(log_p0)) {
  if (!is.numeric(log_p0) || !is.numeric(log_p1)) {
    stop("`log_p0` and `log_p1` must be numeric vectors.", call. = FALSE)
  }
  if (length(log_p0) != length(log_p1)) {
    stop("`log_p0` and `log_p1` must have the same length.", call. = FALSE)
  }
  if (length(log_p0) == 0L) {
    stop("`log_p0` and `log_p1` must not be empty.", call. = FALSE)
  }
  if (!is.numeric(alpha) || length(alpha) != 1L || !is.finite(alpha) || alpha <= 0 || alpha >= 1) {
    stop("`alpha` must be a single number in (0, 1).", call. = FALSE)
  }
  if (length(time) != length(log_p0)) {
    stop("`time` must have the same length as `log_p0`.", call. = FALSE)
  }

  log_e_increment <- log_p1 - log_p0
  log_e_cumulative <- cumsum(log_e_increment)
  threshold <- log(1 / alpha)

  crossing_index <- which(log_e_cumulative >= threshold)[1]
  if (is.na(crossing_index)) {
    crossing_time <- NA
    signal <- FALSE
  } else {
    crossing_time <- time[crossing_index]
    signal <- TRUE
  }

  path <- data.frame(
    time = time,
    log_p0 = log_p0,
    log_p1 = log_p1,
    log_e_increment = log_e_increment,
    log_e_cumulative = log_e_cumulative,
    threshold = threshold,
    stringsAsFactors = FALSE
  )

  list(
    path = path,
    alpha = alpha,
    threshold = threshold,
    crossing_time = crossing_time,
    signal = signal
  )
}
