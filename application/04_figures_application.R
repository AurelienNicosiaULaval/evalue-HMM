# Generate figures for the elk application.

input_data_file <- "application/data_processed/elk_prepared.csv"
input_paths_file <- "results/application_tables/elk_application_diagnostic_paths.csv"
input_summary_file <- "results/application_tables/elk_application_diagnostic_summary.csv"

if (!file.exists(input_data_file) ||
    !file.exists(input_paths_file) ||
    !file.exists(input_summary_file)) {
  stop("Run application/01_preprocess.R, 02_fit_hmm.R, and 03_compute_eprocess.R first.", call. = FALSE)
}

output_figure_dir <- "results/application_figures"
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)

prepared <- read.csv(input_data_file, stringsAsFactors = FALSE)
diagnostic_paths <- read.csv(input_paths_file, stringsAsFactors = FALSE)
diagnostic_summary <- read.csv(input_summary_file, stringsAsFactors = FALSE)

split_colours <- c(train = "grey70", validation = "firebrick")
diagnostic_names <- unique(diagnostic_paths$diagnostic_name)
diagnostic_colours <- grDevices::hcl.colors(length(diagnostic_names), palette = "Dark 3")
names(diagnostic_colours) <- diagnostic_names

png(
  filename = file.path(output_figure_dir, "elk_trajectory_split.png"),
  width = 1800,
  height = 1300,
  res = 180
)
plot(
  prepared$x,
  prepared$y,
  type = "n",
  asp = 1,
  xlab = "Easting",
  ylab = "Northing",
  main = "Elk application: train and validation trajectories"
)
for (individual_id in unique(prepared$ID)) {
  individual_data <- prepared[prepared$ID == individual_id, ]
  lines(
    individual_data$x,
    individual_data$y,
    col = split_colours[[unique(individual_data$split)]],
    lwd = ifelse(unique(individual_data$split) == "validation", 2, 1)
  )
}
legend(
  "topright",
  legend = names(split_colours),
  col = split_colours,
  lwd = c(1, 2),
  bty = "n"
)
dev.off()

png(
  filename = file.path(output_figure_dir, "elk_eprocess_paths.png"),
  width = 1800,
  height = 1300,
  res = 180
)
y_range <- range(
  c(diagnostic_paths$log_e_cumulative, diagnostic_paths$threshold),
  finite = TRUE
)
plot(
  NA,
  xlim = range(diagnostic_paths$time),
  ylim = y_range,
  xlab = "Validation time index",
  ylab = "Cumulative log e-value",
  main = "Elk application: predictive e-diagnostics"
)
for (diagnostic_name in diagnostic_names) {
  path <- diagnostic_paths[diagnostic_paths$diagnostic_name == diagnostic_name, ]
  lines(
    path$time,
    path$log_e_cumulative,
    col = diagnostic_colours[[diagnostic_name]],
    lwd = 2
  )
}
abline(h = log(1 / 0.05), lty = 2, lwd = 2, col = "black")
legend(
  "topleft",
  legend = c(diagnostic_names, "alpha = 0.05 threshold"),
  col = c(unname(diagnostic_colours), "black"),
  lwd = c(rep(2, length(diagnostic_names)), 2),
  lty = c(rep(1, length(diagnostic_names)), 2),
  bty = "n",
  cex = 0.8
)
dev.off()

png(
  filename = file.path(output_figure_dir, "elk_log_e_increments.png"),
  width = 1800,
  height = 1300,
  res = 180
)
primary_name <- diagnostic_summary$diagnostic_name[which.max(diagnostic_summary$max_log_e)]
primary_path <- diagnostic_paths[diagnostic_paths$diagnostic_name == primary_name, ]
plot(
  primary_path$time,
  primary_path$log_e_increment,
  type = "h",
  lwd = 2,
  col = "steelblue4",
  xlab = "Validation time index",
  ylab = "Local log e-value increment",
  main = paste("Elk application: local increments for", primary_name)
)
abline(h = 0, col = "grey30", lty = 2)
dev.off()

message("Application figures completed.")
message("Figures written to: ", output_figure_dir)
