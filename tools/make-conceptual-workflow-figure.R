#!/usr/bin/env Rscript

# Conceptual workflow figure for the manuscript.

output_file <- file.path("paper", "figures", "conceptual_workflow.png")

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

png(
  filename = output_file,
  width = 2800,
  height = 1500,
  res = 220,
  bg = "white"
)

op <- par(
  mar = c(0.6, 0.6, 0.6, 0.6),
  xaxs = "i",
  yaxs = "i",
  family = "Helvetica"
)
on.exit({
  par(op)
  dev.off()
}, add = TRUE)

plot.new()
plot.window(xlim = c(0, 100), ylim = c(0, 60))

col_dark <- "#263238"
col_mid <- "#607D8B"
col_train <- "#E8F2F1"
col_validate <- "#EEF1F8"
col_diag <- "#F5F0E6"
col_output <- "#EEF4EA"
col_warn <- "#F9E9E6"
col_line <- "#455A64"

draw_box <- function(x, y, w, h, title, subtitle = NULL, fill = "white",
                     border = col_mid, title_cex = 0.92, sub_cex = 0.68) {
  rect(x, y, x + w, y + h, col = fill, border = border, lwd = 1.4)
  text(
    x + w / 2,
    y + h * if (is.null(subtitle)) 0.50 else 0.62,
    title,
    cex = title_cex,
    font = 2,
    col = col_dark
  )
  if (!is.null(subtitle)) {
    text(
      x + w / 2,
      y + h * 0.34,
      subtitle,
      cex = sub_cex,
      col = col_dark
    )
  }
}

draw_arrow <- function(x0, y0, x1, y1, lty = 1, lwd = 1.7, col = col_line) {
  arrows(x0, y0, x1, y1, length = 0.09, angle = 22, lwd = lwd, col = col, lty = lty)
}

draw_band <- function(y0, y1, label, fill) {
  rect(1.5, y0, 98.5, y1, col = fill, border = NA)
  text(4, y1 - 2.2, label, adj = c(0, 0.5), cex = 0.75, font = 2, col = col_mid)
}

draw_band(41.5, 58.5, "Before validation", "#F8FBFB")
draw_band(22.0, 39.5, "Sequential validation", "#FAFAFC")
draw_band(3.0, 20.0, "Diagnostic reporting", "#FAFBF9")

draw_box(5, 46, 15, 7, "Movement data", "individuals, steps, angles", col_train)
draw_box(25, 46, 15, 7, "Training split", "preprocessing fixed", col_train)
draw_box(45, 46, 17, 7, "Fit null HMM", "M0 and parameters", col_train)
draw_box(68, 46, 22, 7, "Diagnostic menu", "q_t rules fixed or predictable", col_diag)

draw_arrow(20, 49.5, 25, 49.5)
draw_arrow(40, 49.5, 45, 49.5)
draw_arrow(62, 49.5, 68, 49.5)

draw_box(5, 28.5, 17, 7, "Validation data", "Y_t = (L_t, theta_t)", col_validate)
draw_box(28, 28.5, 18, 7, "Forward filter", "predictive state weights", col_validate)
draw_box(52, 29.5, 18, 6, "Observable p0", "marginal over states", col_validate)
draw_box(52, 22.5, 18, 5.5, "Diagnostic q_t", "predictive competitor", col_diag)
draw_box(76, 26, 16, 7, "Increment", "E_t = q_t / p0", col_output)

draw_arrow(22, 32, 28, 32)
draw_arrow(46, 32, 52, 32)
draw_arrow(70, 32.5, 76, 30.5)
draw_arrow(70, 25.2, 76, 28)
draw_arrow(79, 46, 60, 28, lty = 2, lwd = 1.4)

draw_box(16, 9.5, 20, 7, "Cumulative path", "sum log E_t over time", col_output)
draw_box(42, 9.5, 20, 7, "Anytime threshold", "log(1 / alpha)", col_output)
draw_box(68, 9.5, 22, 7, "Interpretation", "global and localized evidence", col_output)

draw_arrow(84, 26, 36, 13, lwd = 1.5)
draw_arrow(36, 13, 42, 13)
draw_arrow(62, 13, 68, 13)

draw_box(
  28,
  21.5,
  18,
  4.8,
  "Do not condition on",
  "decoded latent states",
  col_warn,
  border = "#B35C4D",
  title_cex = 0.73,
  sub_cex = 0.62
)
draw_arrow(37, 26.3, 57, 31.5, lty = 3, lwd = 1.3, col = "#B35C4D")

text(
  50,
  57,
  "Predictive e-diagnostics for movement HMMs",
  cex = 1.2,
  font = 2,
  col = col_dark
)

text(
  50,
  4.8,
  "Validity comes from predictable diagnostic choices and the observable predictive density p0(Y_t | F_{t-1}).",
  cex = 0.72,
  col = col_dark
)
