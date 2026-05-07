# Preprocess the real-data application dataset.
#
# Dataset choice:
# - moveHMM::elk_data
# - Title in moveHMM: "Elk data set from Morales et al. (2004, Ecology)"
# - Package source: Michelot, Langrock and Patterson (2016), moveHMM.

required_packages <- c("moveHMM")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L) {
  stop(
    "Missing required package(s): ",
    paste(missing_packages, collapse = ", "),
    ". Install them before running this script.",
    call. = FALSE
  )
}

output_data_dir <- "application/data_processed"
output_table_dir <- "results/application_tables"
dir.create(output_data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_table_dir, recursive = TRUE, showWarnings = FALSE)

data("elk_data", package = "moveHMM")

prepared <- moveHMM::prepData(
  trackData = elk_data,
  type = "UTM",
  coordNames = c("Easting", "Northing")
)

prepared$time_index <- ave(
  seq_len(nrow(prepared)),
  prepared$ID,
  FUN = seq_along
)

# Hold out one individual before fitting. This is a simple pre-specified
# validation split, not a data-adaptive choice.
validation_id <- "elk-115"
prepared$split <- ifelse(prepared$ID == validation_id, "validation", "train")

dataset_summary <- data.frame(
  dataset = "moveHMM::elk_data",
  package = "moveHMM",
  package_version = as.character(utils::packageVersion("moveHMM")),
  source_article = "Morales et al. (2004), Ecology",
  source_doi = "https://doi.org/10.1890/03-0269",
  package_article = "Michelot et al. (2016), Methods in Ecology and Evolution",
  package_doi = "https://doi.org/10.1111/2041-210X.12578",
  n_rows = nrow(prepared),
  n_individuals = length(unique(prepared$ID)),
  validation_id = validation_id,
  train_rows = sum(prepared$split == "train"),
  validation_rows = sum(prepared$split == "validation"),
  stringsAsFactors = FALSE
)

individual_summary <- do.call(
  rbind,
  lapply(split(prepared, prepared$ID), function(individual_data) {
    data.frame(
      ID = unique(individual_data$ID),
      split = unique(individual_data$split),
      n_rows = nrow(individual_data),
      n_complete_step_angle = sum(is.finite(individual_data$step) & is.finite(individual_data$angle)),
      mean_step = mean(individual_data$step, na.rm = TRUE),
      median_step = stats::median(individual_data$step, na.rm = TRUE),
      max_step = max(individual_data$step, na.rm = TRUE),
      mean_dist_water = mean(individual_data$dist_water, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
)
row.names(individual_summary) <- NULL

candidate_selection <- data.frame(
  candidate = c("moveHMM::elk_data", "moveHMM::haggis_data", "momentuHMM::example", "amt::amt_fisher"),
  decision = c("selected", "not_selected", "not_selected", "not_selected"),
  reason = c(
    "Real elk movement data, four individuals, UTM coordinates, included with moveHMM.",
    "Useful package example, but less directly tied to the classic elk movement article.",
    "Useful for software examples, but simulated or package-internal example data are less compelling for the first application.",
    "Potentially useful, but the installed amt package currently fails to load with the local dplyr version."
  ),
  stringsAsFactors = FALSE
)

write.csv(
  prepared,
  file = file.path(output_data_dir, "elk_prepared.csv"),
  row.names = FALSE
)
write.csv(
  dataset_summary,
  file = file.path(output_table_dir, "elk_dataset_summary.csv"),
  row.names = FALSE
)
write.csv(
  individual_summary,
  file = file.path(output_table_dir, "elk_individual_summary.csv"),
  row.names = FALSE
)
write.csv(
  candidate_selection,
  file = file.path(output_table_dir, "dataset_candidate_selection.csv"),
  row.names = FALSE
)

message("Application preprocessing completed.")
message("Selected dataset: moveHMM::elk_data")
message("Validation individual: ", validation_id)
message("Processed data written to: ", file.path(output_data_dir, "elk_prepared.csv"))
message("Summary tables written to: ", output_table_dir)
