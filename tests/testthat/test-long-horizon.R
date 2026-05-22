test_that("long-horizon straightness helpers produce usable laws", {
  set.seed(4)
  parameters <- create_hmm_movement_parameters()
  laws <- fit_block_straightness_laws(
    parameters = parameters,
    rho_by_state = c(0.4, 0.4),
    block_size = 8,
    n_simulations = 30
  )

  expect_equal(sort(laws$law), c("alternative_ar_angle", "null_hmm"))
  expect_true(all(laws$shape1 > 0))
  expect_true(all(laws$shape2 > 0))

  data <- simulate_hmm_movement_ar_angles(
    n_times = 24,
    parameters = parameters,
    rho_by_state = c(0.4, 0.4)
  )
  diagnostic <- diagnostic_long_horizon_straightness(
    data = data,
    law_parameters = laws,
    block_size = 8
  )

  expect_s3_class(diagnostic, "predictive_e_diagnostic")
  expect_equal(nrow(diagnostic$path), 3)
})
