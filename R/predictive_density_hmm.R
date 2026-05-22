#' Compute observable HMM predictive log-density
#'
#' Convenience wrapper around [hmm_forward_filter()] returning only the
#' observable one-step predictive log-density.
#'
#' @param log_emission Numeric matrix of log-emission densities.
#' @param transition_matrix Square transition probability matrix.
#' @param initial_probs Initial state probability vector.
#'
#' @return A numeric vector of predictive log-densities.
#' @export

hmm_predictive_log_density <- function(log_emission, transition_matrix, initial_probs) {
  filtered <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = transition_matrix,
    initial_probs = initial_probs
  )

  filtered$log_predictive_density
}
