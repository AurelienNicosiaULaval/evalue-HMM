test_that("full-density diagnostics return common diagnostic objects", {
  set.seed(1)
  null_parameters <- create_hmm_movement_parameters()
  angle_parameters <- perturb_hmm_movement_parameters(
    null_parameters,
    angle_sd_multiplier = 1.2
  )
  extra_parameters <- create_hmm_movement_parameters(
    initial_probs = c(0.55, 0.35, 0.10),
    transition_matrix = matrix(
      c(0.90, 0.08, 0.02,
        0.10, 0.85, 0.05,
        0.15, 0.10, 0.75),
      nrow = 3,
      byrow = TRUE
    ),
    step_shape = c(2, 7, 4),
    step_rate = c(3, 2, 1.5),
    angle_mean = c(0, 0, 0.4),
    angle_sd = c(1.6, 0.35, 0.8)
  )
  data <- simulate_hmm_movement(30, null_parameters)

  angle_diagnostic <- diagnostic_angle(data, null_parameters, angle_parameters)
  state_diagnostic <- diagnostic_extra_state(data, null_parameters, extra_parameters)

  expect_s3_class(angle_diagnostic, "predictive_e_diagnostic")
  expect_s3_class(state_diagnostic, "predictive_e_diagnostic")
  expect_equal(nrow(angle_diagnostic$path), 30)
  expect_equal(nrow(state_diagnostic$path), 30)
})

test_that("feature diagnostics, mixtures and localization compose", {
  set.seed(2)
  parameters <- create_hmm_movement_parameters()
  data <- simulate_hmm_movement(25, parameters)

  copula_diagnostic <- diagnostic_step_angle_dependence(
    data = data,
    null_parameters = parameters,
    rho = 0.25
  )
  angle_diagnostic <- diagnostic_angle(
    data = data,
    null_parameters = parameters,
    angle_parameters = perturb_hmm_movement_parameters(parameters)
  )

  mixture <- diagnostic_mixture(list(copula = copula_diagnostic, angle = angle_diagnostic))
  weights <- time_window_weights(mixture$path$time, start = 5, end = 15)
  localized <- localize_predictive_diagnostic(
    diagnostic = mixture,
    weights = weights,
    localization_name = "window"
  )

  expect_s3_class(mixture, "predictive_e_diagnostic")
  expect_s3_class(localized, "predictive_e_diagnostic")
  expect_equal(nrow(localized$path), nrow(mixture$path))
  expect_true(all(localized$path$weight %in% c(0, 1)))
})

test_that("duration and composite diagnostics run on small examples", {
  set.seed(3)
  parameters <- create_hmm_movement_parameters()
  data <- simulate_hmm_movement(20, parameters)

  duration <- diagnostic_duration_blockwise(
    data = data,
    null_parameters = parameters,
    dwell_mean = c(5, 5),
    dwell_size = c(4, 4),
    step_threshold = 1.5,
    block_size = 5,
    n_simulations = 20
  )

  null_family <- list(
    base = parameters,
    perturbed = perturb_hmm_movement_parameters(parameters, angle_sd_multiplier = 1.1)
  )
  composite <- diagnostic_composite_envelope(
    data = data,
    null_family = null_family,
    diagnostic_parameters = perturb_hmm_movement_parameters(parameters)
  )

  expect_s3_class(duration, "predictive_e_diagnostic")
  expect_s3_class(composite, "predictive_e_diagnostic")
})
