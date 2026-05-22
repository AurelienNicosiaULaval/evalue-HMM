dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

draw_logo <- function() {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)

  par(mar = rep(0, 4), xaxs = "i", yaxs = "i", bg = NA)
  plot.new()
  plot.window(xlim = c(-1.08, 1.08), ylim = c(-1.08, 1.08), asp = 1)

  theta <- pi / 6 + seq(0, 2 * pi, length.out = 7)
  hex_x <- cos(theta)
  hex_y <- sin(theta)

  polygon(
    hex_x,
    hex_y,
    col = "#17324d",
    border = "#29a37a",
    lwd = 9
  )

  polygon(
    0.84 * hex_x,
    0.84 * hex_y,
    col = "#f7fbff",
    border = NA
  )

  state_x <- c(-0.46, 0.00, 0.46)
  state_y <- c(0.22, 0.42, 0.22)

  arrows(state_x[1], state_y[1], state_x[2], state_y[2],
    length = 0.08, lwd = 3, col = "#17324d"
  )
  arrows(state_x[2], state_y[2], state_x[3], state_y[3],
    length = 0.08, lwd = 3, col = "#17324d"
  )
  arrows(state_x[3], state_y[3], state_x[1], state_y[1],
    length = 0.08, lwd = 3, col = "#17324d", code = 1
  )

  symbols(
    state_x,
    state_y,
    circles = rep(0.115, 3),
    inches = FALSE,
    add = TRUE,
    bg = "#ffd166",
    fg = "#17324d",
    lwd = 3
  )

  curve_x <- seq(-0.52, 0.52, length.out = 80)
  curve_y <- -0.32 + 0.16 * sin(2.5 * pi * (curve_x + 0.52)) + 0.26 * curve_x
  lines(curve_x, curve_y, col = "#d1495b", lwd = 6, lend = "round")
  segments(-0.72, -0.12, 0.72, -0.12, col = "#29a37a", lty = 2, lwd = 3)

  text(0, -0.68, "evalueHMM", family = "sans", font = 2, cex = 1.18, col = "#17324d")
}

png("man/figures/logo.png", width = 1200, height = 1200, res = 220, bg = "transparent")
draw_logo()
dev.off()

svg("man/figures/logo.svg", width = 6, height = 6, bg = "transparent")
draw_logo()
dev.off()
