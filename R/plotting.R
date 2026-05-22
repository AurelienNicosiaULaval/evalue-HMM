#' Plot a predictive e-process
#'
#' @param eprocess Object returned by [compute_eprocess()].
#' @param title Plot title.
#'
#' @return A `ggplot` object.
#' @examples
#' eprocess <- compute_eprocess(c(-1, -1), c(-0.8, -0.9))
#' plot_eprocess(eprocess)
#' @export
plot_eprocess <- function(eprocess, title = "Predictive e-process") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package `ggplot2` is required for `plot_eprocess()`.", call. = FALSE)
  }
  if (!is.list(eprocess) || is.null(eprocess$path)) {
    stop("`eprocess` must be the object returned by `compute_eprocess()`.", call. = FALSE)
  }

  ggplot2::ggplot(eprocess$path, ggplot2::aes(x = .data$time, y = .data$log_e_cumulative)) +
    ggplot2::geom_hline(
      yintercept = eprocess$threshold,
      linetype = "dashed",
      colour = "firebrick"
    ) +
    ggplot2::geom_line(linewidth = 0.8, colour = "steelblue") +
    ggplot2::labs(
      title = title,
      x = "Time",
      y = "Cumulative log e-value"
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
