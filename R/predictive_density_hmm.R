# Convenience wrapper returning the observable log predictive density from HMM filtering.

hmm_predictive_log_density <- function(log_emission, transition_matrix, initial_probs) {
  filtered <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = transition_matrix,
    initial_probs = initial_probs
  )

  filtered$log_predictive_density
}
