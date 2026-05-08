# Generate ggplot figures for the elk application.

required_packages <- c("ggplot2", "dplyr", "tidyr", "scales")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    ". Install them before running this script.",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  suppressWarnings(library(ggplot2))
  suppressWarnings(library(dplyr))
  suppressWarnings(library(tidyr))
  suppressWarnings(library(scales))
})

input_data_file <- "application/data_processed/elk_prepared.csv"
input_paths_file <- "results/application_tables/elk_application_diagnostic_paths.csv"
input_summary_file <- "results/application_tables/elk_application_diagnostic_summary.csv"
input_model_selection_file <- "results/application_tables/elk_hmm_model_selection.csv"
input_state_probs_file <- "results/application_tables/elk_application_predicted_state_probs.csv"

required_files <- c(
  input_data_file,
  input_paths_file,
  input_summary_file,
  input_model_selection_file,
  input_state_probs_file
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop(
    "Run application/01_preprocess.R, 02_fit_hmm.R, and 03_compute_eprocess.R first. Missing: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

output_figure_dir <- "results/application_figures"
paper_figure_dir <- "paper/figures"
dir.create(output_figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paper_figure_dir, recursive = TRUE, showWarnings = FALSE)

prepared <- read.csv(input_data_file, stringsAsFactors = FALSE)
diagnostic_paths <- read.csv(input_paths_file, stringsAsFactors = FALSE)
diagnostic_summary <- read.csv(input_summary_file, stringsAsFactors = FALSE)
model_selection <- read.csv(input_model_selection_file, stringsAsFactors = FALSE)
predicted_state_probs <- read.csv(input_state_probs_file, stringsAsFactors = FALSE)

diagnostic_labels <- c(
  state_number_K3_vs_K4 = "State-number diagnostic (K=3 vs K=4)",
  angle_diffuse_K3 = "Diffuse-angle diagnostic",
  mixture_state_angle = "Fixed mixture",
  state_number_K3_vs_K4__predicted_state_3 = "Long-step-state localized diagnostic"
)

diagnostic_short_labels <- c(
  state_number_K3_vs_K4 = "K=3 vs K=4",
  angle_diffuse_K3 = "Diffuse angle",
  mixture_state_angle = "Fixed mixture",
  state_number_K3_vs_K4__predicted_state_3 = "Localized K+1"
)

diagnostic_paths <- diagnostic_paths |>
  mutate(
    diagnostic_label = recode(
      diagnostic_name,
      !!!diagnostic_labels,
      .default = diagnostic_name
    ),
    diagnostic_short_label = recode(
      diagnostic_name,
      !!!diagnostic_short_labels,
      .default = diagnostic_name
    ),
    increment_direction = if_else(log_e_increment >= 0, "Evidence for diagnostic", "Evidence for null")
  )

diagnostic_summary <- diagnostic_summary |>
  mutate(
    diagnostic_label = recode(
      diagnostic_name,
      !!!diagnostic_labels,
      .default = diagnostic_name
    ),
    diagnostic_short_label = recode(
      diagnostic_name,
      !!!diagnostic_short_labels,
      .default = diagnostic_name
    ),
    signal_label = if_else(signal, "Crosses threshold", "Does not cross")
  )

theme_elk <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title.position = "plot",
      plot.title = element_text(face = "bold", size = base_size + 4, colour = "#17324d"),
      plot.subtitle = element_text(size = base_size, colour = "#405261", margin = margin(b = 8)),
      plot.caption = element_text(colour = "#596673", hjust = 0),
      axis.title = element_text(colour = "#17324d"),
      axis.text = element_text(colour = "#33414f"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#e5e8eb", linewidth = 0.35),
      legend.position = "bottom",
      legend.title = element_blank(),
      strip.text = element_text(face = "bold", colour = "#17324d"),
      plot.margin = margin(12, 38, 12, 12)
    )
}

save_application_plot <- function(plot, file_name, width = 10, height = 7, dpi = 320) {
  ggplot2::ggsave(
    filename = file.path(output_figure_dir, file_name),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  ggplot2::ggsave(
    filename = file.path(paper_figure_dir, file_name),
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
}

split_colours <- c(train = "#a8b0b7", validation = "#c23b22")
diagnostic_colours <- c(
  "State-number diagnostic (K=3 vs K=4)" = "#1b6ca8",
  "Diffuse-angle diagnostic" = "#c46a00",
  "Fixed mixture" = "#0b7a53",
  "Long-step-state localized diagnostic" = "#6b5b2e"
)
increment_colours <- c(
  "Evidence for diagnostic" = "#0b7a53",
  "Evidence for null" = "#b8c0c8"
)

trajectory_labels <- prepared |>
  group_by(ID) |>
  slice_max(order_by = time_index, n = 1, with_ties = FALSE) |>
  ungroup()

trajectory_plot <- ggplot(prepared, aes(x = x, y = y, group = ID, colour = split)) +
  geom_path(aes(linewidth = split, alpha = split), lineend = "round") +
  geom_point(
    data = trajectory_labels,
    aes(x = x, y = y),
    size = 2.4,
    show.legend = FALSE
  ) +
  geom_label(
    data = trajectory_labels,
    aes(label = ID),
    size = 3.1,
    linewidth = 0,
    fill = "white",
    colour = "#17324d",
    show.legend = FALSE
  ) +
  coord_equal() +
  scale_colour_manual(values = split_colours) +
  scale_linewidth_manual(values = c(train = 0.45, validation = 1.15)) +
  scale_alpha_manual(values = c(train = 0.55, validation = 0.98)) +
  labs(
    title = "Held-out validation is one whole animal",
    subtitle = "The red trajectory, elk-115, is never used to fit the HMMs.",
    x = "Easting",
    y = "Northing",
    caption = "Data: moveHMM::elk_data. Split: elk-115 validation, remaining individuals training."
  ) +
  scale_x_continuous(labels = label_number(big.mark = ",")) +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  theme_elk()

criterion_long <- model_selection |>
  mutate(selected = if_else(selected_null, "BIC-selected null", "Candidate")) |>
  pivot_longer(
    cols = c(AIC, BIC),
    names_to = "criterion",
    values_to = "value"
  )

selected_row <- criterion_long |>
  filter(selected_null, criterion == "BIC")

model_selection_plot <- ggplot(
  criterion_long,
  aes(x = n_states, y = value, colour = criterion, group = criterion)
) +
  geom_line(linewidth = 1.1) +
  geom_point(aes(shape = selected), size = 3.2, stroke = 1.1) +
  geom_label(
    data = selected_row,
    aes(label = "BIC selects K = 3"),
    nudge_y = 45,
    linewidth = 0,
    fill = "white",
    colour = "#17324d",
    show.legend = FALSE
  ) +
  scale_x_continuous(breaks = sort(unique(model_selection$n_states))) +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  scale_colour_manual(values = c(AIC = "#c46a00", BIC = "#1b6ca8")) +
  scale_shape_manual(values = c(Candidate = 16, `BIC-selected null` = 21)) +
  labs(
    title = "Model selection chooses a parsimonious null",
    subtitle = "K = 4 improves AIC, but BIC selects K = 3 as the fitted generator.",
    x = "Number of states",
    y = "Information criterion",
    caption = "All HMMs are fitted on training individuals only."
  ) +
  theme_elk()

threshold <- unique(diagnostic_paths$threshold)[1]
final_labels <- diagnostic_paths |>
  group_by(diagnostic_label) |>
  slice_max(order_by = time, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(
    label_x = max(diagnostic_paths$time) + 5,
    label_y = case_when(
      diagnostic_name == "state_number_K3_vs_K4" ~ log_e_cumulative - 0.16,
      diagnostic_name == "state_number_K3_vs_K4__predicted_state_3" ~ log_e_cumulative + 0.16,
      TRUE ~ log_e_cumulative
    )
  )

crossing_points <- diagnostic_paths |>
  group_by(diagnostic_label) |>
  filter(log_e_cumulative >= threshold) |>
  slice_min(order_by = time, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(
    crossing_label = paste0("t = ", time),
    label_x = case_when(
      diagnostic_name == "state_number_K3_vs_K4" ~ time - 2,
      diagnostic_name == "mixture_state_angle" ~ time + 10,
      TRUE ~ time + 7
    ),
    label_y = case_when(
      diagnostic_name == "state_number_K3_vs_K4" ~ threshold + 0.82,
      diagnostic_name == "mixture_state_angle" ~ threshold + 0.34,
      TRUE ~ threshold + 0.58
    )
  )

eprocess_plot <- ggplot(
  diagnostic_paths,
  aes(x = time, y = log_e_cumulative, colour = diagnostic_label)
) +
  geom_hline(
    yintercept = threshold,
    linetype = "dashed",
    linewidth = 0.8,
    colour = "#1f2933"
  ) +
  annotate(
    "label",
    x = 62,
    y = threshold,
    label = "alpha 0.05 threshold",
    vjust = -0.8,
    size = 3.2,
    linewidth = 0,
    fill = "white",
    colour = "#1f2933"
  ) +
  geom_line(linewidth = 1.1) +
  geom_point(
    data = crossing_points,
    size = 2.4,
    show.legend = FALSE
  ) +
  geom_label(
    data = crossing_points,
    aes(x = label_x, y = label_y, label = crossing_label),
    size = 3,
    linewidth = 0,
    fill = "white",
    show.legend = FALSE
  ) +
  geom_text(
    data = final_labels,
    aes(x = label_x, y = label_y, label = diagnostic_short_label),
    hjust = 0,
    size = 3.1,
    show.legend = FALSE
  ) +
  coord_cartesian(
    xlim = c(min(diagnostic_paths$time), max(diagnostic_paths$time) + 34),
    clip = "off"
  ) +
  scale_x_continuous(expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous(expand = expansion(mult = c(0.03, 0.10))) +
  scale_colour_manual(values = diagnostic_colours) +
  labs(
    title = "The held-out elk challenges the BIC-selected HMM",
    subtitle = "The K+1 diagnostic crosses early; the localized version crosses later in long-step periods.",
    x = "Validation time index",
    y = "Cumulative log e-value",
    caption = "A crossing is evidence against the fitted generator relative to the chosen diagnostic, not proof of a biological state."
  ) +
  theme_elk() +
  theme(legend.position = "none")

primary_name <- diagnostic_summary |>
  arrange(desc(max_log_e)) |>
  slice(1) |>
  pull(diagnostic_name)

primary_path <- diagnostic_paths |>
  filter(diagnostic_name == primary_name)

increment_plot <- ggplot(
  primary_path,
  aes(x = time, y = log_e_increment, fill = increment_direction)
) +
  geom_col(width = 0.9, colour = NA) +
  geom_hline(yintercept = 0, linewidth = 0.7, colour = "#1f2933") +
  scale_fill_manual(values = increment_colours) +
  labs(
    title = "Local increments show where the evidence is earned",
    subtitle = "Positive bars are observations predicted better by the diagnostic mixture than by the fitted null.",
    x = "Validation time index",
    y = "Local log e-value increment",
    caption = paste0("Displayed diagnostic: ", unique(primary_path$diagnostic_label), ".")
  ) +
  theme_elk()

localized_diagnostic_name <- diagnostic_paths |>
  filter(grepl("predicted_state_", diagnostic_name)) |>
  slice(1) |>
  pull(diagnostic_name)
long_state <- as.integer(sub(".*predicted_state_([0-9]+).*", "\\1", localized_diagnostic_name))

long_state_col <- paste0("state_", long_state)
localized_path <- diagnostic_paths |>
  filter(grepl("predicted_state_", diagnostic_name))

state_probability_panel <- predicted_state_probs |>
  transmute(
    time = time_index,
    panel = paste0("Pr(long-step state ", long_state, ")"),
    value = .data[[long_state_col]]
  )

localized_panel <- localized_path |>
  transmute(
    time = time,
    panel = "Localized log e-value",
    value = log_e_cumulative
  )

localization_panel <- bind_rows(state_probability_panel, localized_panel) |>
  mutate(panel = factor(panel, levels = c(
    paste0("Pr(long-step state ", long_state, ")"),
    "Localized log e-value"
  )))

threshold_panel <- data.frame(
  panel = factor("Localized log e-value", levels = levels(localization_panel$panel)),
  yintercept = threshold
)

localization_plot <- ggplot(localization_panel, aes(x = time, y = value)) +
  geom_hline(
    data = threshold_panel,
    aes(yintercept = yintercept),
    linetype = "dashed",
    colour = "#1f2933",
    linewidth = 0.7
  ) +
  geom_area(
    data = filter(localization_panel, grepl("^Pr\\(", panel)),
    fill = "#d9eadf",
    colour = NA
  ) +
  geom_line(
    data = filter(localization_panel, panel == "Localized log e-value"),
    colour = "#6b5b2e",
    linewidth = 1.1
  ) +
  geom_line(
    data = filter(localization_panel, grepl("^Pr\\(", panel)),
    colour = "#0b7a53",
    linewidth = 1.0
  ) +
  facet_grid(panel ~ ., scales = "free_y", switch = "y") +
  labs(
    title = "The localized signal waits for long-step conditions",
    subtitle = "Filtering supplies predictable state weights before each validation observation.",
    x = "Validation time index",
    y = NULL,
    caption = "The lower panel uses the valid linear localization 1 + W_t(E_t - 1)."
  ) +
  theme_elk() +
  theme(
    legend.position = "none",
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, hjust = 1),
    panel.spacing.y = grid::unit(10, "pt")
  )

summary_plot <- diagnostic_summary |>
  arrange(max_log_e) |>
  mutate(diagnostic_label = factor(diagnostic_label, levels = diagnostic_label)) |>
  ggplot(aes(x = max_log_e, y = diagnostic_label, colour = signal_label)) +
  geom_vline(xintercept = threshold, linetype = "dashed", linewidth = 0.8, colour = "#1f2933") +
  geom_segment(aes(x = 0, xend = max_log_e, yend = diagnostic_label), linewidth = 1.2) +
  geom_point(size = 4) +
  annotate(
    "label",
    x = threshold,
    y = 0.6,
    label = "threshold",
    size = 3.1,
    linewidth = 0,
    fill = "white",
    colour = "#1f2933"
  ) +
  scale_colour_manual(values = c(`Crosses threshold` = "#0b7a53", `Does not cross` = "#b85c38")) +
  labs(
    title = "Which diagnostics speak the loudest?",
    subtitle = "The mixture and localized state-number diagnostics provide the clearest evidence.",
    x = "Maximum cumulative log e-value",
    y = NULL,
    caption = "All diagnostics are computed on the same held-out individual, elk-115."
  ) +
  theme_elk()

save_application_plot(trajectory_plot, "elk_trajectory_split.png", width = 9.5, height = 7.2)
save_application_plot(model_selection_plot, "elk_model_selection.png", width = 8.4, height = 6.2)
save_application_plot(eprocess_plot, "elk_eprocess_paths.png", width = 11.4, height = 7.2)
save_application_plot(increment_plot, "elk_log_e_increments.png", width = 10, height = 6.2)
save_application_plot(localization_plot, "elk_state_localization.png", width = 10, height = 7.2)
save_application_plot(summary_plot, "elk_diagnostic_summary.png", width = 9.6, height = 6.4)

message("Application ggplot figures completed.")
message("Figures written to: ", output_figure_dir)
message("Manuscript-ready copies written to: ", paper_figure_dir)
