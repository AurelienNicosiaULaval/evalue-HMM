test_that("compute_eprocess returns expected cumulative path", {
  log_p0 <- c(-1.0, -1.2, -0.8)
  log_q <- c(-0.8, -1.0, -0.7)

  out <- compute_eprocess(log_p0 = log_p0, log_p1 = log_q, alpha = 0.05)

  expect_equal(out$path$log_e_increment, log_q - log_p0)
  expect_equal(out$path$log_e_cumulative, cumsum(log_q - log_p0))
  expect_equal(out$threshold, log(20))
  expect_false(out$signal)
})

test_that("make_predictive_diagnostic builds a stable S3 object", {
  diagnostic <- make_predictive_diagnostic(
    diagnostic_name = "toy",
    log_p0 = c(-1.0, -1.2),
    log_q = c(-0.8, -1.0),
    individual_id = "id-1"
  )

  expect_s3_class(diagnostic, "predictive_e_diagnostic")
  expect_equal(nrow(diagnostic$path), 2)
  expect_equal(unique(diagnostic$path$individual_id), "id-1")

  summary <- summarise_predictive_diagnostic(diagnostic)
  expect_equal(summary$diagnostic_name, "toy")
  expect_equal(summary$n_observations, 2)
})

test_that("invalid e-process inputs fail clearly", {
  expect_error(compute_eprocess(c(0, 1), c(0), alpha = 0.05), "same length")
  expect_error(compute_eprocess(c(0), c(0), alpha = 1), "in \\(0, 1\\)")
})
