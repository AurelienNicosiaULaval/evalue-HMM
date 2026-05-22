# Generate ggplot figures for the elk application under LOAO.

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
      plot.margin = margin(12, 12, 12, 12)
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

# 1. Trajectory Plot (showing the 4 individuals)
trajectory_labels <- prepared |>
  group_by(ID) |>
  slice_max(order_by = time_index, n = 1, with_ties = FALSE) |>
  ungroup()

trajectory_plot <- ggplot(prepared, aes(x = x, y = y, group = ID, colour = ID)) +
  geom_path(linewidth = 0.65, lineend = "round", alpha = 0.8) +
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
  scale_colour_brewer(palette = "Set1") +
  labs(
    title = "Trajectories of the four elk individuals",
    subtitle = "Under Leave-One-Animal-Out cross-validation, each individual is used for validation in turn.",
    x = "Easting",
    y = "Northing",
    caption = "Data: moveHMM::elk_data."
  ) +
  scale_x_continuous(labels = label_number(big.mark = ",")) +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  theme_elk()

# 2. Model Selection Plot (showing AIC/BIC for each fold)
criterion_long <- model_selection |>
  mutate(selected = if_else(selected_null, "BIC-selected null", "Candidate")) |>
  pivot_longer(
    cols = c(AIC, BIC),
    names_to = "criterion",
    values_to = "value"
  )

model_selection_plot <- ggplot(
  criterion_long,
  aes(x = n_states, y = value, colour = criterion, group = criterion)
) +
  geom_line(linewidth = 1.1) +
  geom_point(aes(shape = selected), size = 2.8, stroke = 1.1) +
  facet_wrap(~validation_id, scales = "free_y") +
  scale_x_continuous(breaks = sort(unique(model_selection$n_states))) +
  scale_y_continuous(labels = label_number(big.mark = ",")) +
  scale_colour_manual(values = c(AIC = "#c46a00", BIC = "#1b6ca8")) +
  scale_shape_manual(values = c(Candidate = 16, `BIC-selected null` = 21)) +
  labs(
    title = "Model selection across Leave-One-Animal-Out folds",
    subtitle = "BIC consistently selects K = 3 as the null model for all training sets.",
    x = "Number of states",
    y = "Information criterion",
    caption = "All HMMs are fitted on training individuals for each fold."
  ) +
  theme_elk()

# 3. Cumulative E-process Paths Plot (faceted by diagnostic, showing the 4 individuals)
threshold <- unique(diagnostic_paths$threshold)[1]

eprocess_plot <- ggplot(
  diagnostic_paths,
  aes(x = time, y = log_e_cumulative, colour = individual_id, group = individual_id)
) +
  geom_hline(
    yintercept = threshold,
    linetype = "dashed",
    linewidth = 0.8,
    colour = "#1f2933"
  ) +
  geom_line(linewidth = 1.0, alpha = 0.8) +
  facet_wrap(~diagnostic_label, scales = "free_y") +
  scale_colour_brewer(palette = "Set1") +
  labs(
    title = "Leave-One-Animal-Out cumulative log e-processes",
    subtitle = "The dashed line is the alpha = 0.05 threshold, log(20). Tracks vary across individual animals.",
    x = "Validation time index",
    y = "Cumulative log e-value",
    caption = "A crossing of the threshold is evidence against the fitted generator."
  ) +
  theme_elk()

# 4. Local increments plot (shown for representative individual elk-115)
primary_path_elk115 <- diagnostic_paths |>
  filter(diagnostic_name == "mixture_state_angle", individual_id == "elk-115")

increment_colours <- c(
  "Evidence for diagnostic" = "#0b7a53",
  "Evidence for null" = "#b8c0c8"
)

increment_plot <- ggplot(
  primary_path_elk115,
  aes(x = time, y = log_e_increment, fill = increment_direction)
) +
  geom_col(width = 0.9, colour = NA) +
  geom_hline(yintercept = 0, linewidth = 0.7, colour = "#1f2933") +
  scale_fill_manual(values = increment_colours) +
  labs(
    title = "Local increments show where the evidence is earned (elk-115)",
    subtitle = "Positive bars are observations predicted better by the diagnostic mixture than by the fitted null.",
    x = "Validation time index",
    y = "Local log e-value increment",
    caption = "Displayed diagnostic: Fixed mixture for elk-115."
  ) +
  theme_elk()

