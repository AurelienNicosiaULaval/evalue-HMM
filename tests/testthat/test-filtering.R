test_that("forward filter returns normalized probabilities", {
  log_emission <- log(matrix(
    c(0.6, 0.4,
      0.2, 0.8,
      0.7, 0.3),
    nrow = 3,
    byrow = TRUE
  ))
  transition_matrix <- matrix(c(0.9, 0.1, 0.2, 0.8), nrow = 2, byrow = TRUE)
  initial_probs <- c(0.55, 0.45)

  filtered <- hmm_forward_filter(
    log_emission = log_emission,
    transition_matrix = transition_matrix,
    initial_probs = initial_probs
  )

  expect_equal(dim(filtered$predicted_probs), c(3, 2))
  expect_equal(rowSums(filtered$predicted_probs), rep(1, 3), tolerance = 1e-12)
  expect_equal(rowSums(filtered$filtered_probs), rep(1, 3), tolerance = 1e-12)

  first_log_density <- log(sum(initial_probs * exp(log_emission[1, ])))
  expect_equal(filtered$log_predictive_density[1], first_log_density)
})

test_that("movement predictive densities are finite on simulated data", {
  set.seed(123)
  parameters <- create_hmm_movement_parameters()
  data <- simulate_hmm_movement(n_times = 20, parameters = parameters)

  log_emission <- hmm_movement_log_emission(data, parameters)
  log_density <- hmm_movement_predictive_log_density(data, parameters)

  expect_equal(dim(log_emission), c(20, 2))
  expect_true(all(is.finite(log_density)))
})

test_that("wrapped normal helpers work for scalar and vector inputs", {
  density_scalar <- d_wrapped_normal(0, mean = 0, sd = 1)
  density_vector <- d_wrapped_normal(c(0, 0.5), mean = 0, sd = 1)
  cdf_scalar <- p_wrapped_normal(0, mean = 0, sd = 1)
  cdf_vector <- p_wrapped_normal(c(0, 0.5), mean = 0, sd = 1)

  expect_length(density_scalar, 1)
  expect_length(density_vector, 2)
  expect_length(cdf_scalar, 1)
  expect_length(cdf_vector, 2)
  expect_true(all(is.finite(c(density_scalar, density_vector))))
  expect_true(all(c(cdf_scalar, cdf_vector) >= 0 & c(cdf_scalar, cdf_vector) <= 1))
})
