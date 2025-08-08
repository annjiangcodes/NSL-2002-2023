# =============================================================================
# ANALYSIS: THREE INDICES BY GENERATION (2002-2022)
# =============================================================================
#
# Purpose: 
# Creates a plot showing the trends for the liberalism index, 
# restrictionism index, and deportation concern from 2002-2022, 
# stratified by generation. This script adheres to the v2.6 
# visualization standards.
#
# Input:
# - data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
#
# Output:
# - current/outputs/CURRENT_2025_08_09_FIGURES_three_indices/
#   - three_indices_by_generation_2002_2022.png
#
# =============================================================================

# Load required libraries
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
})

message("=== ANALYSIS: THREE INDICES BY GENERATION (2002-2022) START ===")

# -----------------------------------------------------------------------------
# 1) Load and prepare data
# -----------------------------------------------------------------------------
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
if (!file.exists(input_path)) stop("Input file not found: ", input_path)
df <- read_csv(input_path, show_col_types = FALSE)

# Filter for 2002-2022 and prepare generation labels
df_processed <- df %>%
  filter(survey_year >= 2002 & survey_year <= 2022) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation",
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(generation_label))

# -----------------------------------------------------------------------------
# 2) Calculate yearly means for the three indices
# -----------------------------------------------------------------------------
indices_to_plot <- c(
  "liberalism_index", 
  "restrictionism_index", 
  "concern_index"
)

trend_data <- df_processed %>%
  select(survey_year, generation_label, all_of(indices_to_plot)) %>%
  pivot_longer(
    cols = all_of(indices_to_plot),
    names_to = "index_name",
    values_to = "index_value"
  ) %>%
  filter(!is.na(index_value)) %>%
  group_by(survey_year, generation_label, index_name) %>%
  summarise(
    mean_index = mean(index_value, na.rm = TRUE),
    se_index = sd(index_value, na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  ) %>%
  mutate(
    index_name = case_when(
      index_name == "liberalism_index" ~ "Immigration Policy Liberalism",
      index_name == "restrictionism_index" ~ "Immigration Policy Restrictionism",
      index_name == "concern_index" ~ "Deportation Concern"
    )
  )

# -----------------------------------------------------------------------------
# 3) Define plotting theme and colors
# -----------------------------------------------------------------------------
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

generation_colors <- c(
  "First Generation" = "#2166ac", 
  "Second Generation" = "#762a83", 
  "Third+ Generation" = "#5aae61"
)

# -----------------------------------------------------------------------------
# 4) Create and save the plot
# -----------------------------------------------------------------------------
p <- ggplot(trend_data, aes(x = survey_year, y = mean_index, color = generation_label)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 3, alpha = 0.9) +
  geom_ribbon(
    aes(ymin = mean_index - 1.96 * se_index, ymax = mean_index + 1.96 * se_index, fill = generation_label),
    alpha = 0.2, color = NA
  ) +
  facet_wrap(~ index_name, scales = "free_y", ncol = 1) +
  scale_color_manual(values = generation_colors) +
  scale_fill_manual(values = generation_colors) +
  scale_x_continuous(breaks = seq(2002, 2022, 2)) +
  labs(
    title = "Immigration Attitudes by Generation: Three Key Indices (2002-2022)",
    subtitle = "Longitudinal trends for Liberalism, Restrictionism, and Deportation Concern.",
    x = "Survey Year",
    y = "Index Value (Standardized)",
    color = "Generational Status",
    fill = "Generational Status",
    caption = "Source: National Survey of Latinos, 2002-2022. 95% confidence intervals shown."
  ) +
  publication_theme

output_dir <- "current/outputs/CURRENT_2025_08_09_FIGURES_three_indices"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_path <- file.path(output_dir, "three_indices_by_generation_2002_2022.png")
ggsave(
  output_path,
  plot = p,
  width = 12,
  height = 14,
  dpi = 300,
  bg = "white"
)

message("Saved plot: ", output_path)
message("=== ANALYSIS: THREE INDICES BY GENERATION (2002-2022) COMPLETE ===")

