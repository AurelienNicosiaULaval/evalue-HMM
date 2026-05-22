#' evalueHMM: predictive e-diagnostics for movement HMMs
#'
#' The package provides tools for constructing predictive e-process diagnostics
#' for hidden Markov models used with animal movement data. Core functions cover
#' simulation, observable predictive densities by filtering, e-process
#' construction, diagnostic alternatives, localization, combinations and plotting.
#'
#' @keywords internal
"_PACKAGE"

# Shared utilities and global variables for R CMD check.

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(".data"))
}