# 5. Localization plot (shown for representative individual elk-115)
predicted_state_probs_elk115 <- predicted_state_probs |>
  filter(ID == "elk-115")
localized_path_elk115 <- diagnostic_paths |>
  filter(diagnostic_name == "state_number_K3_vs_K4__predicted_state_3", individual_id == "elk-115")

state_probability_panel <- predicted_state_probs_elk115 |>
  transmute(
    time = time_index,
    panel = "Pr(long-step state 3)",
    value = state_3
  )

localized_panel <- localized_path_elk115 |>
  transmute(
    time = time,
    panel = "Localized log e-value",
    value = log_e_cumulative
  )

localization_panel <- bind_rows(state_probability_panel, localized_panel) |>
  mutate(panel = factor(panel, levels = c(
    "Pr(long-step state 3)",
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
    data = filter(localization_panel, panel == "Pr(long-step state 3)"),
    fill = "#d9eadf",
    colour = NA
  ) +
  geom_line(
    data = filter(localization_panel, panel == "Localized log e-value"),
    colour = "#6b5b2e",
    linewidth = 1.1
  ) +
  geom_line(
    data = filter(localization_panel, panel == "Pr(long-step state 3)"),
    colour = "#0b7a53",
    linewidth = 1.0
  ) +
  facet_grid(panel ~ ., scales = "free_y", switch = "y") +
  labs(
    title = "The localized signal waits for long-step conditions (elk-115)",
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

# 6. Summary Plot of final log e-values (Individual points and Population Cross-fitted Average)
indiv_summary <- diagnostic_summary |> filter(validation_id != "population_average")
pop_summary <- diagnostic_summary |> filter(validation_id == "population_average")

summary_plot <- ggplot() +
  geom_vline(xintercept = threshold, linetype = "dashed", linewidth = 0.8, colour = "#1f2933") +
  annotate(
    "label",
    x = threshold,
    y = "Fixed mixture",
    label = "threshold",
    size = 3.1,
    linewidth = 0,
    fill = "white",
    colour = "#1f2933"
  ) +
  geom_segment(
    data = pop_summary,
    aes(x = 0, xend = final_log_e, y = diagnostic_label, yend = diagnostic_label),
    linewidth = 1.2,
    colour = "#788796"
  ) +
  geom_point(
    data = indiv_summary,
    aes(x = final_log_e, y = diagnostic_label, colour = validation_id),
    size = 3.2,
    alpha = 0.75,
    shape = 16
  ) +
  geom_point(
    data = pop_summary,
    aes(x = final_log_e, y = diagnostic_label),
    size = 5.2,
    colour = "#0b7a53",
    shape = 18
  ) +
  scale_colour_brewer(palette = "Dark2") +
  labs(
    title = "Summary of final log e-values across individuals",
    subtitle = "Individual results (circles) and population cross-fitted average (green diamond).",
    x = "Final log e-value",
    y = NULL,
    caption = "The cross-fitted average is E^cf = (1/N) * sum(E^(i)). The threshold is log(20) = 2.996."
  ) +
  theme_elk()

# Save all plots
save_application_plot(trajectory_plot, "elk_trajectory_split.png", width = 9.5, height = 7.2)
save_application_plot(model_selection_plot, "elk_model_selection.png", width = 9.5, height = 7.2)
save_application_plot(eprocess_plot, "elk_eprocess_paths.png", width = 11.4, height = 7.2)
save_application_plot(increment_plot, "elk_log_e_increments.png", width = 10, height = 6.2)
save_application_plot(localization_plot, "elk_state_localization.png", width = 10, height = 7.2)
save_application_plot(summary_plot, "elk_diagnostic_summary.png", width = 9.6, height = 6.4)

message("Application ggplot figures completed.")
message("Figures written to: ", output_figure_dir)
message("Manuscript-ready copies written to: ", paper_figure_dir)
