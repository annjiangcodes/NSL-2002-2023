# SCRIPT: Create Data Coverage Matrix
#
# Description:
# This script generates a tile-based plot (heatmap) to visualize data 
# coverage for different immigration attitude measures across survey years.
# It reads a pre-computed coverage summary file, reshapes the data, and 
# creates a ggplot visualization.
#
# Input:
# - "outputs/v2_9c_coverage_summary.csv": A CSV file containing coverage 
#   information per variable. Expected columns are 'variable' and 'year_range'.
#
# Output:
# - "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/0_data_coverage_matrix.png": 
#   A PNG image of the data coverage matrix.
#
# Author: Gemini
# Date: 2025-08-08
#
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(stringr)
})

# Define input and output paths
input_file <- "outputs/v2_9c_coverage_summary.csv"
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
output_file <- file.path(output_dir, "0_data_coverage_matrix.png")

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Load the coverage data
if (!file.exists(input_file)) {
  stop("Input file not found: ", input_file)
}
coverage_df <- read_csv(input_file, show_col_types = FALSE) %>%
  filter(year_range != "Inf--Inf")

# Process the data to create a year-by-variable matrix
coverage_matrix <- coverage_df %>%
  # Extract start and end years, and handle single years
  mutate(
    start_year = as.integer(str_extract(year_range, "^\\d{4}")),
    end_year = as.integer(str_extract(year_range, "\\d{4}$"))
  ) %>%
  # Create a sequence of years for each variable
  rowwise() %>%
  mutate(survey_year = list(seq(from = start_year, to = end_year))) %>%
  unnest(survey_year) %>%
  # Keep only the essential columns
  select(variable, survey_year) %>%
  # Add a 'present' indicator
  mutate(present = 1) %>%
  # Ensure all variables are shown, even if they have no coverage in the range
  complete(variable, survey_year = 2002:2022, fill = list(present = 0))


# Define publication theme
publication_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 13, color = "gray40", hjust = 0),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold")
  )

# Create the plot
p <- ggplot(coverage_matrix, aes(x = survey_year, y = variable, fill = factor(present))) +
  geom_tile(color = "white", lwd = 1.5) +
  scale_fill_manual(values = c("0" = "gray90", "1" = "steelblue"),
                    name = "Data Availability",
                    labels = c("Absent", "Present")) +
  labs(
    title = "Data Coverage by Measure and Year (2002-2022)",
    subtitle = "Presence of attitude measures in the dataset across survey years.",
    x = "Survey Year",
    y = "Attitude Measure",
    caption = "Source: v2_9c Coverage Summary"
  ) +
  publication_theme +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  scale_x_continuous(breaks = 2002:2022)

# Save the plot
ggsave(
  output_file,
  plot = p,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)

message("Successfully generated coverage matrix: ", output_file)


